import SwiftUI

private enum AgentMode: String, CaseIterable, Identifiable {
    case local
    case sandbox

    var id: String { rawValue }

    var title: String {
        switch self {
        case .local: return "本地模式"
        case .sandbox: return "沙盒模式"
        }
    }

    var subtitle: String {
        switch self {
        case .local: return "本地工具 · 云端模型"
        case .sandbox: return "隔离环境 · 云端模型"
        }
    }

    var icon: String {
        switch self {
        case .local: return "ipad.and.iphone"
        case .sandbox: return "shippingbox.fill"
        }
    }

    var tint: Color {
        switch self {
        case .local: return Color(red: 0.22, green: 0.46, blue: 0.96)
        case .sandbox: return Color(red: 0.55, green: 0.32, blue: 0.88)
        }
    }

    var detail: String {
        switch self {
        case .local: return "使用已授权的本地文件和设备能力，不启动远程执行环境。"
        case .sandbox: return "在隔离的云端环境运行代码、网页和长任务。"
        }
    }
}

private struct Conversation: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

private struct AgentMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
}

struct ContentView: View {
    @State private var selectedConversation: Int? = 1
    @State private var selectedMode: AgentMode = .local
    @State private var prompt = ""
    @State private var messages: [AgentMessage] = [
        AgentMessage(isUser: false, text: "你好，我是 Agent。告诉我你想完成什么，我会先拆解任务，再按当前模式执行。"),
        AgentMessage(isUser: true, text: "帮我整理一份 iPad Agent 的产品方案，并标出本地模式和沙盒模式的区别。"),
        AgentMessage(isUser: false, text: "好的。我会整理产品目标、核心流程和两种执行环境的边界。当前使用本地模式，模型仍运行在云端。")
    ]
    @State private var isRunning = true
    @State private var showPermissions = false
    @State private var showNewTask = false

    private let conversations = [
        Conversation(id: 1, title: "iPad Agent 产品方案", subtitle: "正在运行 · 2 分钟前", icon: "sparkles", color: .blue),
        Conversation(id: 2, title: "竞品功能调研", subtitle: "昨天", icon: "chart.bar.xaxis", color: .orange),
        Conversation(id: 3, title: "SwiftUI 原型设计", subtitle: "周二", icon: "rectangle.3.group", color: .purple)
    ]

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            workspace
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showPermissions) {
            PermissionSheet(mode: selectedMode)
                .presentationDetents([.medium])
        }
    }

    private var sidebar: some View {
        List(selection: $selectedConversation) {
            Section {
                Button {
                    showNewTask = true
                    selectedConversation = nil
                    messages = []
                    prompt = ""
                    isRunning = false
                } label: {
                    Label("新建任务", systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor)
                        .padding(.vertical, 4)
                )
            }

            Section("最近任务") {
                ForEach(conversations) { conversation in
                    ConversationRow(conversation: conversation)
                        .tag(conversation.id)
                }
            }

            Section("工作区") {
                Label("全部项目", systemImage: "square.grid.2x2")
                Label("已保存产物", systemImage: "folder")
                Label("自动化任务", systemImage: "clock.arrow.circlepath")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Agent")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { } label: {
                    Image(systemName: "person.crop.circle")
                }
                .accessibilityLabel("账户")
            }
        }
        .alert("已创建新任务", isPresented: $showNewTask) {
            Button("开始") { }
        } message: {
            Text("选择执行模式后，在下方输入任务。")
        }
    }

    private var workspace: some View {
        VStack(spacing: 0) {
            workspaceHeader
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if messages.isEmpty {
                        welcomeCard
                    } else {
                        conversationView
                    }

                    if isRunning {
                        taskProgressCard
                    }

                    modePicker
                    composer
                }
                .frame(maxWidth: 960)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showPermissions = true } label: {
                    Label("权限", systemImage: "lock.shield")
                }
            }
        }
    }

    private var workspaceHeader: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(conversations.first(where: { $0.id == (selectedConversation ?? -1) })?.title ?? "新任务")
                    .font(.title3.weight(.semibold))
                HStack(spacing: 7) {
                    Circle()
                        .fill(isRunning ? Color.green : Color.secondary)
                        .frame(width: 7, height: 7)
                    Text(isRunning ? "Agent 正在工作" : "等待你的任务")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: selectedMode.icon)
                    .foregroundStyle(selectedMode.tint)
                Text(selectedMode.title)
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(.bar)
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 13))

                VStack(alignment: .leading, spacing: 4) {
                    Text("今天要完成什么？")
                        .font(.title2.weight(.bold))
                    Text("Agent 会先制定计划，再按选定的执行环境完成任务。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                SuggestionChip(title: "分析一份 PDF", icon: "doc.text") { prompt = "分析这份 PDF，并提取关键结论" }
                SuggestionChip(title: "研究一个主题", icon: "magnifyingglass") { prompt = "研究一个主题并整理带引用的报告" }
                SuggestionChip(title: "运行代码", icon: "terminal") {
                    selectedMode = .sandbox
                    prompt = "运行这段代码并解释输出结果"
                }
            }
        }
        .padding(24)
        .background(
            LinearGradient(colors: [Color.blue.opacity(0.10), Color.purple.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.12), lineWidth: 1)
        }
    }

    private var conversationView: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(messages) { message in
                MessageBubble(message: message)
            }
        }
    }

    private var taskProgressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("正在执行任务", systemImage: "arrow.triangle.2.circlepath")
                    .font(.headline)
                Spacer()
                Text(selectedMode.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(selectedMode.tint)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(selectedMode.tint.opacity(0.12))
                    .clipShape(Capsule())
            }

            ProgressView(value: 0.62)
                .tint(selectedMode.tint)

            HStack {
                Label("分析任务要求", systemImage: "checkmark.circle.fill")
                Spacer()
                Label("整理输出结构", systemImage: "circle")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("执行环境")
                    .font(.headline)
                Spacer()
                Button { showPermissions = true } label: {
                    Label("查看权限", systemImage: "lock.shield")
                        .font(.subheadline)
                }
            }

            HStack(spacing: 12) {
                ForEach(AgentMode.allCases) { mode in
                    ModeCard(mode: mode, isSelected: selectedMode == mode) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMode = mode
                        }
                    }
                }
            }
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .bottom, spacing: 12) {
                Button { } label: {
                    Image(systemName: "paperclip")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                }

                TextEditor(text: $prompt)
                    .frame(minHeight: 42, maxHeight: 110)
                    .scrollContentBackground(.hidden)
                    .font(.body)
                    .overlay(alignment: .topLeading) {
                        if prompt.isEmpty {
                            Text("描述你想完成的任务…")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }

                Button(action: sendPrompt) {
                    Image(systemName: prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "arrow.up" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary : selectedMode.tint)
                }
                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }

            HStack(spacing: 8) {
                Image(systemName: "cloud.fill")
                Text("云端模型")
                Text("·")
                Text(selectedMode == .local ? "仅使用已授权的本地工具" : "隔离云端环境")
                Spacer()
                Text("⌘ ↵ 发送")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
        }
    }

    private func sendPrompt() {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(AgentMessage(isUser: true, text: trimmed))
        messages.append(AgentMessage(isUser: false, text: "已收到。我会使用\(selectedMode.title)执行这项任务，并在需要访问文件或外部服务时请求权限。"))
        prompt = ""
        isRunning = true
    }
}

