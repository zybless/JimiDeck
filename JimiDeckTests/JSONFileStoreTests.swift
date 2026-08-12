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
}
