import Foundation

struct JSONFileLoadResult<Value: Sendable>: Sendable {
    let value: Value
    let recoveredFromBackup: Bool
}

actor JSONFileStore<Value: Codable & Sendable> {
    private let url: URL
    private let backupURL: URL
    private let defaultValue: Value
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(url: URL, defaultValue: Value) {
        self.url = url
        backupURL = url.appendingPathExtension("backup")
        self.defaultValue = defaultValue
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() throws -> Value {
        try loadWithRecovery().value
    }

    func loadWithRecovery() throws -> JSONFileLoadResult<Value> {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            do {
                let primaryData = try Data(contentsOf: url)
                let value = try decoder.decode(Value.self, from: primaryData)
                if !fileManager.fileExists(atPath: backupURL.path),
                    (try? primaryData.write(to: backupURL, options: .atomic)) != nil
                {
                    securePermissions(at: backupURL)
                }
                return JSONFileLoadResult(
                    value: value,
                    recoveredFromBackup: false
                )
            } catch {
                guard fileManager.fileExists(atPath: backupURL.path) else { throw error }
            }
        } else if !fileManager.fileExists(atPath: backupURL.path) {
            return JSONFileLoadResult(value: defaultValue, recoveredFromBackup: false)
        }

        let backupData = try Data(contentsOf: backupURL)
        let value = try decoder.decode(Value.self, from: backupData)
        try backupData.write(to: url, options: .atomic)
        securePermissions(at: url)
        return JSONFileLoadResult(value: value, recoveredFromBackup: true)
    }

    func save(_ value: Value) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic)
        securePermissions(at: url)

        if (try? data.write(to: backupURL, options: .atomic)) != nil {
            securePermissions(at: backupURL)
        }
    }

    private func securePermissions(at fileURL: URL) {
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: fileURL.path
        )
    }
}

enum AppSupportPaths {
    static func root(fileManager: FileManager = .default) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appending(path: "JimiDeck", directoryHint: .isDirectory)
    }

    static func instances(fileManager: FileManager = .default) -> URL {
        root(fileManager: fileManager).appending(path: "instances.json")
    }

    static func recentProjects(fileManager: FileManager = .default) -> URL {
        root(fileManager: fileManager).appending(path: "recent-projects.json")
    }
}
