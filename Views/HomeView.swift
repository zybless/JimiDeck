import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showsCreate = false
    @State private var showsSettings = false
    @State private var selectedCLI: CodexInstance?

    init() {
        #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            _showsCreate = State(initialValue: arguments.contains("--ui-test-create"))
            _showsSettings = State(
                initialValue: arguments.contains { $0.hasPrefix("--ui-test-settings") }
            )
            _selectedCLI = State(
                initialValue: arguments.contains("--ui-test-cli-picker") ? .defaultCLI : nil
            )
        #endif
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task { await model.bootstrap() }
        .sheet(isPresented: $showsCreate) {
            CreateInstanceView()
                .environmentObject(model)
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView()
                .environmentObject(model)
        }
        .sheet(item: $selectedCLI) { instance in
            ProjectPickerView(instance: instance)
                .environmentObject(model)
        }
        .alert(
            "JimiDeck",
            isPresented: Binding(
                get: { model.presentedError != nil },
                set: { if !$0 { model.presentedError = nil } }
            )
        ) {
            Button("好") { model.presentedError = nil }
        } message: {
            Text(model.presentedError ?? "")
        }
        .overlay {
            if model.isWorking {
                ProgressView()
                    .controlSize(.large)
                    .padding(22)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("JimiDeck")
                    .font(.title2.weight(.semibold))
                Text("Codex Instance Manager")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showsCreate = true
            } label: {
                Image(systemName: "plus")
                    .frame(width: 22, height: 22)
            }
            .help("创建 Codex 实例")
            .disabled(!model.environment.desktop.found && !model.environment.cli.found)

            Button {
                showsSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .frame(width: 22, height: 22)
            }
            .help("设置与诊断")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var content: some View {
        if !model.environment.desktop.found && !model.environment.cli.found {
            EmptyEnvironmentView()
        } else if model.visibleInstances.isEmpty {
            ContentUnavailableView(
                "还没有 Codex 实例",
                systemImage: "rectangle.stack.badge.plus",
                description: Text("点击右上角的 + 创建 Desktop 或 CLI 实例。")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(model.visibleInstances) { instance in
                        InstanceCard(instance: instance) {
                            switch instance.type {
                            case .desktop:
                                Task { await model.launchDesktop(instance) }
                            case .cli:
                                selectedCLI = instance
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
    }
}

private struct InstanceCard: View {
    let instance: CodexInstance
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: instance.type.symbolName)
                    .font(.system(size: 23, weight: .medium))
                    .foregroundStyle(instance.type == .desktop ? Color.accentColor : Color.secondary)
                    .frame(width: 42, height: 42)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 11))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(instance.displayName)
                            .font(.headline)
                        if instance.isSystem {
                            Text("系统")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                    Text(instance.type.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .padding(16)
            .background(
                hovering ? Color.accentColor.opacity(0.08) : Color(nsColor: .controlBackgroundColor),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.separator.opacity(0.65))
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .accessibilityLabel("\(instance.displayName)，\(instance.type.title)")
    }
}

private struct EmptyEnvironmentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ContentUnavailableView {
            Label("需要 Codex 运行环境", systemImage: "exclamationmark.triangle")
        } description: {
            Text("安装 ChatGPT Desktop 或 Codex CLI 后重新检测。")
        } actions: {
            HStack {
                Link("OpenAI 官方下载", destination: URL(string: "https://learn.chatgpt.com/docs/app")!)
                Button("重新检测") {
                    Task { await model.refreshEnvironment() }
                }
            }
        }
    }
}
