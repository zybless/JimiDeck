import Foundation
import XCTest

@testable import JimiDeck

final class ProfileIDTests: XCTestCase {
    func testDesktopAndCLIIDsAreDistinctAndManaged() {
        let id = UUID(uuidString: "A82FBD0A-59DD-4FE9-B98A-313E00704FE2")!
        let desktop = ProfileID.make(for: .desktop, id: id)
        let cli = ProfileID.make(for: .cli, id: id)

        XCTAssertEqual(desktop, "jimideck-desktop-a82fbd0a-59dd-4fe9-b98a-313e00704fe2")
        XCTAssertEqual(cli, "jimideck-cli-a82fbd0a-59dd-4fe9-b98a-313e00704fe2")
        XCTAssertNotEqual(desktop, cli)
        XCTAssertTrue(ProfileID.isManaged(desktop))
        XCTAssertTrue(ProfileID.isManaged(cli))
        XCTAssertFalse(ProfileID.isManaged("work"))
        XCTAssertFalse(ProfileID.isManaged("default"))
        XCTAssertEqual(ProfileID.parse(desktop), .init(type: .desktop, id: id))
        XCTAssertEqual(ProfileID.parse(cli), .init(type: .cli, id: id))
        XCTAssertNil(ProfileID.parse("jimideck-cli-not-a-uuid"))
    }

    func testSystemInstancesRemainSeparate() {
        XCTAssertNotEqual(CodexInstance.defaultDesktop.id, CodexInstance.defaultCLI.id)
        XCTAssertEqual(CodexInstance.defaultDesktop.type, .desktop)
        XCTAssertEqual(CodexInstance.defaultCLI.type, .cli)
        XCTAssertTrue(CodexInstance.defaultDesktop.isSystem)
        XCTAssertTrue(CodexInstance.defaultCLI.isSystem)
    }