private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: conversation.icon)
                .foregroundStyle(conversation.color)
                .frame(width: 27, height: 27)
                .background(conversation.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(conversation.title)
                    .lineLimit(1)
                Text(conversation.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MessageBubble: View {
    let message: AgentMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !message.isUser {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.blue.gradient)
                    .clipShape(Circle())
            }

            Text(message.text)
                .font(.body)
                .foregroundStyle(message.isUser ? .white : .primary)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(message.isUser ? Color.accentColor : Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 15))

            if message.isUser { Spacer(minLength: 70) }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
}

private struct ModeCard: View {
    let mode: AgentMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: mode.icon)
                        .font(.title3)
                        .foregroundStyle(isSelected ? mode.tint : .secondary)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? mode.tint : Color.secondary.opacity(0.45))
                }
                Text(mode.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(mode.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(mode.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(15)
            .background(isSelected ? mode.tint.opacity(0.10) : Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? mode.tint.opacity(0.65) : Color.clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SuggestionChip: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(.thinMaterial)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct PermissionSheet: View {
    let mode: AgentMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("模型") {
                    PermissionRow(icon: "cloud.fill", title: "云端模型", detail: "所有模式均使用云端模型")
                }

                Section("当前模式 · \(mode.title)") {
                    if mode == .local {
                        PermissionRow(icon: "folder", title: "本地文件", detail: "仅访问你明确授权的文件")
                        PermissionRow(icon: "network.slash", title: "网络工具", detail: "默认关闭远程执行")
                    } else {
                        PermissionRow(icon: "shippingbox.fill", title: "云端沙盒", detail: "隔离环境，任务结束后清理")
                        PermissionRow(icon: "globe", title: "网络访问", detail: "按任务授予临时权限")
                    }
                }
            }
            .navigationTitle("权限与数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

private struct PermissionRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}

#Preview {
    ContentView()
}
