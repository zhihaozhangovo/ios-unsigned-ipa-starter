import SwiftUI
import Foundation
import Security
import UniformTypeIdentifiers

private enum RuntimeMode: String, CaseIterable, Identifiable {
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
        case .local: return "Alpine Linux 虚拟环境"
        case .sandbox: return "云端隔离环境"
        }
    }

    var icon: String {
        switch self {
        case .local: return "terminal.fill"
        case .sandbox: return "shippingbox.fill"
        }
    }

    var color: Color {
        switch self {
        case .local: return .blue
        case .sandbox: return .purple
        }
    }
}

private struct ChatMessage: Identifiable, Codable {
    enum Role: String, Codable {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    var text: String

    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}

private struct Conversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var updatedAt: Date

    init(title: String = "新对话", messages: [ChatMessage] = []) {
        self.id = UUID()
        self.title = title
        self.messages = messages
        self.updatedAt = Date()
    }
}

private struct BalanceSnapshot: Codable {
    let remaining: Double
    let used: Double?
    let total: Double?
    let unit: String
    let expiresAt: Date?

    var displayValue: String {
        let normalized = unit.lowercased()
        if normalized.contains("usd") || normalized == "$" {
            return String(format: "$ %.2f", remaining)
        }
        if normalized.contains("cny") || normalized.contains("rmb") || normalized == "¥" {
            return String(format: "¥ %.2f", remaining)
        }
        return String(format: "%.0f %@", remaining, unit)
    }

    var detail: String {
        if let expiresAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            return "刚刚更新 · 到期 \(formatter.string(from: expiresAt))"
        }
        return "刚刚更新"
    }
}

private struct ProviderStatus {
    var models: [String] = []
    var balance: BalanceSnapshot?
    var message = "尚未连接"
    var isLoading = false
}

private enum SecureStore {
    private static let service = "com.example.iPadAgent"
    private static let account = "provider-api-key"

    static func read() -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func save(_ value: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        guard !value.isEmpty, let data = value.data(using: .utf8) else { return }
        let item = query.merging([
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]) { _, new in new }
        _ = SecItemAdd(item as CFDictionary, nil)
    }
}

private enum ClientError: LocalizedError {
    case missingConfiguration
    case invalidEndpoint
    case insecureEndpoint
    case http(Int, String)
    case transport(String)
    case invalidResponse(String)
    case noModels
    case noBalance

    var errorDescription: String? {
        switch self {
        case .missingConfiguration: return "请先填写 API Endpoint 和 API Key"
        case .invalidEndpoint: return "Endpoint 无效"
        case .insecureEndpoint: return "Endpoint 必须使用 HTTPS；仅允许 localhost 使用 HTTP"
        case .http(let code, let body):
            let detail = body.trimmingCharacters(in: .whitespacesAndNewlines)
            return detail.isEmpty ? "服务器返回 HTTP \(code)" : "服务器返回 HTTP \(code)：\(detail.prefix(160))"
        case .transport(let message): return "网络请求失败：\(message)"
        case .invalidResponse(let message): return "服务器响应无法识别：\(message)"
        case .noModels: return "连接成功，但没有读取到模型"
        case .noBalance: return "连接成功，但该服务没有提供余额接口"
        }
    }
}

private enum ProviderClient {
    static func models(endpoint: String, token: String) async throws -> [String] {
        guard !endpoint.isEmpty, !token.isEmpty else { throw ClientError.missingConfiguration }
        var lastError: Error = ClientError.noModels
        for url in try modelURLs(endpoint) {
            do {
                let (data, response) = try await request(url: url, token: token)
                guard let http = response as? HTTPURLResponse else {
                    lastError = ClientError.invalidResponse("缺少 HTTP 状态码")
                    continue
                }
                if http.statusCode == 401 || http.statusCode == 403 {
                    throw ClientError.http(http.statusCode, "认证失败")
                }
                if http.statusCode == 404 {
                    lastError = ClientError.http(404, "模型接口不存在")
                    continue
                }
                guard (200..<300).contains(http.statusCode) else {
                    throw ClientError.http(http.statusCode, responseText(data))
                }
                guard let json = try? JSONSerialization.jsonObject(with: data) else {
                    lastError = ClientError.invalidResponse("返回内容不是合法 JSON")
                    continue
                }
                let found = modelIDs(json)
                if !found.isEmpty { return Array(Set(found)).sorted() }
                lastError = ClientError.invalidResponse("JSON 中没有模型 ID")
            } catch let error as ClientError {
                if case .http(let code, _) = error, code == 404 {
                    lastError = error
                    continue
                }
                throw error
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = ClientError.transport(error.localizedDescription)
            }
        }
        throw lastError
    }

