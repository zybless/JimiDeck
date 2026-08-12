import Foundation

protocol CoreAdapter: Sendable {
    var executableURL: URL? { get }

    func createProfile(_ profileID: String) async throws
    func listProfiles() async throws -> [String]
    func removeProfile(_ profileID: String) async throws
    func launchDesktop(profileID: String) async throws
    func launchCLI(profileID: String, projectURL: URL) async throws
    func diagnose() async throws -> EnvironmentReport
}

enum JimiDeckError: LocalizedError, Equatable {
    case coreNotFound
    case coreFailure(String)
    case invalidName
    case unmanagedProfile
    case desktopNotInstalled
    case cliNotInstalled
    case projectMissing
    case persistence(String)

    var errorDescription: String? {
        switch self {
        case .coreNotFound:
            "找不到 JimiDeck Core。开发版可安装 codex-profile 0.7.0。"
        case .coreFailure(let message):
            "Core 操作失败：\(message)"
        case .invalidName:
            "请输入实例名称。"
        case .unmanagedProfile:
            "JimiDeck 拒绝删除不属于自己的 Profile。"
        case .desktopNotInstalled:
            "未检测到 ChatGPT Desktop。"
        case .cliNotInstalled:
            "未检测到可用的 Codex CLI。"
        case .projectMissing:
            "项目目录不存在，请重新选择。"
        case .persistence(let message):
            "保存本地数据失败：\(message)"
        }
    }
}