    @MainActor
    func testExternalProfileCanBeImportedAndPersists() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "JimiDeckImportTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        let instanceStore = JSONFileStore<[CodexInstance]>(
            url: directory.appending(path: "instances.json"),
            defaultValue: []
        )
        let projectStore = JSONFileStore<[RecentProject]>(
            url: directory.appending(path: "recent-projects.json"),
            defaultValue: []
        )
        let core = ImportTestCore(profiles: ["default", "plus2"])
        let model = AppModel(instanceStore: instanceStore, projectStore: projectStore, core: core)

        await model.bootstrap()
        XCTAssertEqual(model.externalProfiles, ["plus2"])
        XCTAssertTrue(model.instances.isEmpty)

        let imported = await model.importProfile(profileID: "plus2", name: "个人账号", type: .desktop)
        XCTAssertTrue(imported)
        XCTAssertTrue(model.externalProfiles.isEmpty)
        XCTAssertEqual(model.instances.count, 1)
        XCTAssertEqual(model.instances.first?.displayName, "个人账号")
        XCTAssertEqual(model.instances.first?.profileId, "plus2")
        XCTAssertEqual(model.instances.first?.type, .desktop)
        XCTAssertEqual(model.instances.first?.isImported, true)

        let reloaded = AppModel(instanceStore: instanceStore, projectStore: projectStore, core: core)
        await reloaded.bootstrap()
        XCTAssertEqual(reloaded.instances.count, 1)
        XCTAssertEqual(reloaded.instances.first?.id, model.instances.first?.id)
        XCTAssertEqual(reloaded.instances.first?.displayName, "个人账号")
        XCTAssertEqual(reloaded.instances.first?.profileId, "plus2")
        XCTAssertEqual(reloaded.instances.first?.type, .desktop)
        XCTAssertTrue(reloaded.externalProfiles.isEmpty)
    }

    @MainActor
    func testDetachingImportedProfileKeepsUnderlyingProfile() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "JimiDeckDetachTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        let instanceStore = JSONFileStore<[CodexInstance]>(
            url: directory.appending(path: "instances.json"),
            defaultValue: []
        )
        let projectStore = JSONFileStore<[RecentProject]>(
            url: directory.appending(path: "recent-projects.json"),
            defaultValue: []
        )
        let core = ImportTestCore(profiles: ["default", "plus2"])
        let model = AppModel(instanceStore: instanceStore, projectStore: projectStore, core: core)

        await model.bootstrap()
        let imported = await model.importProfile(profileID: "plus2", name: "plus2", type: .cli)
        XCTAssertTrue(imported)
        let instance = try XCTUnwrap(model.instances.first)
        let detached = await model.detachImportedProfile(instance)
        XCTAssertTrue(detached)

        XCTAssertTrue(model.instances.isEmpty)
        XCTAssertEqual(model.externalProfiles, ["plus2"])
        let removedProfiles = await core.removedProfiles()
        XCTAssertTrue(removedProfiles.isEmpty)
    }

    @MainActor
    func testImportRejectsProfileRemovedAfterDiscovery() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "JimiDeckMissingImportTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        let instanceStore = JSONFileStore<[CodexInstance]>(
            url: directory.appending(path: "instances.json"),
            defaultValue: []
        )
        let projectStore = JSONFileStore<[RecentProject]>(
            url: directory.appending(path: "recent-projects.json"),
            defaultValue: []
        )
        let core = ImportTestCore(profiles: ["default", "plus2"])
        let model = AppModel(instanceStore: instanceStore, projectStore: projectStore, core: core)

        await model.bootstrap()
        await core.setProfiles(["default"])
        let imported = await model.importProfile(profileID: "plus2", name: "plus2", type: .cli)

        XCTAssertFalse(imported)
        XCTAssertTrue(model.instances.isEmpty)
        XCTAssertTrue(model.externalProfiles.isEmpty)
        XCTAssertEqual(model.presentedError, JimiDeckError.profileMissing.errorDescription)
    }

    @MainActor
    func testRemoveRollsBackMetadataWhenCoreRemovalFails() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "JimiDeckRemoveRollbackTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        let profileID = ProfileID.make(for: .cli)
        let instance = CodexInstance(
            id: UUID(),
            displayName: "Keep Me",
            type: .cli,
            profileId: profileID,
            createdAt: Date()
        )
        let instanceStore = JSONFileStore<[CodexInstance]>(
            url: directory.appending(path: "instances.json"),
            defaultValue: []
        )
        try await instanceStore.save([instance])
        let storedBeforeRemoval = try await instanceStore.load()
        let projectStore = JSONFileStore<[RecentProject]>(
            url: directory.appending(path: "recent-projects.json"),
            defaultValue: []
        )
        let core = ImportTestCore(profiles: ["default", profileID], removeShouldFail: true)
        let model = AppModel(instanceStore: instanceStore, projectStore: projectStore, core: core)

        await model.bootstrap()
        let removed = await model.remove(instance)

        XCTAssertFalse(removed)
        XCTAssertEqual(model.instances, storedBeforeRemoval)
        let persistedInstances = try await instanceStore.load()
        XCTAssertEqual(persistedInstances, storedBeforeRemoval)
    }
}

private actor ImportTestCore: CoreAdapter {
    nonisolated let executableURL: URL? = URL(filePath: "/tmp/codex-profile")
    private var profiles: [String]
    private var removed: [String] = []
    private let removeShouldFail: Bool

    init(profiles: [String], removeShouldFail: Bool = false) {
        self.profiles = profiles
        self.removeShouldFail = removeShouldFail
    }

    func createProfile(_ profileID: String) {
        profiles.append(profileID)
    }

    func listProfiles() -> [String] {
        profiles
    }

    func removeProfile(_ profileID: String) throws {
        if removeShouldFail { throw JimiDeckError.coreFailure("test removal failure") }
        profiles.removeAll { $0 == profileID }
        removed.append(profileID)
    }

    func launchDesktop(profileID: String) {}

    func launchCLI(profileID: String, projectURL: URL) {}

    func diagnose() -> EnvironmentReport {
        EnvironmentReport(
            desktop: .init(
                found: true,
                path: "/Applications/ChatGPT.app/Contents/MacOS/ChatGPT",
                appPath: "/Applications/ChatGPT.app",
                product: "ChatGPT",
                bundleID: "com.openai.codex"
            ),
            cli: .init(found: true, path: "/usr/local/bin/codex", version: "test", source: "test", healthy: true),
            coreVersion: "codex-profile test",
            corePath: executableURL?.path ?? "",
            desktopIsolationIsCompatibilityLayer: true
        )
    }

    func removedProfiles() -> [String] {
        removed
    }

    func setProfiles(_ values: [String]) {
        profiles = values
    }
}