    static func balance(endpoint: String, token: String) async throws -> BalanceSnapshot {
        guard !endpoint.isEmpty, !token.isEmpty else { throw ClientError.missingConfiguration }
        var lastError: Error = ClientError.noBalance
        for (path, url) in try balanceURLs(endpoint) {
            do {
                let (data, response) = try await request(url: url, token: token)
                guard let http = response as? HTTPURLResponse else {
                    lastError = ClientError.invalidResponse("缺少 HTTP 状态码")
                    continue
                }
                if http.statusCode == 401 || http.statusCode == 403 {
                    throw ClientError.http(http.statusCode, "认证失败")
                }
                if http.statusCode == 404 {
                    lastError = ClientError.http(404, "\(path) 不存在")
                    continue
                }
                guard (200..<300).contains(http.statusCode) else {
                    throw ClientError.http(http.statusCode, responseText(data))
                }
                guard let json = try? JSONSerialization.jsonObject(with: data) else {
                    lastError = ClientError.invalidResponse("返回内容不是合法 JSON")
                    continue
                }
                if path == "/v1/usage", let snapshot = sub2Balance(json) { return snapshot }
                if path == "/api/usage/token", let snapshot = newAPIbalance(json) { return snapshot }
                lastError = ClientError.invalidResponse("JSON 中没有可识别的余额字段")
            } catch let error as ClientError {
                if case .http(let code, _) = error, code == 404 {
                    lastError = error
                    continue
                }
                throw error
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = ClientError.transport(error.localizedDescription)
            }
        }
        throw lastError
    }

    static func stream(endpoint: String, token: String, model: String, history: [[String: String]]) -> AsyncThrowingStream<String, Error> {
        var producer: Task<Void, Never>?
        let stream = AsyncThrowingStream<String, Error> { continuation in
            producer = Task {
                do {
                    guard !endpoint.isEmpty, !token.isEmpty, !model.isEmpty else {
                        throw ClientError.missingConfiguration
                    }
                    var lastError: Error = ClientError.invalidEndpoint
                    for url in try chatURLs(endpoint) {
                        do {
                            if Task.isCancelled { throw CancellationError() }
                            var request = makeRequest(url: url, method: "POST", token: token)
                            request.timeoutInterval = 120
                            request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                            request.httpBody = try JSONSerialization.data(withJSONObject: [
                                "model": model,
                                "messages": history,
                                "stream": true
                            ])

                            let (bytes, response) = try await URLSession.shared.bytes(for: request)
                            guard let http = response as? HTTPURLResponse else { throw ClientError.invalidEndpoint }
                            if http.statusCode == 401 || http.statusCode == 403 {
                                throw ClientError.http(http.statusCode, "认证失败")
                            }
                            if http.statusCode == 404 {
                                throw ClientError.http(404, "聊天接口不存在")
                            }
                            if !(200..<300).contains(http.statusCode) {
                                var body = ""
                                for try await line in bytes.lines { body += line }
                                throw ClientError.http(http.statusCode, body)
                            }

                            for try await line in bytes.lines {
                                guard line.hasPrefix("data:") else { continue }
                                let payload = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                                if payload.isEmpty { continue }
                                if payload == "[DONE]" { break }
                                guard let data = payload.data(using: .utf8),
                                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                                    throw ClientError.invalidResponse("流式响应包含非法 JSON")
                                }
                                if let error = json["error"] as? [String: Any],
                                   let message = error["message"] as? String {
                                    throw ClientError.http(http.statusCode, message)
                                }
                                guard let choice = (json["choices"] as? [[String: Any]])?.first else { continue }
                                if let delta = choice["delta"] as? [String: Any],
                                   let content = delta["content"] as? String {
                                    continuation.yield(content)
                                } else if let text = choice["text"] as? String {
                                    continuation.yield(text)
                                } else if let message = choice["message"] as? [String: Any],
                                          let content = message["content"] as? String {
                                    continuation.yield(content)
                                }
                            }
                            continuation.finish()
                            return
                        } catch is CancellationError {
                            throw CancellationError()
                        } catch {
                            lastError = error
                            if case ClientError.http(let code, _) = error, code != 404 {
                                throw error
                            }
                        }
                    }
                    continuation.finish(throwing: lastError)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in
                producer?.cancel()
            }
        }
        return stream
    }

