import AppKit
import SwiftUI

struct ProjectPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: AppModel
    let instance: CodexInstance

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("选择项目")
                        .font(.title2.weight(.semibold))
                    Text("使用 \(instance.displayName) 启动 Codex CLI")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)

            Divider()

            Group {
                if model.recentProjects.isEmpty {
                    ContentUnavailableView(
                        "没有最近项目",
                        systemImage: "folder",
                        description: Text("选择一个项目目录开始使用。")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("最近项目")
                                .font(.headline)

                            LazyVStack(spacing: 6) {
                                ForEach(model.recentProjects) { project in
                                    Button {
                                        launch(URL(filePath: project.path, directoryHint: .isDirectory))
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: "folder")
                                                .foregroundStyle(.secondary)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(project.displayName)
                                                    .font(.body.weight(.medium))
                                                Text(project.path.abbreviatingHomeDirectory)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                            }
                                            Spacer()
                                        }
                                        .contentShape(Rectangle())
                                        .padding(10)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(24)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            HStack {
                Button {
                    chooseOtherProject()
                } label: {
                    Label("打开其他项目…", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(minWidth: 560, idealWidth: 620, minHeight: 460, idealHeight: 540)
    }

    private func chooseOtherProject() {
        let panel = NSOpenPanel()
        panel.title = "选择项目目录"
        panel.prompt = "打开"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        launch(url)
    }

    private func launch(_ url: URL) {
        dismiss()
        Task { await model.launchCLI(instance, projectURL: url) }
    }
}

extension String {
    fileprivate var abbreviatingHomeDirectory: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        guard hasPrefix(home) else { return self }
        return "~" + dropFirst(home.count)
    }
}
