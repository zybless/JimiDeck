import Foundation

actor JSONFileStore<Value: Codable & Sendable> {
    private let url: URL
    private let defaultValue: Value
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(url: URL, defaultValue: Value) {
        self.url = url
        self.defaultValue = defaultValue
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() throws -> Value {
        guard FileManager.default.fileExists(atPath: url.path) else { return defaultValue }
        return try decoder.decode(Value.self, from: Data(contentsOf: url))
    }

    func save(_ value: Value) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic)
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
}

enum AppSupportPaths {
    static func root(fileManager: FileManager = .default) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appending(path: "JimiDeck", directoryHint: .isDirectory)
    }

    static func instances(fileManager: FileManager = .default) -> URL {
        root(fileManager: fileManager).appending(path: "instances.json")
    }

    static func recentProjects(fileManager: FileManager = .default) -> URL {
        root(fileManager: fileManager).appending(path: "recent-projects.json")
    }
}
