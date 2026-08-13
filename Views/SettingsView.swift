import AppKit
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: AppModel
    @State private var selection: SettingsSection = .instances

    init() {
        #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("--ui-test-settings-diagnostics") {
                _selection = State(initialValue: .diagnostics)
            } else if arguments.contains("--ui-test-settings-about") {
                _selection = State(initialValue: .about)
            }
        #endif
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("设置")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button("完成") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            NavigationSplitView {
                List(SettingsSection.allCases, selection: $selection) { section in
                    Label(section.title, systemImage: section.symbol)
                        .tag(section)
                }
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
            } detail: {
                Group {
                    switch selection {
                    case .instances:
                        InstanceManagementView()
                    case .diagnostics:
                        DiagnosticsView()
                    case .about:
                        AboutView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 780, idealWidth: 880, minHeight: 560, idealHeight: 640)
    }
}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case instances
    case diagnostics
    case about

    var id: String { rawValue }
    var title: String {
        switch self {
        case .instances: "实例管理"
        case .diagnostics: "诊断"
        case .about: "关于"
        }
    }
    var symbol: String {
        switch self {
        case .instances: "rectangle.stack"
        case .diagnostics: "stethoscope"
        case .about: "info.circle"
        }
    }
}

private struct InstanceManagementView: View {
    @EnvironmentObject private var model: AppModel
    @State private var deleting: CodexInstance?
    @State private var detaching: CodexInstance?
    @State private var editing: CodexInstance?
    @State private var importingProfileID: String?
    @State private var editedName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("实例管理")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button {
                    Task { await model.refreshProfiles(reportErrors: true) }
                } label: {
                    Label("重新扫描", systemImage: "arrow.clockwise")
                }
                .disabled(model.isWorking)
            }
            Group {
                if model.instances.isEmpty && model.externalProfiles.isEmpty {
                    ContentUnavailableView(
                        "没有自定义实例",
                        systemImage: "rectangle.stack",
                        description: Text("在主窗口创建实例，或重新扫描命令行 Profile。")
                    )
                } else {
                    List {
                        if !model.instances.isEmpty {
                            Section("已管理") {
                                ForEach(model.instances) { instance in
                                    HStack(spacing: 12) {
                                        Image(systemName: instance.type.symbolName)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundStyle(Color.accentColor)
                                            .frame(width: 34, height: 34)
                                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))

                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 8) {
                                                Text(instance.displayName)
                                                    .font(.body.weight(.medium))
                                                InstanceTag(instance.type.title)
                                                if instance.isImported {
                                                    InstanceTag("外部导入")
                                                }
                                            }
                                            Text(instance.profileId)
                                                .font(.caption.monospaced())
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                                .textSelection(.enabled)
                                        }

                                        Spacer(minLength: 12)

                                        Menu {
                                            Button("重命名") {
                                                editedName = instance.displayName
                                                editing = instance
                                            }
                                            Divider()
                                            if instance.isImported {
                                                Button("仅从 JimiDeck 移除") {
                                                    detaching = instance
                                                }
                                                Button("删除底层 Profile", role: .destructive) {
                                                    deleting = instance
                                                }
                                            } else {
                                                Button("删除", role: .destructive) {
                                                    deleting = instance
                                                }
                                            }
                                        } label: {
                                            Image(systemName: "ellipsis.circle")
                                                .font(.title3)
                                        }
                                        .menuStyle(.borderlessButton)
                                        .fixedSize()
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                        }

                        if !model.externalProfiles.isEmpty {
                            Section("发现的命令行 Profile") {
                                ForEach(model.externalProfiles, id: \.self) { profileID in
                                    HStack(spacing: 12) {
                                        Image(systemName: "rectangle.stack.badge.plus")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 34, height: 34)
                                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(profileID)
                                                .font(.body.monospaced().weight(.medium))
                                            Text("选择 Desktop 或 CLI 后导入，不复制现有数据")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Button("导入") {
                                            importingProfileID = profileID
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(24)
        .confirmationDialog(
            "删除“\(deleting?.displayName ?? "")”？",
            isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
            titleVisibility: .visible
        ) {
            Button(deleting?.isImported == true ? "永久删除底层 Profile" : "永久删除实例", role: .destructive) {
                guard let deleting else { return }
                Task {
                    _ = await model.remove(deleting)
                    self.deleting = nil
                }
            }
            Button("取消", role: .cancel) { deleting = nil }
        } message: {
            if deleting?.isImported == true {
                Text(
                    "请先关闭使用该 Profile 的 ChatGPT 或终端窗口。这会从 codex-profile 中永久删除该 Profile、"
                        + "本地数据和登录状态；若只想停止管理，请选择“仅从 JimiDeck 移除”。"
                )
            } else {
                Text("请先关闭使用该实例的 ChatGPT 或终端窗口。这会删除本地 Profile 数据和登录状态，但不会删除任何项目代码。")
            }
        }
        .confirmationDialog(
            "从 JimiDeck 移除“\(detaching?.displayName ?? "")”？",
            isPresented: Binding(get: { detaching != nil }, set: { if !$0 { detaching = nil } }),
            titleVisibility: .visible
        ) {
            Button("仅移除管理记录") {
                guard let detaching else { return }
                Task {
                    _ = await model.detachImportedProfile(detaching)
                    self.detaching = nil
                }
            }
            Button("取消", role: .cancel) { detaching = nil }
        } message: {
            Text("底层 Profile“\(detaching?.profileId ?? "")”及登录状态会保留，并会重新出现在待导入列表中。")
        }
        .sheet(item: $editing) { instance in
            VStack(spacing: 0) {
                HStack {
                    Text("重命名实例")
                        .font(.headline)
                    Spacer()
                    Button("取消") { editing = nil }
                        .keyboardShortcut(.cancelAction)
                }
                .padding(20)

                Divider()

                TextField("名称", text: $editedName)
                    .textFieldStyle(.roundedBorder)
                    .padding(20)

                Divider()

                HStack {
                    Spacer()
                    Button("保存") {
                        Task {
                            await model.rename(instance, to: editedName)
                            editing = nil
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding(16)
            }
            .frame(minWidth: 420, minHeight: 190)
        }
        .sheet(
            isPresented: Binding(
                get: { importingProfileID != nil },
                set: { if !$0 { importingProfileID = nil } }
            )
        ) {
            if let importingProfileID {
                ImportProfileView(profileID: importingProfileID)
                    .environmentObject(model)
            }
        }
    }
}

private struct InstanceTag: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary, in: Capsule())
    }
}

private struct ImportProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: AppModel
    let profileID: String
    @State private var selectedType: CodexInstanceType?
    @State private var name: String

    init(profileID: String) {
        self.profileID = profileID
        _name = State(initialValue: profileID)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("导入 Profile")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(20)

            Divider()

            Form {
                LabeledContent("底层 Profile") {
                    Text(profileID)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                }
                TextField("显示名称", text: $name)
                Picker("实例类型", selection: $selectedType) {
                    Text("请选择").tag(CodexInstanceType?.none)
                    ForEach(CodexInstanceType.allCases) { type in
                        Text(typeIsAvailable(type) ? type.title : "\(type.title)（当前不可用）")
                            .tag(Optional(type))
                            .disabled(!typeIsAvailable(type))
                    }
                }
                Text("导入不会移动或复制 Profile。类型导入后固定，但显示名称可以随时修改。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .formStyle(.grouped)
            .padding(.horizontal, 8)

            Divider()

            HStack {
                Spacer()
                Button("导入") {
                    guard let selectedType else { return }
                    Task {
                        if await model.importProfile(profileID: profileID, name: name, type: selectedType) {
                            dismiss()
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(
                    selectedType == nil
                        || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || model.isWorking
                )
            }
            .padding(16)
        }
        .frame(minWidth: 520, minHeight: 360)
    }

    private func typeIsAvailable(_ type: CodexInstanceType) -> Bool {
        switch type {
        case .desktop: model.environment.desktop.found
        case .cli: model.environment.cli.found
        }
    }
}

private struct DiagnosticsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("环境诊断")
                        .font(.title2.weight(.semibold))
                    Spacer()
                    Button("打开数据目录") {
                        let directory = AppSupportPaths.root()
                        try? FileManager.default.createDirectory(
                            at: directory,
                            withIntermediateDirectories: true,
                            attributes: [.posixPermissions: 0o700]
                        )
                        NSWorkspace.shared.open(directory)
                    }
                    Button("复制诊断信息") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(diagnosticSummary, forType: .string)
                    }
                    Button("重新检测") {
                        Task { await model.refreshEnvironment() }
                    }
                    .disabled(model.isWorking)
                }

                VStack(spacing: 0) {
                    DiagnosticRow(title: "JimiDeck", value: "正常")
                    DiagnosticRow(title: "Core", value: model.environment.coreVersion)
                    DiagnosticRow(title: "Core 路径", value: model.environment.corePath, monospaced: true)
                    DiagnosticRow(
                        title: "ChatGPT Desktop",
                        value: model.environment.desktop.found ? "已安装" : "未安装"
                    )
                    DiagnosticRow(
                        title: "Desktop 路径",
                        value: model.environment.desktop.appPath ?? "—",
                        monospaced: true
                    )
                    DiagnosticRow(title: "Codex CLI", value: model.environment.cli.found ? "已安装" : "未安装")
                    DiagnosticRow(title: "CLI 版本", value: model.environment.cli.version ?? "—")
                    DiagnosticRow(title: "CLI 来源", value: model.environment.cli.source ?? "—", showDivider: false)
                }
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.separator.opacity(0.55))
                }

                Label(
                    "Desktop 多实例依赖当前 ChatGPT Electron 启动行为，属于兼容层；每次官方 App 更新后都应重新验证。",
                    systemImage: "exclamationmark.shield"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(12)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var diagnosticSummary: String {
        let report = model.environment
        return """
            JimiDeck \(Bundle.main.releaseVersion) Alpha
            Core: \(report.coreVersion)
            Core path: \(report.corePath)
            ChatGPT Desktop: \(report.desktop.found ? "available" : "unavailable")
            Desktop path: \(report.desktop.appPath ?? "—")
            Codex CLI: \(report.cli.found ? "available" : "unavailable")
            CLI version: \(report.cli.version ?? "—")
            CLI source: \(report.cli.source ?? "—")
            Managed instances: \(model.instances.count)
            Discovered external profiles: \(model.externalProfiles.count)
            """
    }
}

private struct DiagnosticRow: View {
    let title: String
    let value: String
    var monospaced = false
    var showDivider = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 20) {
                Text(title)
                    .foregroundStyle(.secondary)
                    .frame(width: 140, alignment: .leading)
                Text(value)
                    .font(monospaced ? .callout.monospaced() : .callout)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if showDivider {
                Divider()
                    .padding(.leading, 156)
            }
        }
    }
}

private struct AboutView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 104, height: 104)
            Text("JimiDeck")
                .font(.title.weight(.semibold))
            Text("Codex Instance Manager")
                .foregroundStyle(.secondary)
            Divider().frame(width: 280)
            Text("Version \(Bundle.main.releaseVersion) Alpha")
                .foregroundStyle(.secondary)
            Text("© 2026 JimiDeck")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension Bundle {
    fileprivate var releaseVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.2.0"
    }
}
