import SwiftUI

struct CreateInstanceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: AppModel
    @State private var selectedType: CodexInstanceType?
    @State private var name = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("创建 Codex")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("选择类型")
                        .font(.headline)

                    HStack(spacing: 12) {
                        ForEach(CodexInstanceType.allCases) { type in
                            TypeChoice(
                                type: type,
                                selected: selectedType == type,
                                enabled: type == .desktop
                                    ? model.environment.desktop.found : model.environment.cli.found
                            ) {
                                selectedType = type
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("名称")
                            .font(.headline)
                        TextField("例如：Work", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .disabled(selectedType == nil)
                            .onSubmit { create() }
                        Text(
                            selectedType == nil
                                ? "先选择 Desktop 或 CLI。"
                                : "显示名称可以重复，底层 Profile ID 始终唯一。"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            HStack {
                Spacer()
                Button("创建") { create() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(
                        selectedType == nil || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || model.isWorking)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(minWidth: 580, idealWidth: 620, minHeight: 470, idealHeight: 520)
    }

    private func create() {
        guard let selectedType else { return }
        Task {
            if await model.createInstance(name: name, type: selectedType) {
                dismiss()
            }
        }
    }
}

private struct TypeChoice: View {
    let type: CodexInstanceType
    let selected: Bool
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: type.symbolName)
                    .font(.system(size: 26, weight: .medium))
                Spacer()
                Text(type.title)
                    .font(.headline)
                Text(enabled ? type.subtitle : "当前环境不可用")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(selected ? Color.accentColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        selected ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: selected ? 2 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.55)
        .frame(minHeight: 145)
    }
}
