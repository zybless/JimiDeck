import Foundation

struct EnvironmentReport: Codable, Equatable, Sendable {
    struct Desktop: Codable, Equatable, Sendable {
        let found: Bool
        let path: String?
        let appPath: String?
        let product: String?
        let bundleID: String?
    }

    struct CLI: Codable, Equatable, Sendable {
        let found: Bool
        let path: String?
        let version: String?
        let source: String?
        let healthy: Bool
    }

    let desktop: Desktop
    let cli: CLI
    let coreVersion: String
    let corePath: String
    let desktopIsolationIsCompatibilityLayer: Bool

    static func unavailable(corePath: String = "未找到") -> EnvironmentReport {
        EnvironmentReport(
            desktop: .init(found: false, path: nil, appPath: nil, product: nil, bundleID: nil),
            cli: .init(found: false, path: nil, version: nil, source: nil, healthy: false),
            coreVersion: "不可用",
            corePath: corePath,
            desktopIsolationIsCompatibilityLayer: true
        )
    }
}
