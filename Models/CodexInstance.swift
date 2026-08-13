import Foundation

enum CodexInstanceType: String, Codable, CaseIterable, Identifiable, Sendable {
    case desktop
    case cli

    var id: String { rawValue }

    var title: String {
        switch self {
        case .desktop: "Desktop"
        case .cli: "CLI"
        }
    }

    var subtitle: String {
        switch self {
        case .desktop: "图形界面 Codex"
        case .cli: "终端 Codex"
        }
    }

    var symbolName: String {
        switch self {
        case .desktop: "macwindow"
        case .cli: "terminal"
        }
    }
}

struct CodexInstance: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var displayName: String
    let type: CodexInstanceType
    let profileId: String
    let createdAt: Date
    var lastUsedAt: Date?

    var isSystem: Bool { profileId == "default" }
    var isImported: Bool { !isSystem && !ProfileID.isManaged(profileId) }

    static let defaultDesktop = CodexInstance(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        displayName: "Default Desktop",
        type: .desktop,
        profileId: "default",
        createdAt: .distantPast
    )

    static let defaultCLI = CodexInstance(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        displayName: "Default CLI",
        type: .cli,
        profileId: "default",
        createdAt: .distantPast
    )
}

enum ProfileID {
    struct Components: Equatable {
        let type: CodexInstanceType
        let id: UUID
    }

    static func make(for type: CodexInstanceType, id: UUID = UUID()) -> String {
        "jimideck-\(type.rawValue)-\(id.uuidString.lowercased())"
    }

    static func isManaged(_ value: String) -> Bool {
        parse(value) != nil
    }

    static func parse(_ value: String) -> Components? {
        for type in CodexInstanceType.allCases {
            let prefix = "jimideck-\(type.rawValue)-"
            guard value.hasPrefix(prefix) else { continue }
            let rawID = String(value.dropFirst(prefix.count))
            guard let id = UUID(uuidString: rawID) else { return nil }
            return Components(type: type, id: id)
        }
        return nil
    }
}
