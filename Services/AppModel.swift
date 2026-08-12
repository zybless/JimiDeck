import AppKit
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var instances: [CodexInstance] = []
    @Published private(set) var recentProjects: [RecentProject] = []
    @Published private(set) var environment: EnvironmentReport = .unavailable()
    @Published var isWorking = false
    @Published var presentedError: String?

    private let instanceStore: JSONFileStore<[CodexInstance]>
    private let projectStore: JSONFileStore<[RecentProject]>
    private let core: any CoreAdapter

    init(
        instanceStore: JSONFileStore<[CodexInstance]>,
        projectStore: JSONFileStore<[RecentProject]>,
        core: any CoreAdapter
    ) {
        self.instanceStore = instanceStore
        self.projectStore = projectStore
        self.core = core
    }

    static func live() -> AppModel {
        AppModel(
            instanceStore: JSONFileStore(url: AppSupportPaths.instances(), defaultValue: []),
            projectStore: JSONFileStore(url: AppSupportPaths.recentProjects(), defaultValue: []),
            core: CodexProfilesCLIAdapter()
        )
    }

    var visibleInstances: [CodexInstance] {
        var values: [CodexInstance] = []
        if environment.desktop.found { values.append(.defaultDesktop) }
        if environment.cli.found { values.append(.defaultCLI) }
        values.append(
            contentsOf: instances.sorted {
                ($0.lastUsedAt ?? $0.createdAt) > ($1.lastUsedAt ?? $1.createdAt)
            })
        return values
    }

    func bootstrap() async {
        do {
            async let storedInstances = instanceStore.load()
            async let storedProjects = projectStore.load()
            instances = try await storedInstances.filter { ProfileID.isManaged($0.profileId) }
            recentProjects =
                try await storedProjects
                .filter { FileManager.default.fileExists(atPath: $0.path) }
                .sorted { $0.lastOpenedAt > $1.lastOpenedAt }
        } catch {
            present(error)
        }
        await recoverOrphanProfiles()
        await refreshEnvironment()
    }

    func refreshEnvironment() async {
        isWorking = true
        defer { isWorking = false }
        do {
            environment = try await core.diagnose()
        } catch {
            environment = .unavailable(corePath: core.executableURL?.path ?? "未找到")
            present(error)
        }
    }

    func createInstance(name: String, type: CodexInstanceType) async -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            present(JimiDeckError.invalidName)
            return false
        }
        let id = UUID()
        let profileID = ProfileID.make(for: type, id: id)
        let instance = CodexInstance(
            id: id,
            displayName: trimmed,
            type: type,
            profileId: profileID,
            createdAt: Date()
        )

        isWorking = true
        defer { isWorking = false }
        do {
            try await core.createProfile(profileID)
            var updated = instances
            updated.append(instance)
            do {
                try await instanceStore.save(updated)
                instances = updated
                return true
            } catch {
                try? await core.removeProfile(profileID)
                throw error
            }
        } catch {
            present(error)
            return false
        }
    }

    func launchDesktop(_ instance: CodexInstance) async {
        guard environment.desktop.found else {
            present(JimiDeckError.desktopNotInstalled)
            return
        }
        await performLaunch(instance) {
            try await self.core.launchDesktop(profileID: instance.profileId)
        }
    }

    func launchCLI(_ instance: CodexInstance, projectURL: URL) async {
        guard environment.cli.found else {
            present(JimiDeckError.cliNotInstalled)
            return
        }
        await performLaunch(instance) {
            try await self.core.launchCLI(profileID: instance.profileId, projectURL: projectURL)
            await self.recordRecentProject(projectURL)
        }
    }

    func rename(_ instance: CodexInstance, to name: String) async {
        guard !instance.isSystem else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            present(JimiDeckError.invalidName)
            return
        }
        guard let index = instances.firstIndex(where: { $0.id == instance.id }) else { return }
        var updated = instances
        updated[index].displayName = trimmed
        await persistInstances(updated)
    }

    func remove(_ instance: CodexInstance) async -> Bool {
        guard !instance.isSystem, ProfileID.isManaged(instance.profileId) else {
            present(JimiDeckError.unmanagedProfile)
            return false
        }
        isWorking = true
        defer { isWorking = false }
        do {
            try await core.removeProfile(instance.profileId)
            let updated = instances.filter { $0.id != instance.id }
            try await instanceStore.save(updated)
            instances = updated
            return true
        } catch {
            present(error)
            return false
        }
    }

    private func performLaunch(
        _ instance: CodexInstance,
        operation: @escaping () async throws -> Void
    ) async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await operation()
            guard !instance.isSystem,
                let index = instances.firstIndex(where: { $0.id == instance.id })
            else { return }
            var updated = instances
            updated[index].lastUsedAt = Date()
            await persistInstances(updated)
        } catch {
            present(error)
        }
    }

    private func recordRecentProject(_ url: URL) async {
        let canonical = url.standardizedFileURL.path
        var updated = recentProjects.filter { $0.path != canonical }
        updated.insert(
            RecentProject(path: canonical, displayName: url.lastPathComponent, lastOpenedAt: Date()),
            at: 0
        )
        updated = Array(updated.prefix(20))
        do {
            try await projectStore.save(updated)
            recentProjects = updated
        } catch {
            present(error)
        }
    }

    private func recoverOrphanProfiles() async {
        do {
            let knownProfiles = Set(instances.map(\.profileId))
            let orphanProfiles = try await core.listProfiles().filter { !knownProfiles.contains($0) }
            guard !orphanProfiles.isEmpty else { return }

            var recovered = instances
            for profileID in orphanProfiles {
                guard let components = ProfileID.parse(profileID) else { continue }
                recovered.append(
                    CodexInstance(
                        id: components.id,
                        displayName: components.type == .desktop ? "Recovered Desktop" : "Recovered CLI",
                        type: components.type,
                        profileId: profileID,
                        createdAt: Date()
                    )
                )
            }
            try await instanceStore.save(recovered)
            instances = recovered
        } catch {
            // Recovery is best-effort. A missing Core is reported by environment diagnostics.
        }
    }

    private func persistInstances(_ updated: [CodexInstance]) async {
        do {
            try await instanceStore.save(updated)
            instances = updated
        } catch {
            present(error)
        }
    }

    private func present(_ error: Error) {
        presentedError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
