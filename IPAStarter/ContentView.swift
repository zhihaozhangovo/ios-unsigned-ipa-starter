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
        case .local: return "调用云端模型，使用已授权的 iPad 文件与设备能力。"
        case .sandbox: return "调用云端模型，在隔离环境运行代码、网页和长任务。"
        }
    }
}

private enum FeatureDestination: String, CaseIterable, Identifiable {
    case providers
    case modelGroups
    case tokenUsage
    case appearance
    case tools
    case subagents
    case skills
    case soul
    case memory
    case mcp
    case environment
    case storage
    case sharedFolders
    case mounts
    case sync
    case backup
    case permissions
    case touchID
    case logs
    case about
    case privacy
    case feedback
    case webResearch
    case codeExecution
    case connectors
    case automation
    case multiAgent
    case artifacts
    case systemPrompt

    var id: String { rawValue }

    var title: String {
        switch self {
        case .providers: return "管理 AI 服务商"
        case .modelGroups: return "模型分组"
        case .tokenUsage: return "Token 用量"
        case .appearance: return "外观"
        case .tools: return "可用工具"
        case .subagents: return "子代理任务"
        case .skills: return "技能与工作流"
        case .soul: return "灵魂与行为"
        case .memory: return "记忆"
        case .mcp: return "MCP 集成"
        case .environment: return "环境变量与密钥"
        case .storage: return "存储与产物"
        case .sharedFolders: return "共享文件夹"
        case .mounts: return "挂载外部文件夹"
        case .sync: return "iCloud 同步"
        case .backup: return "备份与恢复"
        case .permissions: return "权限"
        case .touchID: return "Touch ID 保护"
        case .logs: return "日志与诊断"
        case .about: return "关于 iPad Agent"
        case .privacy: return "隐私政策"
        case .feedback: return "反馈问题"
        case .webResearch: return "网页研究"
        case .codeExecution: return "代码执行"
        case .connectors: return "连接器"
        case .automation: return "自动化与定时任务"
        case .multiAgent: return "多 Agent 协作"
        case .artifacts: return "文件与产物"
        case .systemPrompt: return "系统提示词"
        }
    }

    var icon: String {
        switch self {
        case .providers: return "key.fill"
        case .modelGroups: return "gearshape.2.fill"
        case .tokenUsage: return "chart.line.uptrend.xyaxis"
        case .appearance: return "paintbrush.fill"
        case .tools: return "wrench.and.screwdriver.fill"
        case .subagents: return "person.2.fill"
        case .skills: return "wand.and.stars"
        case .soul: return "sparkles"
        case .memory: return "brain.head.profile"
        case .mcp: return "point.3.connected.trianglepath.dotted"
        case .environment: return "terminal.fill"
        case .storage: return "internaldrive.fill"
        case .sharedFolders: return "folder.badge.person.crop"
        case .mounts: return "externaldrive.connected.to.line.below"
        case .sync: return "icloud.fill"
        case .backup: return "arrow.clockwise.icloud.fill"
        case .permissions: return "lock.shield.fill"
        case .touchID: return "touchid"
        case .logs: return "doc.text.magnifyingglass"
        case .about: return "info.circle.fill"
        case .privacy: return "hand.raised.fill"
        case .feedback: return "bubble.left.and.bubble.right.fill"
        case .webResearch: return "globe"
        case .codeExecution: return "terminal"
        case .connectors: return "square.grid.2x2.fill"
        case .automation: return "clock.arrow.circlepath"
        case .multiAgent: return "person.3.fill"
        case .artifacts: return "shippingbox.fill"
        case .systemPrompt: return "text.badge.star"
        }
    }

    var tint: Color {
        switch self {
        case .providers, .tokenUsage: return .blue
        case .modelGroups, .appearance: return .indigo
        case .tools, .codeExecution: return .orange
        case .subagents, .multiAgent: return .purple
        case .skills, .soul, .systemPrompt: return .pink
        case .memory: return .mint
        case .mcp, .connectors: return .cyan
        case .environment, .logs: return .green
        case .storage, .sharedFolders, .mounts, .sync, .backup: return .teal
        case .permissions, .touchID: return .red
        case .about, .privacy, .feedback: return .gray
        case .webResearch: return .blue
        case .automation: return .purple
        case .artifacts: return .orange
        }
    }

