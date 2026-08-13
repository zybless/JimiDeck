import Foundation
import XCTest

@testable import JimiDeck

final class JSONFileStoreTests: XCTestCase {
    func testRoundTrip() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "JimiDeckTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "instances.json")
        let store = JSONFileStore<[CodexInstance]>(url: url, defaultValue: [])
        let instance = CodexInstance(
            id: UUID(),
            displayName: "Work",
            type: .cli,
            profileId: ProfileID.make(for: .cli),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let initial = try await store.load()
        XCTAssertEqual(initial, [])
        try await store.save([instance])
        let reloaded = try await store.load()
        XCTAssertEqual(reloaded, [instance])
    }

    func testRecoversCorruptPrimaryFromBackup() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "JimiDeckTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "instances.json")
        let store = JSONFileStore<[CodexInstance]>(url: url, defaultValue: [])
        let instance = CodexInstance(
            id: UUID(),
            displayName: "Recover Me",
            type: .desktop,
            profileId: ProfileID.make(for: .desktop),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        try await store.save([instance])
        try Data("not-json".utf8).write(to: url, options: .atomic)

        let recovered = try await store.loadWithRecovery()
        XCTAssertTrue(recovered.recoveredFromBackup)
        XCTAssertEqual(recovered.value, [instance])
        let restoredPrimary = try await store.load()
        XCTAssertEqual(restoredPrimary, [instance])
    }

    func testThrowsWhenPrimaryAndBackupAreBothCorrupt() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "JimiDeckTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "instances.json")
        try Data("not-json".utf8).write(to: url)
        try Data("also-not-json".utf8).write(to: url.appendingPathExtension("backup"))
        let store = JSONFileStore<[CodexInstance]>(url: url, defaultValue: [])

        do {
            _ = try await store.loadWithRecovery()
            XCTFail("Expected corrupt primary and backup to throw")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }
}

final class ProcessRunnerTests: XCTestCase {
    func testDrainsLargeStandardOutputAndErrorWithoutDeadlock() async throws {
        let result = try await ProcessRunner().run(
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: [
                "-c",
                "/usr/bin/yes output | /usr/bin/head -c 1048576; "
                    + "/usr/bin/yes error | /usr/bin/head -c 1048576 >&2",
            ]
        )

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.stdout.count, 1_048_576)
        XCTAssertEqual(result.stderr.count, 1_048_576)
    }
}