    private static func baseCandidates(_ endpoint: String) throws -> [String] {
        let trimmed = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let parsed = URL(string: trimmed),
              let scheme = parsed.scheme?.lowercased(),
              let host = parsed.host?.lowercased(),
              !host.isEmpty,
              parsed.user == nil,
              parsed.password == nil,
              parsed.query == nil,
              parsed.fragment == nil else {
            throw ClientError.invalidEndpoint
        }
        let localHosts: Set<String> = ["localhost", "127.0.0.1", "::1"]
        guard scheme == "https" || (scheme == "http" && localHosts.contains(host)) else {
            throw ClientError.insecureEndpoint
        }

        var base = trimmed
        while base.hasSuffix("/") { base.removeLast() }
        guard !base.isEmpty else { throw ClientError.invalidEndpoint }
        var values = [base]
        if base.lowercased().hasSuffix("/v1") {
            values.append(String(base.dropLast(3)))
        }
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    private static func modelURLs(_ endpoint: String) throws -> [URL] {
        var result: [URL] = []
        for base in try baseCandidates(endpoint) {
            let paths = base.lowercased().hasSuffix("/v1")
                ? ["/models", "/api/models"]
                : ["/v1/models", "/models", "/api/models"]
            for path in paths {
                if let url = URL(string: base + path), url.scheme != nil, url.host != nil {
                    result.append(url)
                }
            }
        }
        return unique(result)
    }

    private static func balanceURLs(_ endpoint: String) throws -> [(String, URL)] {
        var result: [(String, URL)] = []
        for base in try baseCandidates(endpoint) {
            let candidates: [(String, String)] = base.lowercased().hasSuffix("/v1")
                ? [("/v1/usage", "/usage"), ("/api/usage/token", "/api/usage/token")]
                : [("/v1/usage", "/v1/usage"), ("/api/usage/token", "/api/usage/token")]
            for (label, path) in candidates {
                if let url = URL(string: base + path), url.scheme != nil, url.host != nil {
                    result.append((label, url))
                }
            }
        }
        var seen = Set<String>()
        return result.filter { seen.insert($0.1.absoluteString).inserted }
    }

    private static func chatURLs(_ endpoint: String) throws -> [URL] {
        var result: [URL] = []
        for base in try baseCandidates(endpoint) {
            let paths = base.lowercased().hasSuffix("/v1")
                ? ["/chat/completions"]
                : ["/v1/chat/completions", "/chat/completions"]
            for path in paths {
                if let url = URL(string: base + path), url.scheme != nil, url.host != nil {
                    result.append(url)
                }
            }
        }
        return unique(result)
    }

    private static func makeRequest(url: URL, method: String, token: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 10
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private static func request(url: URL, token: String) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(for: makeRequest(url: url, method: "GET", token: token))
    }

    private static func responseText(_ data: Data) -> String {
        guard let text = String(data: data, encoding: .utf8) else { return "响应正文不可读" }
        return String(text.prefix(160))
    }

    private static func unique(_ urls: [URL]) -> [URL] {
        var seen = Set<String>()
        return urls.filter {
            let key = $0.absoluteString
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    private static func modelIDs(_ value: Any) -> [String] {
        if let dictionary = value as? [String: Any] {
            if let data = dictionary["data"] { return modelIDs(data) }
            var result: [String] = []
            for (key, nested) in dictionary {
                if key == "id", let id = nested as? String { result.append(id) }
                if let list = nested as? [Any] { result += modelIDs(list) }
            }
            return result
        }
        if let array = value as? [Any] {
            return array.compactMap { item in
                if let model = item as? [String: Any] {
                    return model["id"] as? String ?? model["name"] as? String
                }
                return item as? String
            }
        }
        return []
    }

    private static func sub2Balance(_ value: Any) -> BalanceSnapshot? {
        let remaining = number(value, keys: ["remaining", "available", "balance", "user_balance"])
        guard let remaining else { return nil }
        let used = number(value, keys: ["used", "consumed", "usage"])
        let total = number(value, keys: ["total", "granted"])
        let unit = string(value, keys: ["unit"]) ?? "USD"
        return BalanceSnapshot(remaining: remaining, used: used, total: total, unit: unit, expiresAt: nil)
    }

    private static func newAPIbalance(_ value: Any) -> BalanceSnapshot? {
        let payload = (value as? [String: Any])?["data"] ?? value
        let remaining = number(payload, keys: ["total_available", "available", "remaining"])
        guard let remaining else { return nil }
        let used = number(payload, keys: ["total_used", "used"])
        let total = number(payload, keys: ["total_granted", "total"])
        let expires = number(payload, keys: ["expires_at"]).flatMap { $0 > 0 ? Date(timeIntervalSince1970: $0) : nil }
        return BalanceSnapshot(remaining: remaining, used: used, total: total, unit: "quota", expiresAt: expires)
    }

    private static func number(_ value: Any, keys: [String]) -> Double? {
        for key in keys {
            if let found = find(value, key: key),
               let number = found as? NSNumber { return number.doubleValue }
            if let found = find(value, key: key) as? String,
               let number = Double(found) { return number }
        }
        return nil
    }

    private static func string(_ value: Any, keys: [String]) -> String? {
        for key in keys {
            if let found = find(value, key: key) as? String, !found.isEmpty { return found }
        }
        return nil
    }

    private static func find(_ value: Any, key: String) -> Any? {
        if let dictionary = value as? [String: Any] {
            for (candidate, nested) in dictionary where candidate.lowercased() == key.lowercased() {
                return nested
            }
            for nested in dictionary.values {
                if let found = find(nested, key: key) { return found }
            }
        } else if let array = value as? [Any] {
            for nested in array {
                if let found = find(nested, key: key) { return found }
            }
        }
        return nil
    }
}

private struct AgentRootView: View {
    @AppStorage("iPadAgent.runtimeMode") private var storedRuntime = RuntimeMode.local.rawValue
    @AppStorage("iPadAgent.endpoint") private var endpoint = ""
    @AppStorage("iPadAgent.model") private var modelID = ""
    @AppStorage("iPadAgent.systemPrompt") private var systemPrompt = ""

    @State private var runtimeMode: RuntimeMode = .local
    @State private var conversations: [Conversation] = []
    @State private var didLoadConversations = false
    @State private var selectedConversation: UUID?
    @State private var activeMessages: [ChatMessage] = []
    @State private var composerText = ""
    @State private var isSending = false
    @State private var sendTask: Task<Void, Never>?
    @State private var activeRequestID: UUID?
    @State private var showSettings = false
    @State private var showFileImporter = false
    @State private var attachedFileName: String?
    @State private var attachedFileContent: String?
    @State private var statusText: String?
    @FocusState private var shouldFocusComposer: Bool

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 360)
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .preferredColorScheme(.dark)
        .onAppear {
            runtimeMode = RuntimeMode(rawValue: storedRuntime) ?? .local
            if modelID.isEmpty { modelID = "gpt-4o-mini" }
            loadConversationsIfNeeded()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(runtimeMode: $runtimeMode, endpoint: $endpoint, modelID: $modelID, systemPrompt: $systemPrompt)
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                attachedFileName = url.lastPathComponent
                attachedFileContent = readAttachment(url)
            case .failure(let error):
                statusText = error.localizedDescription
            }
        }
    }

