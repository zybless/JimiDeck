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
}