    var detail: String {
        switch self {
        case .providers: return "管理 OpenAI、Anthropic、Google、Sub2API、NewAPI 等云端服务商，支持 API Key、OAuth 和连接测试。"
        case .modelGroups: return "创建模型分组，设置默认模型、备用模型、上下文长度和路由规则。"
        case .tokenUsage: return "查看请求次数、Token、成本、余额和每日用量上限。"
        case .appearance: return "自定义主题、字体、气泡、侧栏宽度和工作区布局。"
        case .tools: return "启用网页、浏览器、文件、代码沙盒、终端、OCR、截图和通知工具。"
        case .subagents: return "配置研究、编码、审校等子代理，并设置并发数和交接规则。"
        case .skills: return "管理可复用技能、提示词模板、工作流和技能市场。"
        case .soul: return "自定义 Agent 名称、角色、语气、边界和长期行为规则。"
        case .memory: return "查看、编辑、删除长期记忆、项目记忆和用户偏好。"
        case .mcp: return "连接 MCP 服务器，管理工具清单、状态、权限和调用记录。"
        case .environment: return "安全保存环境变量、密钥和沙盒运行时配置。"
        case .storage: return "管理对话、任务、缓存、生成文件和版本历史。"
        case .sharedFolders: return "选择可被本地模式访问的共享目录。"
        case .mounts: return "挂载外部文件夹或远程工作区。"
        case .sync: return "跨设备同步会话、设置、记忆和产物。"
        case .backup: return "导出、导入和恢复完整工作区。"
        case .permissions: return "按任务授予文件、网络、摄像头、麦克风和外部服务权限。"
        case .touchID: return "使用 Face ID 或 Touch ID 保护密钥、会话和敏感内容。"
        case .logs: return "查看调用链、工具执行、错误、耗时和导出诊断包。"
        case .about: return "查看版本、构建信息、开源许可和服务状态。"
        case .privacy: return "查看数据传输、保存、删除和云端处理规则。"
        case .feedback: return "提交问题、功能建议和诊断信息。"
        case .webResearch: return "多来源搜索、浏览、引用核验和研究报告。"
        case .codeExecution: return "在云端沙盒运行代码、安装依赖和生成文件。"
        case .connectors: return "连接 GitHub、邮件、日历、云盘、Notion、Slack 等服务。"
        case .automation: return "创建事件触发、定时执行和结果通知。"
        case .multiAgent: return "让多个 Agent 并行研究、写作、编码和审校。"
        case .artifacts: return "管理文档、表格、图片、代码、演示文稿和版本。"
        case .systemPrompt: return "自定义系统提示词，并让 AI 根据目标自动生成和优化。"
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
    @State private var selectedConversation: Int?
    @State private var selectedMode: AgentMode = .local
    @State private var prompt = ""
    @State private var messages: [AgentMessage] = []
    @State private var isRunning = false
    @State private var showPermissions = false
    @State private var showSettings = false
    @State private var activeFeature: FeatureDestination?
    @State private var setupStep = 1
    @State private var customSystemPrompt = ""
    @AppStorage("iPadAgent.onboardingComplete") private var onboardingComplete = false
    @State private var showOnboarding = false

    private let conversations = [
        Conversation(id: 1, title: "iPad Agent 产品方案", subtitle: "2 分钟前", icon: "sparkles", color: .blue),
        Conversation(id: 2, title: "竞品功能调研", subtitle: "昨天", icon: "chart.bar.xaxis", color: .orange),
        Conversation(id: 3, title: "SwiftUI 原型设计", subtitle: "周二", icon: "rectangle.3.group", color: .purple)
    ]

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 300, ideal: 340, max: 380)
        } detail: {
            if selectedConversation == nil {
                emptyWorkspace
            } else {
                workspace
            }
        }
        .navigationSplitViewStyle(.balanced)
        .preferredColorScheme(.dark)
        .onAppear {
            showOnboarding = !onboardingComplete
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                onboardingComplete = true
                setupStep = 1
                showOnboarding = false
            }
        }
        .sheet(isPresented: $showPermissions) {
            PermissionSheet(mode: selectedMode)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showSettings) {
            SettingsView { feature in
                showSettings = false
                DispatchQueue.main.async {
                    activeFeature = feature
                }
            }
            .presentationDetents([.large])
        }
        .sheet(item: $activeFeature) { feature in
            FeatureDetailSheet(feature: feature, systemPrompt: $customSystemPrompt) {
                if feature == .providers { setupStep = max(setupStep, 2) }
                if feature == .modelGroups { setupStep = max(setupStep, 3) }
            }
            .presentationDetents([.large])
        }
    }

    private var sidebar: some View {
        List(selection: $selectedConversation) {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Agent")
                                .font(.title2.weight(.bold))
                            Text("云端智能工作台")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("开始使用")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    OnboardingStepRow(number: 1, title: "配置云端 AI 服务商", detail: "API Key / OAuth / 连接测试", isCurrent: setupStep == 1) {
                        activeFeature = .providers
                    }
                    OnboardingStepRow(number: 2, title: "选择模型和默认模式", detail: "模型分组 · 本地模式 / 沙盒模式", isCurrent: setupStep == 2) {
                        activeFeature = .modelGroups
                    }
                    OnboardingStepRow(number: 3, title: "开始第一个对话", detail: "从示例任务开始使用 Agent", isCurrent: setupStep == 3) {
                        beginConversation()
                    }
                }
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 8, leading: 14, bottom: 10, trailing: 14))
                .listRowBackground(Color.clear)
            }

            Section {
                Button {
                    newTask()
                } label: {
                    Label("新建任务", systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 5)
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
                        .onTapGesture {
                            selectConversation(conversation.id)
                        }
                }
            }

            Section("能力中心") {
                CapabilityRow(title: "网页研究", icon: "globe", color: .blue) { activeFeature = .webResearch }
                CapabilityRow(title: "代码执行", icon: "terminal", color: .orange) {
                    selectedMode = .sandbox
                    activeFeature = .codeExecution
                }
                CapabilityRow(title: "多 Agent 协作", icon: "person.3.fill", color: .purple) { activeFeature = .multiAgent }
                CapabilityRow(title: "自动化与定时", icon: "clock.arrow.circlepath", color: .pink) { activeFeature = .automation }
                CapabilityRow(title: "文件与产物", icon: "shippingbox.fill", color: .teal) { activeFeature = .artifacts }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("设置")
            }
        }
    }

    private var emptyWorkspace: some View {
        VStack(spacing: 18) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)
            Text("未选择对话")
                .font(.title2.weight(.semibold))
            Text("选择一个对话，或从左侧开始新任务")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                beginConversation()
            } label: {
                Label("开始新对话", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
    }

    private var workspace: some View {
        VStack(spacing: 0) {
            workspaceHeader
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    conversationView
                    if isRunning { taskProgressCard }
                    modePicker
                    advancedCapabilities
                    composer
                }
                .frame(maxWidth: 1040)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 34)
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
            Button { activeFeature = .systemPrompt } label: {
                Label("系统提示词", systemImage: "text.badge.star")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
            ModePill(mode: selectedMode) {
                showPermissions = true
            }
        }
        .padding(.horizontal, 34)
        .padding(.vertical, 16)
        .background(.bar)
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
            ProgressView(value: 0.62).tint(selectedMode.tint)
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
                Text("执行环境").font(.headline)
                Spacer()
                Button { showPermissions = true } label: {
                    Label("查看权限", systemImage: "lock.shield")
                        .font(.subheadline)
                }
            }
            HStack(spacing: 12) {
                ForEach(AgentMode.allCases) { mode in
                    ModeCard(mode: mode, isSelected: selectedMode == mode) {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedMode = mode }
                    }
                }
            }
        }
    }

    private var advancedCapabilities: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Agent 能力").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                CapabilityCard(title: "网页研究", subtitle: "搜索 · 浏览 · 引用", icon: "globe", color: .blue) { activeFeature = .webResearch }
                CapabilityCard(title: "代码执行", subtitle: "云端沙盒 · 依赖", icon: "terminal", color: .orange) {
                    selectedMode = .sandbox
                    activeFeature = .codeExecution
                }
                CapabilityCard(title: "连接器", subtitle: "GitHub · 云盘 · 日历", icon: "square.grid.2x2.fill", color: .cyan) { activeFeature = .connectors }
                CapabilityCard(title: "多 Agent", subtitle: "并行研究 · 审校", icon: "person.3.fill", color: .purple) { activeFeature = .multiAgent }
                CapabilityCard(title: "自动化", subtitle: "定时 · 事件触发", icon: "clock.arrow.circlepath", color: .pink) { activeFeature = .automation }
                CapabilityCard(title: "文件产物", subtitle: "文档 · 表格 · 导出", icon: "shippingbox.fill", color: .teal) { activeFeature = .artifacts }
            }
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .bottom, spacing: 12) {
                Button { activeFeature = .artifacts } label: {
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
            .overlay { RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.08), lineWidth: 1) }

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

    private func newTask() {
        selectedConversation = nil
        messages = []
        prompt = ""
        isRunning = false
        setupStep = max(setupStep, 3)
    }

    private func beginConversation() {
        selectedConversation = 1
        messages = [
            AgentMessage(isUser: false, text: "你好，我是 Agent。告诉我你想完成什么，我会先拆解任务，再按当前模式执行。"),
            AgentMessage(isUser: false, text: "你可以让我研究网页、分析文件、运行代码、连接外部服务，或编排多个 Agent 协作。")
        ]
        prompt = ""
        isRunning = false
        setupStep = 3
    }

    private func selectConversation(_ id: Int) {
        selectedConversation = id
        messages = [
            AgentMessage(isUser: false, text: "已打开「\(conversations.first(where: { $0.id == id })?.title ?? "任务")」。你可以继续执行、切换模式或查看产物。")
        ]
        isRunning = false
    }

    private func sendPrompt() {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if selectedConversation == nil { beginConversation() }
        messages.append(AgentMessage(isUser: true, text: trimmed))
        messages.append(AgentMessage(isUser: false, text: "已收到。我会使用\(selectedMode.title)执行这项任务，并在需要访问文件或外部服务时请求权限。"))
        prompt = ""
        isRunning = true
    }
}

private struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            VStack(spacing: 22) {
                HStack {
                    Label("iPad Agent", systemImage: "sparkles")
                        .font(.headline)
                    Spacer()
                    Button("跳过") { onFinish() }
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)

                TabView(selection: $page) {
                    OnboardingPage(
                        icon: "sparkles",
                        color: .blue,
                        title: "欢迎使用 iPad Agent",
                        subtitle: "一个可配置、可审计、可扩展的云端 Agent 工作台。",
                        features: ["所有模式均使用云端模型", "本地工具与云端沙盒可按任务切换", "执行高风险操作前会请求确认"]
                    ).tag(0)
                    OnboardingPage(
                        icon: "key.fill",
                        color: .orange,
                        title: "先连接你的 AI 服务",
                        subtitle: "支持 OpenAI 兼容接口、Sub2API、NewAPI 以及 OAuth 服务商。",
                        features: ["API Key 与 OAuth 安全保存", "连接测试、余额查询和 Token 用量", "主模型、备用模型和智能路由"]
                    ).tag(1)
                    OnboardingPage(
                        icon: "wand.and.stars",
                        color: .purple,
                        title: "把 Agent 配成你的工作方式",
                        subtitle: "自定义灵魂、系统提示词、工具、技能、记忆和自动化。",
                        features: ["AI 辅助填写系统提示词", "网页研究、代码执行、MCP 与子代理", "文件产物、同步、备份和日志"]
                    ).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                HStack(spacing: 14) {
                    if page > 0 {
                        Button("上一步") { withAnimation { page -= 1 } }
                            .buttonStyle(.bordered)
                    }
                    Spacer()
                    Button(page == 2 ? "开始使用" : "继续") {
                        if page == 2 {
                            onFinish()
                        } else {
                            withAnimation { page += 1 }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 26)
            }
        }
    }
}