    private var sidebar: some View {
        List(selection: $selectedConversation) {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iPad Agent").font(.title3.weight(.semibold))
                        Text("云端模型工作台").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 7)
                .listRowBackground(Color.clear)
            }

            Section {
                Button {
                    newConversation()
                } label: {
                    Label("新建对话", systemImage: "square.and.pencil")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .listRowBackground(Color.clear)
            }

            if conversations.isEmpty {
                Section("最近") {
                    Text("还没有对话")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("最近") {
                    ForEach(conversations) { conversation in
                        ConversationRow(conversation: conversation)
                            .tag(conversation.id)
                            .onTapGesture { open(conversation) }
                    }
                }
            }

            Section("工具") {
                ToolRow(title: "插件市场", icon: "storefront", color: .green) { showSettings = true }
                ToolRow(title: "运行环境", icon: runtimeMode.icon, color: runtimeMode.color) { showSettings = true }
                ToolRow(title: "文件与产物", icon: "folder", color: .orange) { showSettings = true }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("")
    }

    @ViewBuilder
    private var detailView: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if activeMessages.isEmpty {
                emptyState
            } else {
                chatView
            }
            composer
        }
        .background(Color(uiColor: .systemBackground))
    }

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(currentTitle)
                    .font(.title3.weight(.semibold))
                HStack(spacing: 6) {
                    Circle()
                        .fill(isSending ? .green : .secondary)
                        .frame(width: 7, height: 7)
                    Text(isSending ? "正在响应" : "就绪")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Menu {
                ForEach(RuntimeMode.allCases) { mode in
                    Button {
                        runtimeMode = mode
                        storedRuntime = mode.rawValue
                    } label: {
                        Label("\(mode.title) · \(mode.subtitle)", systemImage: mode.icon)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: runtimeMode.icon).foregroundStyle(runtimeMode.color)
                    Text(runtimeMode.title).font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.down").font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 15)
        .background(.bar)
    }

    private var emptyState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 54)
                VStack(alignment: .leading, spacing: 8) {
                    Text("有什么可以帮忙？")
                        .font(.system(size: 32, weight: .semibold))
                    Text("连接云端模型后，输入目标即可开始。工具会在需要时请求权限。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                RuntimeSelector(mode: $runtimeMode) {
                    storedRuntime = runtimeMode.rawValue
                }
                QuickActions { text in
                    composerText = text
                    shouldFocusComposer.toggle()
                }
                if endpoint.isEmpty {
                    SetupNotice { showSettings = true }
                }
                Spacer(minLength: 70)
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 34)
        }
    }

    private var chatView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(activeMessages) { message in
                        MessageRow(message: message)
                            .id(message.id)
                    }
                    if let statusText {
                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                    }
                }
                .frame(maxWidth: 860)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 34)
                .padding(.vertical, 28)
            }
            .onChange(of: activeMessages.count) { _ in
                if let last = activeMessages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 7) {
            if let attachedFileName {
                HStack(spacing: 7) {
                    Image(systemName: "paperclip")
                    Text(attachedFileName).lineLimit(1)
                    Button {
                        self.attachedFileName = nil
                        self.attachedFileContent = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 900, alignment: .leading)
            }

            HStack(alignment: .bottom, spacing: 10) {
                Button { showFileImporter = true } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                TextEditor(text: $composerText)
                    .focused($shouldFocusComposer)
                    .frame(minHeight: 40, maxHeight: 120)
                    .scrollContentBackground(.hidden)
                    .overlay(alignment: .topLeading) {
                        if composerText.isEmpty {
                            Text("输入消息…")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }

                Button {
                    if isSending { cancelSend() } else { send() }
                } label: {
                    Image(systemName: isSending ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : runtimeMode.color)
                }
                .disabled(!isSending && composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 17))
            .overlay {
                RoundedRectangle(cornerRadius: 17).stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }

            HStack(spacing: 7) {
                Image(systemName: "cloud.fill")
                Text("云端模型")
                Text("·")
                Text(modelID.isEmpty ? "未选择模型" : modelID)
                Spacer()
                Text(runtimeMode.subtitle)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: 900)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 34)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .background(.bar)
    }

    private var currentTitle: String {
        conversations.first(where: { $0.id == selectedConversation })?.title ?? "新对话"
    }

    private func newConversation() {
        sendTask?.cancel()
        sendTask = nil
        activeRequestID = nil
        isSending = false
        selectedConversation = nil
        activeMessages = []
        composerText = ""
        attachedFileName = nil
        attachedFileContent = nil
        statusText = nil
    }

    private func open(_ conversation: Conversation) {
        sendTask?.cancel()
        sendTask = nil
        activeRequestID = nil
        isSending = false
        selectedConversation = conversation.id
        activeMessages = conversation.messages
        attachedFileName = nil
        attachedFileContent = nil
        statusText = nil
    }

    private func send() {
        let text = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }

        if selectedConversation == nil {
            let conversation = Conversation(title: String(text.prefix(28)))
            conversations.insert(conversation, at: 0)
            selectedConversation = conversation.id
        }

        let user = ChatMessage(role: .user, text: text)
        let assistantID = UUID()
        let pendingAttachmentName = attachedFileName
        let pendingAttachmentContent = attachedFileContent
        activeMessages.append(user)
        activeMessages.append(ChatMessage(id: assistantID, role: .assistant, text: ""))
        composerText = ""
        attachedFileName = nil
        attachedFileContent = nil
        statusText = nil
        isSending = true
        persistActive()

        var history = activeMessages.dropLast().map {
            ["role": $0.role == .user ? "user" : "assistant", "content": $0.text]
        }
        if let pendingAttachmentName, let pendingAttachmentContent, !pendingAttachmentContent.isEmpty,
           let lastIndex = history.indices.last {
            let clipped = String(pendingAttachmentContent.prefix(24_000))
            history[lastIndex]["content"] = (history[lastIndex]["content"] ?? "")
                + "\n\n[附件：\(pendingAttachmentName)]\n\(clipped)"
        } else if let pendingAttachmentName, let lastIndex = history.indices.last {
            history[lastIndex]["content"] = (history[lastIndex]["content"] ?? "")
                + "\n\n[附件：\(pendingAttachmentName)]（未能读取文本内容，请根据文件名处理）"
        }
        if !systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            history.insert(["role": "system", "content": systemPrompt], at: 0)
        }
        let endpoint = endpoint
        let token = SecureStore.read()
        let model = modelID
        let requestID = UUID()
        activeRequestID = requestID
        sendTask = Task {
            var responseText = ""
            do {
                for try await chunk in ProviderClient.stream(endpoint: endpoint, token: token, model: model, history: Array(history)) {
                    responseText += chunk
                    if activeRequestID == requestID,
                       let index = activeMessages.firstIndex(where: { $0.id == assistantID }) {
                        activeMessages[index].text = responseText
                    }
                }
                if responseText.isEmpty {
                    if activeRequestID == requestID { statusText = "服务器没有返回文本内容" }
                }
            } catch is CancellationError {
                if activeRequestID == requestID { statusText = "已停止生成" }
            } catch {
                if activeRequestID == requestID,
                   let index = activeMessages.firstIndex(where: { $0.id == assistantID }) {
                    activeMessages[index].text = "请求失败：\(error.localizedDescription)"
                }
            }
            if activeRequestID == requestID {
                isSending = false
                sendTask = nil
                activeRequestID = nil
                persistActive()
            }
        }
    }

    private func cancelSend() {
        sendTask?.cancel()
        sendTask = nil
        activeRequestID = nil
        isSending = false
        statusText = "已停止生成"
        persistActive()
    }

    private func persistActive() {
        guard let id = selectedConversation,
              let index = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[index].messages = activeMessages
        conversations[index].updatedAt = Date()
        if let first = activeMessages.first(where: { $0.role == .user }) {
            conversations[index].title = String(first.text.prefix(28))
        }
        saveConversations()
    }

    private func loadConversationsIfNeeded() {
        guard !didLoadConversations else { return }
        didLoadConversations = true
        guard let data = UserDefaults.standard.data(forKey: "iPadAgent.conversations"),
              let saved = try? JSONDecoder().decode([Conversation].self, from: data) else { return }
        conversations = saved.sorted { $0.updatedAt > $1.updatedAt }
        if let first = conversations.first {
            selectedConversation = first.id
            activeMessages = first.messages
        }
    }

    private func saveConversations() {
        guard let data = try? JSONEncoder().encode(conversations) else { return }
        UserDefaults.standard.set(data, forKey: "iPadAgent.conversations")
    }

    private func readAttachment(_ url: URL) -> String? {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url), !data.isEmpty else { return nil }
        if let text = String(data: data, encoding: .utf8) { return text }
        return "文件已选择，但不是可直接读取的 UTF-8 文本。文件大小：\(data.count) 字节。"
    }
}

