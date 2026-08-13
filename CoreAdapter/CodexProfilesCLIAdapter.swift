import Foundation

struct CodexProfilesCLIAdapter: CoreAdapter {
    let executableURL: URL?
    private let runner: ProcessRunner

    init(executableURL: URL? = nil, runner: ProcessRunner = ProcessRunner()) {
        self.executableURL = executableURL ?? Self.resolveExecutable()
        self.runner = runner
    }

    func createProfile(_ profileID: String) async throws {
        _ = try await runCore(["init", profileID])
    }

    func listProfiles() async throws -> [String] {
        let result = try await runCore(["list"])
        return result.stdoutString
            .split(whereSeparator: \.isNewline)
            .map(String.init)
    }

    func removeProfile(_ profileID: String) async throws {
        guard profileID != "default" else { throw JimiDeckError.unmanagedProfile }
        _ = try await runCore(["remove", profileID, "--yes"])
    }

    func launchDesktop(profileID: String) async throws {
        _ = try await runCore(["app", profileID])
    }

    func launchCLI(profileID: String, projectURL: URL) async throws {
        guard FileManager.default.fileExists(atPath: projectURL.path) else {
            throw JimiDeckError.projectMissing
        }
        guard let core = executableURL else { throw JimiDeckError.coreNotFound }

        let launcherURL = try Self.writeTerminalLauncher(
            coreURL: core,
            profileID: profileID,
            projectURL: projectURL
        )
        do {
            let result = try await runner.run(
                executableURL: URL(filePath: "/usr/bin/open"),
                arguments: ["-a", "Terminal", launcherURL.path]
            )
            guard result.exitCode == 0 else {
                try? FileManager.default.removeItem(at: launcherURL)
                throw JimiDeckError.coreFailure(Self.message(from: result))
            }
        } catch {
            try? FileManager.default.removeItem(at: launcherURL)
            throw error
        }
    }

    func diagnose() async throws -> EnvironmentReport {
        guard let executableURL else { throw JimiDeckError.coreNotFound }
        let versionResult = try await runner.run(
            executableURL: executableURL,
            arguments: ["version"],
            environment: Self.coreEnvironment
        )
        let result = try await runner.run(
            executableURL: executableURL,
            arguments: ["doctor", "--json"],
            environment: Self.coreEnvironment
        )
        guard !result.stdout.isEmpty else {
            throw JimiDeckError.coreFailure(Self.message(from: result))
        }

        let payload = try JSONDecoder().decode(DoctorPayload.self, from: result.stdout)
        return EnvironmentReport(
            desktop: .init(
                found: payload.desktop.found,
                path: payload.desktop.path,
                appPath: payload.desktop.appPath,
                product: payload.desktop.product,
                bundleID: payload.desktop.bundleID
            ),
            cli: .init(
                found: payload.cli.found,
                path: payload.cli.path,
                version: payload.cli.version,
                source: payload.cli.source,
                healthy: payload.cli.healthy
            ),
            coreVersion: versionResult.stdoutString.trimmingCharacters(in: .whitespacesAndNewlines),
            corePath: executableURL.path,
            desktopIsolationIsCompatibilityLayer: true
        )
    }

    private func runCore(_ arguments: [String]) async throws -> ProcessResult {
        guard let executableURL else { throw JimiDeckError.coreNotFound }
        let result = try await runner.run(
            executableURL: executableURL,
            arguments: arguments,
            environment: Self.coreEnvironment
        )
        guard result.exitCode == 0 else {
            throw JimiDeckError.coreFailure(Self.message(from: result))
        }
        return result
    }

    static func resolveExecutable(bundle: Bundle = .main) -> URL? {
        let fileManager = FileManager.default
        let candidates = [
            bundle.url(forResource: "codex-profile", withExtension: nil, subdirectory: "Core"),
            bundle.resourceURL?.appending(path: "codex-profile"),
            URL(filePath: "/opt/homebrew/bin/codex-profile"),
            URL(filePath: "/usr/local/bin/codex-profile"),
        ].compactMap { $0 }

        return candidates.first { fileManager.isExecutableFile(atPath: $0.path) }
    }

    static let coreEnvironment = [
        "CODEX_PROFILE_NO_UPDATE_CHECK": "1",
        "DO_NOT_TRACK": "1",
    ]

    static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    static func terminalLauncherScript(
        launcherURL: URL,
        coreURL: URL,
        profileID: String,
        projectURL: URL
    ) -> String {
        """
        #!/bin/zsh
        /bin/rm -f -- \(shellQuote(launcherURL.path))
        cd -- \(shellQuote(projectURL.path)) || exit 1
        exec /usr/bin/env CODEX_PROFILE_NO_UPDATE_CHECK=1 \(shellQuote(coreURL.path)) cli \(shellQuote(profileID))

        """
    }

    private static func writeTerminalLauncher(
        coreURL: URL,
        profileID: String,
        projectURL: URL
    ) throws -> URL {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appending(path: "JimiDeck-Launchers", directoryHint: .isDirectory)
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let launcherURL = directory.appending(path: "launch-\(UUID().uuidString).command")
        let script = terminalLauncherScript(
            launcherURL: launcherURL,
            coreURL: coreURL,
            profileID: profileID,
            projectURL: projectURL
        )
        try Data(script.utf8).write(to: launcherURL, options: .atomic)
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: launcherURL.path)
        return launcherURL
    }

    private static func message(from result: ProcessResult) -> String {
        let stderr = result.stderrString.trimmingCharacters(in: .whitespacesAndNewlines)
        let stdout = result.stdoutString.trimmingCharacters(in: .whitespacesAndNewlines)
        return stderr.isEmpty ? (stdout.isEmpty ? "未知错误（退出码 \(result.exitCode)）" : stdout) : stderr
    }
}

private struct DoctorPayload: Decodable {
    struct Desktop: Decodable {
        let found: Bool
        let path: String?
        let appPath: String?
        let product: String?
        let bundleID: String?

        enum CodingKeys: String, CodingKey {
            case found, path, product
            case appPath = "app_path"
            case bundleID = "bundle_id"
        }
    }

    struct CLI: Decodable {
        let found: Bool
        let path: String?
        let version: String?
        let source: String?
        let healthy: Bool
    }

    let desktop: Desktop
    let cli: CLI
}