private struct OnboardingPage: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let features: [String]

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 52, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 112, height: 112)
                .background(LinearGradient(colors: [color, color.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: 30))
            VStack(spacing: 10) {
                Text(title).font(.largeTitle.weight(.bold)).multilineTextAlignment(.center)
                Text(subtitle).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: 13) {
                ForEach(features, id: \.self) { feature in
                    Label(feature, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: 520, alignment: .leading)
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}

private struct OnboardingStepRow: View {
    let number: Int
    let title: String
    let detail: String
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(String(number))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(isCurrent ? Color.accentColor : Color.secondary.opacity(0.55))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
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
                Text(conversation.title).lineLimit(1)
                Text(conversation.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CapabilityRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}

private struct CapabilityCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }
}

private struct ModePill: View {
    let mode: AgentMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: mode.icon).foregroundStyle(mode.tint)
                Text(mode.title).font(.subheadline.weight(.medium))
                Image(systemName: "chevron.down").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct MessageBubble: View {
    let message: AgentMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser { Spacer(minLength: 70) }
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
            if !message.isUser { Spacer(minLength: 70) }
        }
        .frame(maxWidth: .infinity)
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
                    Image(systemName: mode.icon).font(.title3).foregroundStyle(isSelected ? mode.tint : .secondary)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? mode.tint : Color.secondary.opacity(0.45))
                }
                Text(mode.title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text(mode.subtitle).font(.caption).foregroundStyle(.secondary)
                Text(mode.detail).font(.caption2).foregroundStyle(.secondary).lineLimit(2).multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(15)
            .background(isSelected ? mode.tint.opacity(0.10) : Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay { RoundedRectangle(cornerRadius: 15).stroke(isSelected ? mode.tint.opacity(0.65) : Color.clear, lineWidth: 1.5) }
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsView: View {
    let onFeature: (FeatureDestination) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("AI 服务商") {
                    SettingsRow(feature: .providers, subtitle: "OpenAI · Anthropic · Google · Sub2API · NewAPI", action: onFeature)
                    SettingsRow(feature: .modelGroups, subtitle: "默认模型 · 备用模型 · 路由", action: onFeature)
                    SettingsRow(feature: .tokenUsage, subtitle: "Token · 成本 · 余额 · 限额", action: onFeature)
                }
                Section("外观与交互") {
                    SettingsRow(feature: .appearance, subtitle: "主题 · 字体 · 布局 · 侧栏", action: onFeature)
                    SettingsRow(feature: .systemPrompt, subtitle: "自定义内容 · AI 辅助生成", action: onFeature)
                }
                Section("Agent 运行时") {
                    SettingsRow(feature: .tools, subtitle: "网页 · 浏览器 · 文件 · OCR · 代码", action: onFeature)
                    SettingsRow(feature: .subagents, subtitle: "并行度 · 角色 · 交接规则", action: onFeature)
                    SettingsRow(feature: .skills, subtitle: "技能 · 模板 · 工作流", action: onFeature)
                    SettingsRow(feature: .soul, subtitle: "名称 · 角色 · 语气 · 边界", action: onFeature)
                    SettingsRow(feature: .memory, subtitle: "长期记忆 · 项目记忆 · 偏好", action: onFeature)
                    SettingsRow(feature: .mcp, subtitle: "服务器 · 工具 · 权限 · 状态", action: onFeature)
                    SettingsRow(feature: .environment, subtitle: "变量 · 密钥 · 运行时配置", action: onFeature)
                }
                Section("存储与同步") {
                    SettingsRow(feature: .storage, subtitle: "对话 · 缓存 · 产物 · 版本", action: onFeature)
                    SettingsRow(feature: .sharedFolders, action: onFeature)
                    SettingsRow(feature: .mounts, action: onFeature)
                    SettingsRow(feature: .sync, subtitle: "跨设备同步工作区", action: onFeature)
                    SettingsRow(feature: .backup, subtitle: "导出 · 导入 · 恢复", action: onFeature)
                }
                Section("安全与诊断") {
                    SettingsRow(feature: .permissions, subtitle: "按任务临时授权", action: onFeature)
                    SettingsRow(feature: .touchID, subtitle: "保护密钥和敏感内容", action: onFeature)
                    SettingsRow(feature: .logs, subtitle: "调用链 · 错误 · 耗时", action: onFeature)
                }
                Section("关于") {
                    SettingsRow(feature: .about, action: onFeature)
                    SettingsRow(feature: .privacy, action: onFeature)
                    SettingsRow(feature: .feedback, action: onFeature)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

private struct SettingsRow: View {
    let feature: FeatureDestination
    var subtitle: String? = nil
    let action: (FeatureDestination) -> Void

    var body: some View {
        Button { action(feature) } label: {
            HStack(spacing: 12) {
                Image(systemName: feature.icon)
                    .foregroundStyle(feature.tint)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(feature.title).foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
    }
}

private struct FeatureDetailSheet: View {
    let feature: FeatureDestination
    @Binding var systemPrompt: String
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var providerName = "OpenAI Compatible"
    @State private var endpoint = "https://api.example.com/v1"
    @State private var isEnabled = true
    @State private var checkResult = "尚未检测"
    @State private var customText = ""
    @State private var showPromptAssistant = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: feature.icon)
                            .font(.title2)
                            .foregroundStyle(feature.tint)
                            .frame(width: 44, height: 44)
                            .background(feature.tint.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(feature.title).font(.headline)
                            Text(feature.detail).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                if feature == .providers {
                    providerSection
                } else if feature == .modelGroups {
                    modelSection
                } else if feature == .tokenUsage {
                    balanceSection
                } else if feature == .systemPrompt || feature == .soul || feature == .skills {
                    promptSection
                } else {
                    genericSection
                }

                Section {
                    Button {
                        if feature == .systemPrompt || feature == .soul || feature == .skills {
                            systemPrompt = customText
                        }
                        onComplete()
                        dismiss()
                    } label: {
                        Text("保存并完成")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .onAppear { customText = systemPrompt }
            .sheet(isPresented: $showPromptAssistant) {
                PromptAssistantSheet(prompt: $customText)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var providerSection: some View {
        Group {
            Section("服务商") {
                TextField("服务商名称", text: $providerName)
                TextField("API Endpoint", text: $endpoint)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                SecureField("API Key / OAuth Token", text: .constant(""))
                Button("测试连接") { checkResult = "连接成功 · 200 OK" }
                Label(checkResult, systemImage: checkResult.contains("成功") ? "checkmark.circle.fill" : "circle.dotted")
                    .foregroundStyle(checkResult.contains("成功") ? .green : .secondary)
            }
            Section("兼容服务") {
                ProviderBalanceRow(name: "Sub2API", balance: "$ 128.40", status: "已连接", color: .blue)
                ProviderBalanceRow(name: "NewAPI", balance: "¥ 86.20", status: "已连接", color: .purple)
                Button {
                    checkResult = "余额已刷新 · 刚刚"
                } label: {
                    Label("刷新 Sub2API / NewAPI 余额", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    private var modelSection: some View {
        Group {
            Section("默认模型") {
                Picker("主模型", selection: .constant("智能路由")) {
                    Text("智能路由").tag("智能路由")
                    Text("GPT-5").tag("GPT-5")
                    Text("Claude").tag("Claude")
                    Text("Gemini").tag("Gemini")
                }
                Picker("备用模型", selection: .constant("自动切换")) {
                    Text("自动切换").tag("自动切换")
                    Text("关闭").tag("关闭")
                }
                Toggle("启用模型故障降级", isOn: $isEnabled)
                Toggle("按成本自动路由", isOn: .constant(true))
            }
            Section("默认执行模式") {
                Label("本地模式：iPad 本地工具 + 云端模型", systemImage: "ipad.and.iphone")
                Label("沙盒模式：远程隔离工具 + 云端模型", systemImage: "shippingbox.fill")
            }
        }
    }

    private var balanceSection: some View {
        Group {
            Section("用量概览") {
                UsageMetric(title: "本月 Token", value: "1.28M", detail: "较上月 +12%")
                UsageMetric(title: "本月成本", value: "$ 8.42", detail: "预算 $ 30.00")
                UsageMetric(title: "请求次数", value: "428", detail: "成功率 99.1%")
            }
            Section("余额查询") {
                ProviderBalanceRow(name: "Sub2API", balance: "$ 128.40", status: "刚刚更新", color: .blue)
                ProviderBalanceRow(name: "NewAPI", balance: "¥ 86.20", status: "刚刚更新", color: .purple)
                Button("立即查询余额") { }
            }
        }
    }

    private var promptSection: some View {
        Group {
            Section("自定义内容") {
                TextEditor(text: $customText)
                    .frame(minHeight: 180)
                    .overlay(alignment: .topLeading) {
                        if customText.isEmpty {
                            Text("写下 Agent 的角色、语气、目标、边界和工作习惯…")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }
                Button {
                    showPromptAssistant = true
                } label: {
                    Label("让 AI 辅助填写", systemImage: "sparkles")
                }
            }
            Section("应用范围") {
                Toggle("应用到所有新对话", isOn: $isEnabled)
                Toggle("允许项目覆盖", isOn: .constant(true))
                Toggle("保留版本历史", isOn: .constant(true))
            }
        }
    }

    private var genericSection: some View {
        Group {
            Section("开关") {
                Toggle("启用此功能", isOn: $isEnabled)
            }
            Section("快捷入口") {
                Label("支持云端模型和临时权限", systemImage: "cloud.fill")
                Label("操作会写入日志，可随时撤销", systemImage: "checkmark.shield")
            }
        }
    }
}

private struct ProviderBalanceRow: View {
    let name: String
    let balance: String
    let status: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: "creditcard.fill").foregroundStyle(color).frame(width: 26)
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                Text(status).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(balance).font(.subheadline.weight(.semibold))
        }
    }
}

private struct UsageMetric: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.title3.weight(.semibold))
            }
            Spacer()
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct PromptAssistantSheet: View {
    @Binding var prompt: String
    @Environment(\.dismiss) private var dismiss
    @State private var goal = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("告诉 AI 你希望 Agent 成为什么样的助手，AI 会生成可编辑的系统提示词。")
                    .foregroundStyle(.secondary)
                TextField("例如：帮我管理科研项目，回答要有引用…", text: $goal, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Button {
                    prompt = "你是一个专注于\(goal.isEmpty ? "高质量任务执行" : goal)的 Agent。请先确认目标和约束，给出清晰计划；执行外部操作前请求确认；对事实提供来源；输出结构化、简洁、可执行的结果。"
                } label: {
                    Label("生成系统提示词", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                if !prompt.isEmpty {
                    TextEditor(text: $prompt)
                        .frame(minHeight: 180)
                        .padding(8)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Spacer()
            }
            .padding(24)
            .navigationTitle("AI 辅助填写")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
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
                        PermissionRow(icon: "network.slash", title: "远程执行", detail: "默认关闭沙盒和远程代码")
                    } else {
                        PermissionRow(icon: "shippingbox.fill", title: "云端沙盒", detail: "隔离环境，任务结束后清理")
                        PermissionRow(icon: "globe", title: "网络访问", detail: "按任务授予临时权限")
                    }
                }
                Section("高风险操作") {
                    PermissionRow(icon: "exclamationmark.shield", title: "发送、删除、购买", detail: "执行前暂停并请求确认")
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
            Image(systemName: icon).foregroundStyle(.blue).frame(width: 26)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}

#Preview {
    ContentView()
}
