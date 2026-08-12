import XCTest

@testable import JimiDeck

final class QuotingTests: XCTestCase {
    func testShellQuoteHandlesSpacesAndApostrophes() {
        XCTAssertEqual(
            CodexProfilesCLIAdapter.shellQuote("/tmp/Jimi's Project"),
            "'/tmp/Jimi'\\''s Project'"
        )
    }

    func testTerminalLauncherIsPrivateAndDeletesItself() {
        let script = CodexProfilesCLIAdapter.terminalLauncherScript(
            launcherURL: URL(filePath: "/tmp/Jimi Deck.command"),
            coreURL: URL(filePath: "/Applications/Jimi's Core/codex-profile"),
            profileID: "jimideck-cli-test",
            projectURL: URL(filePath: "/tmp/Jimi's Project")
        )

        XCTAssertTrue(script.hasPrefix("#!/bin/zsh\n"))
        XCTAssertTrue(script.contains("/bin/rm -f -- '/tmp/Jimi Deck.command'"))
        XCTAssertTrue(script.contains("cd -- '/tmp/Jimi'\\''s Project'"))
        XCTAssertTrue(script.contains("CODEX_PROFILE_NO_UPDATE_CHECK=1"))
        XCTAssertTrue(script.contains("'/Applications/Jimi'\\''s Core/codex-profile' cli 'jimideck-cli-test'"))
    }
}