private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bubble.left.and.bubble.right")
                .foregroundStyle(.blue)
                .frame(width: 28, height: 28)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 3) {
                Text(conversation.title).lineLimit(1)
                Text(conversation.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ToolRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon).foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}

private struct RuntimeSelector: View {
    @Binding var mode: RuntimeMode
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("执行环境").font(.headline)
                Spacer()
                Text("模型始终在云端").font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                ForEach(RuntimeMode.allCases) { item in
                    Button {
                        mode = item
                        onChange()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: item.icon).foregroundStyle(item.color)
                                Spacer()
                                Image(systemName: mode == item ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(mode == item ? item.color : .secondary)
                            }
                            Text(item.title).font(.subheadline.weight(.semibold))
                            Text(item.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(mode == item ? item.color.opacity(0.11) : Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(mode == item ? item.color.opacity(0.7) : .clear, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct QuickActions: View {
    let action: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("可以从这里开始").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                QuickAction(title: "研究一个主题", icon: "globe") {
                    action("研究一个主题，整理关键结论并附上来源。")
                }
                QuickAction(title: "分析一个文件", icon: "doc.text") {
                    action("分析我附加的文件，提取重点并生成结构化摘要。")
                }
                QuickAction(title: "运行一段代码", icon: "terminal") {
                    action("在执行环境中运行这段代码，并解释输出和错误。")
                }
                QuickAction(title: "创建一个工作流", icon: "wand.and.stars") {
                    action("帮我把这个目标拆成可复用的 Agent 工作流。")
                }
            }
        }
    }
}

private struct QuickAction: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(13)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct SetupNotice: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "link")
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 3) {
                    Text("连接你的 AI 服务").font(.subheadline.weight(.semibold))
                    Text("输入兼容接口和 API Key，自动读取模型")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

private struct MessageRow: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            if message.role == .assistant {
                Image(systemName: "sparkles")
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.blue.gradient)
                    .clipShape(Circle())
            } else {
                Spacer(minLength: 70)
            }
            Text(message.text.isEmpty ? "…" : message.text)
                .font(.body)
                .foregroundStyle(message.role == .user ? .white : .primary)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(message.role == .user ? Color.accentColor : Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            if message.role == .assistant {
                Spacer(minLength: 50)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SettingsView: View {
    @Binding var runtimeMode: RuntimeMode
    @Binding var endpoint: String
    @Binding var modelID: String
    @Binding var systemPrompt: String
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = SecureStore.read()
    @State private var providerStatus = ProviderStatus()
    @State private var showPromptAssistant = false
    @State private var installedPlugins: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "iPadAgent.plugins") ?? [])

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 7) {
                        Label("连接云端模型", systemImage: "cloud.fill")
                            .font(.headline)
                        Text("只需要一个兼容接口。应用会自动读取模型；兼容服务的余额只在这里显示。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 5)
                }

                Section("连接") {
                    TextField("API Endpoint，例如 https://api.example.com/v1", text: $endpoint)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    SecureField("API Key", text: $apiKey)
                    if !providerStatus.models.isEmpty {
                        Picker("模型", selection: $modelID) {
                            ForEach(providerStatus.models, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                    } else {
                        TextField("模型 ID（可留空，连接后自动选择）", text: $modelID)
                            .textInputAutocapitalization(.never)
                    }
                    Button {
                        Task { await testConnection() }
                    } label: {
                        Label(providerStatus.isLoading ? "正在连接…" : "测试连接并读取模型", systemImage: "dot.radiowaves.left.and.right")
                    }
                    .disabled(providerStatus.isLoading)
                    Text(providerStatus.message)
                        .font(.caption)
                        .foregroundStyle(providerStatus.message.contains("成功") ? .green : .secondary)
                }

                Section("余额") {
                    if let balance = providerStatus.balance {
                        HStack {
                            Label("当前余额", systemImage: "creditcard.fill")
                            Spacer()
                            Text(balance.displayValue).font(.headline)
                        }
                        Text(balance.detail).font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("尚未读取。连接后自动探测兼容的余额接口。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("运行环境") {
                    Text("模型始终使用云端 API。以下选项只决定工具执行目标；未配置执行服务时不会执行命令。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(RuntimeMode.allCases) { mode in
                        Button {
                            runtimeMode = mode
                            UserDefaults.standard.set(mode.rawValue, forKey: "iPadAgent.runtimeMode")
                        } label: {
                            HStack {
                                Image(systemName: mode.icon).foregroundStyle(mode.color).frame(width: 25)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(mode.title)
                                    Text(mode.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if runtimeMode == mode {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(mode.color)
                                }
                            }
                        }
                    }
                }

                Section("插件市场") {
                    PluginRow(name: "网页研究套件", detail: "搜索、浏览、引用核验", icon: "globe", color: .blue, isInstalled: installedPlugins.contains("web")) {
                        togglePlugin("web")
                    }
                    PluginRow(name: "文件与文档", detail: "PDF、Office、OCR、导出", icon: "doc.text.fill", color: .orange, isInstalled: installedPlugins.contains("files")) {
                        togglePlugin("files")
                    }
                    PluginRow(name: "Alpine 执行工具", detail: "终端、Python、Node.js、包管理", icon: "terminal.fill", color: .green, isInstalled: installedPlugins.contains("alpine")) {
                        togglePlugin("alpine")
                    }
                    Text("当前为插件目录和本机启用开关。实际调用需要配置对应的 MCP 或执行服务；应用不会伪造已安装能力。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("系统提示词") {
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if systemPrompt.isEmpty {
                                Text("描述 Agent 的角色、语气、边界和工作习惯…")
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

                Section("数据") {
                    Label("API Key 使用 iOS Keychain 保存", systemImage: "lock.shield")
                    Label("会话、模型和最近余额保存在本机", systemImage: "internaldrive")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        SecureStore.save(apiKey)
                        UserDefaults.standard.set(endpoint, forKey: "iPadAgent.endpoint")
                        UserDefaults.standard.set(modelID, forKey: "iPadAgent.model")
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPromptAssistant) {
                PromptAssistantView(prompt: $systemPrompt, endpoint: endpoint, modelID: modelID)
            }
            .onAppear {
                restoreModels()
                restoreBalance()
            }
        }
    }

    private func testConnection() async {
        providerStatus.isLoading = true
        providerStatus.message = "正在连接…"
        SecureStore.save(apiKey)
        UserDefaults.standard.set(endpoint, forKey: "iPadAgent.endpoint")
        do {
            let models = try await ProviderClient.models(endpoint: endpoint, token: apiKey)
            if modelID.isEmpty { modelID = models.first ?? "" }
            providerStatus.models = models
            UserDefaults.standard.set(models, forKey: "iPadAgent.models")
            UserDefaults.standard.set(modelID, forKey: "iPadAgent.model")
            do {
                providerStatus.balance = try await ProviderClient.balance(endpoint: endpoint, token: apiKey)
                if let balance = providerStatus.balance,
                   let data = try? JSONEncoder().encode(balance) {
                    UserDefaults.standard.set(data, forKey: "iPadAgent.balance")
                }
                providerStatus.message = "连接成功 · 已读取 \(models.count) 个模型和余额"
            } catch {
                providerStatus.message = "连接成功 · 已读取 \(models.count) 个模型；余额：\(error.localizedDescription)"
            }
        } catch {
            providerStatus.message = "连接失败：\(error.localizedDescription)"
        }
        providerStatus.isLoading = false
    }

    private func togglePlugin(_ id: String) {
        if installedPlugins.contains(id) {
            installedPlugins.remove(id)
        } else {
            installedPlugins.insert(id)
        }
        UserDefaults.standard.set(Array(installedPlugins).sorted(), forKey: "iPadAgent.plugins")
    }

    private func restoreBalance() {
        guard let data = UserDefaults.standard.data(forKey: "iPadAgent.balance"),
              let balance = try? JSONDecoder().decode(BalanceSnapshot.self, from: data) else { return }
        providerStatus.balance = balance
    }

    private func restoreModels() {
        providerStatus.models = UserDefaults.standard.stringArray(forKey: "iPadAgent.models") ?? []
    }
}

private struct PluginRow: View {
    let name: String
    let detail: String
    let icon: String
    let color: Color
    let isInstalled: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 3) {
                Text(name).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(isInstalled ? "已启用" : "启用", action: action)
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
                .tint(isInstalled ? .secondary : color)
        }
    }
}

private struct PromptAssistantView: View {
    @Binding var prompt: String
    let endpoint: String
    let modelID: String
    @Environment(\.dismiss) private var dismiss
    @State private var goal = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("目标") {
                    TextField("例如：帮我做研究并保留来源", text: $goal, axis: .vertical)
                    Button {
                        generatePrompt()
                    } label: {
                        Label(isGenerating ? "正在生成…" : "生成提示词", systemImage: "sparkles")
                    }
                    .disabled(isGenerating || goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if let errorMessage {
                        Text(errorMessage).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("可编辑结果") {
                    TextEditor(text: $prompt).frame(minHeight: 230)
                }
            }
            .navigationTitle("AI 辅助填写")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func generatePrompt() {
        let goalText = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !goalText.isEmpty else { return }
        isGenerating = true
        errorMessage = nil
        let request = "请为一个云端 Agent 生成可直接使用的系统提示词。用户目标：\(goalText)。要求包含角色、工作流程、工具权限边界、失败处理和输出格式。只返回提示词正文，不要解释。"
        Task {
            var result = ""
            do {
                for try await chunk in ProviderClient.stream(
                    endpoint: endpoint,
                    token: SecureStore.read(),
                    model: modelID,
                    history: [["role": "user", "content": request]]
                ) {
                    result += chunk
                }
                if result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    errorMessage = "模型没有返回提示词"
                } else {
                    prompt = result.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isGenerating = false
        }
    }
}

#Preview {
    AgentRootView()
}
