import Foundation

struct RecentProject: Codable, Identifiable, Hashable, Sendable {
    var id: String { path }
    let path: String
    var displayName: String
    var lastOpenedAt: Date
}
