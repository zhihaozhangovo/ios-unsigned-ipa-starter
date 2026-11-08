import Foundation
import SwiftUI
import Security

enum IntegrationError: LocalizedError {
    case invalidEndpoint
    case http(Int, String)
    case invalidResponse(String)
    case missingAPIKey
    case twoFactorRequired

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint: return "服务地址无效，必须使用 HTTPS"
        case .http(let code, let body):
            let detail = body.trimmingCharacters(in: .whitespacesAndNewlines)
            return detail.isEmpty ? "服务返回 HTTP \(code)" : "服务返回 HTTP \(code)：\(detail.prefix(180))"
        case .invalidResponse(let message): return "服务响应无法识别：\(message)"
        case .missingAPIKey: return "请先配置 API Key"
        case .twoFactorRequired: return "服务要求二次验证，请在 NewAPI 控制台完成验证"
        }
    }
}

enum IntegrationKeychain {
    private static let service = "com.example.iPadAgent.integrations"

    static func read(_ account: String) -> String {
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

    static func save(_ value: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        guard let data = value.data(using: .utf8), !value.isEmpty else { return }
        let item = query.merging([
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]) { _, new in new }
        _ = SecItemAdd(item as CFDictionary, nil)
    }

    static func remove(_ account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum WebSearchProvider: String, CaseIterable, Identifiable {
    case brave
    case tavily
    case exa

    var id: String { rawValue }
    var title: String {
        switch self {
        case .brave: return "Brave Search"
        case .tavily: return "Tavily"
        case .exa: return "Exa"
        }
    }
}

struct WebSearchResult: Identifiable, Codable {
    let id: UUID
    let title: String
    let url: String
    let snippet: String

    init(title: String, url: String, snippet: String) {
        self.id = UUID()
        self.title = title
        self.url = url
        self.snippet = snippet
    }
}

enum WebSearchService {
    static func search(query: String, provider: WebSearchProvider, apiKey: String) async throws -> [WebSearchResult] {
        guard !apiKey.isEmpty else { throw IntegrationError.missingAPIKey }
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        var request: URLRequest
        switch provider {
        case .brave:
            var components = URLComponents(string: "https://api.search.brave.com/res/v1/web/search")!
            components.queryItems = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "count", value: "10")]
            request = URLRequest(url: components.url!)
            request.setValue(apiKey, forHTTPHeaderField: "X-Subscription-Token")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
        case .tavily:
            request = URLRequest(url: URL(string: "https://api.tavily.com/search")!)
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "api_key": apiKey, "query": query, "search_depth": "advanced",
                "include_answer": true, "include_raw_content": false, "max_results": 10
            ])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .exa:
            request = URLRequest(url: URL(string: "https://api.exa.ai/search")!)
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "query": query, "numResults": 10, "contents": ["text": true]
            ])
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.httpMethod = provider == .brave ? "GET" : "POST"
        request.timeoutInterval = 20
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw IntegrationError.invalidResponse("缺少 HTTP 状态码") }
        guard (200..<300).contains(http.statusCode) else {
            throw IntegrationError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            throw IntegrationError.invalidResponse("不是合法 JSON")
        }
        return parseResults(json, provider: provider)
    }

    private static func parseResults(_ value: Any, provider: WebSearchProvider) -> [WebSearchResult] {
        let items: [[String: Any]]
        switch provider {
        case .brave:
            items = ((value as? [String: Any])?["web"] as? [String: Any])?["results"] as? [[String: Any]] ?? []
        case .tavily:
            items = (value as? [String: Any])?["results"] as? [[String: Any]] ?? []
        case .exa:
            items = (value as? [String: Any])?["results"] as? [[String: Any]] ?? []
        }
        return items.compactMap { item in
            guard let url = item["url"] as? String else { return nil }
            let title = (item["title"] as? String) ?? (item["name"] as? String) ?? url
            let snippet = (item["description"] as? String) ?? (item["snippet"] as? String) ?? (item["text"] as? String) ?? ""
            return WebSearchResult(title: title, url: url, snippet: snippet)
        }
    }
}

struct MCPRemotePlugin: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let version: String
    let url: String
    var isInstalled: Bool = false
}

enum MCPRegistryService {
    static func list(limit: Int = 30) async throws -> [MCPRemotePlugin] {
        var components = URLComponents(string: "https://registry.modelcontextprotocol.io/v0/servers")!
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit)), URLQueryItem(name: "version", value: "latest")]
        var request = URLRequest(url: components.url!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw IntegrationError.invalidResponse("缺少 HTTP 状态码") }
        guard (200..<300).contains(http.statusCode) else {
            throw IntegrationError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let servers = root["servers"] as? [[String: Any]] else {
            throw IntegrationError.invalidResponse("MCP Registry 返回格式不正确")
        }
        return servers.compactMap { entry in
            let server = entry["server"] as? [String: Any] ?? entry
            let remotes = server["remotes"] as? [[String: Any]] ?? []
            let remote = remotes.first { remote in
                let type = (remote["type"] as? String)?.lowercased() ?? ""
                let url = remote["url"] as? String ?? ""
                return (type == "streamable-http" || type == "sse") && URL(string: url)?.scheme == "https"
            }
            guard let url = remote?["url"] as? String,
                  let name = server["name"] as? String else { return nil }
            return MCPRemotePlugin(
                id: name,
                name: (server["title"] as? String) ?? name,
                description: (server["description"] as? String) ?? "",
                version: (server["version"] as? String) ?? "未知版本",
                url: url
            )
        }
    }
}

struct NewAPISession: Codable {
    let accessToken: String
    let userID: Int?
    let username: String?
    let expiresAt: Date?
}

enum NewAPIService {
    private static let sessionAccount = "newapi-access-token"

    static func login(endpoint: String, username: String, password: String) async throws -> NewAPISession {
        let base = try baseURL(endpoint)
        var request = URLRequest(url: base.appendingPathComponent("api/user/login"))
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["username": username, "password": password])
        let (data, response) = try await URLSession.shared.data(for: request)
        let root = try json(data, response)
        let payload = root["data"] as? [String: Any] ?? root
        if payload["challenge"] != nil || payload["requires_2fa"] as? Bool == true { throw IntegrationError.twoFactorRequired }
        guard let token = payload["access_token"] as? String, !token.isEmpty else {
            throw IntegrationError.invalidResponse("登录成功响应中没有 access_token")
        }
        let user = payload["user"] as? [String: Any]
        let session = NewAPISession(accessToken: token, userID: user?["id"] as? Int, username: user?["username"] as? String, expiresAt: parseDate(payload["access_expires_at"]))
        IntegrationKeychain.save(token, account: sessionAccount)
        return session
    }

    static func storedToken() -> String { IntegrationKeychain.read(sessionAccount) }
    static func logout() { IntegrationKeychain.remove(sessionAccount) }

    static func selfInfo(endpoint: String, token: String) async throws -> [String: Any] {
        let base = try baseURL(endpoint)
        var request = URLRequest(url: base.appendingPathComponent("api/user/self"))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        return try json(data, response)
    }

    static func models(endpoint: String, token: String) async throws -> [String] {
        let base = try baseURL(endpoint)
        var request = URLRequest(url: base.appendingPathComponent("api/user/models"))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        let root = try json(data, response)
        let payload = root["data"] ?? root
        if let list = payload as? [[String: Any] ] { return list.compactMap { $0["id"] as? String ?? $0["name"] as? String } }
        return payload as? [String] ?? []
    }

    private static func baseURL(_ endpoint: String) throws -> URL {
        var value = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        while value.hasSuffix("/") { value.removeLast() }
        if value.lowercased().hasSuffix("/v1") {
            value.removeLast(3)
            while value.hasSuffix("/") { value.removeLast() }
        }
        guard let url = URL(string: value), url.scheme?.lowercased() == "https", url.host != nil else { throw IntegrationError.invalidEndpoint }
        return url
    }

    private static func json(_ data: Data, _ response: URLResponse) throws -> [String: Any] {
        guard let http = response as? HTTPURLResponse else { throw IntegrationError.invalidResponse("缺少 HTTP 状态码") }
        guard (200..<300).contains(http.statusCode) else { throw IntegrationError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "") }
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw IntegrationError.invalidResponse("不是对象 JSON") }
        return root
    }

    private static func parseDate(_ value: Any?) -> Date? {
        if let number = value as? NSNumber { return Date(timeIntervalSince1970: number.doubleValue) }
        if let string = value as? String { return ISO8601DateFormatter().date(from: string) }
        return nil
    }
}

struct IntegrationCenterView: View {
    @Binding var endpoint: String
    @Binding var modelID: String
    @AppStorage("iPadAgent.webProvider") private var storedWebProvider = WebSearchProvider.brave.rawValue
    @State private var webKey = IntegrationKeychain.read("web-search-key")
    @State private var webProvider: WebSearchProvider = .brave
    @State private var searchQuery = ""
    @State private var searchResults: [WebSearchResult] = []
    @State private var searchStatus = ""
    @State private var newAPIUsername = ""
    @State private var newAPIPassword = ""
    @State private var newAPIStatus = ""
    @State private var newAPISession: NewAPISession?
    @State private var plugins: [MCPRemotePlugin] = []
    @State private var pluginStatus = ""
    @State private var isLoadingPlugins = false

    var body: some View {
        List {
            Section("网页研究 API") {
                Picker("服务商", selection: $webProvider) {
                    ForEach(WebSearchProvider.allCases) { provider in
                        Text(provider.title).tag(provider)
                    }
                }
                SecureField("API Key", text: $webKey)
                    .textInputAutocapitalization(.never)
                TextField("研究主题", text: $searchQuery, axis: .vertical)
                Button {
                    Task { await runSearch() }
                } label: {
                    Label("搜索并读取来源", systemImage: "globe")
                }
                .disabled(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || webKey.isEmpty)
                if !searchStatus.isEmpty {
                    Text(searchStatus).font(.caption).foregroundStyle(.secondary)
                }
                ForEach(searchResults) { result in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.title).font(.subheadline.weight(.semibold))
                        Text(result.url).font(.caption).foregroundStyle(.blue).lineLimit(1)
                        Text(result.snippet).font(.caption).foregroundStyle(.secondary).lineLimit(3)
                    }
                    .padding(.vertical, 3)
                }
                Text("密钥只保存到 Keychain；网页搜索使用 Brave、Tavily 或 Exa 官方 API。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("NewAPI 登录态") {
                TextField("NewAPI 地址，例如 https://api.example.com", text: $endpoint)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                TextField("用户名或邮箱", text: $newAPIUsername)
                    .textInputAutocapitalization(.never)
                SecureField("密码", text: $newAPIPassword)
                Button {
                    Task { await loginNewAPI() }
                } label: {
                    Label("登录并读取用户信息", systemImage: "person.badge.key")
                }
                if let session = newAPISession {
                    Text(session.username.map { "已登录：\($0)" } ?? "已登录")
                        .foregroundStyle(.green)
                    Button("退出 NewAPI") {
                        NewAPIService.logout()
                        newAPISession = nil
                        newAPIStatus = "已退出登录"
                    }
                }
                if !newAPIStatus.isEmpty {
                    Text(newAPIStatus).font(.caption).foregroundStyle(.secondary)
                }
                Text("登录态使用独立 Token，不覆盖 OpenAI-compatible API Key。需要二次验证时会明确提示。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("远程插件市场") {
                Button {
                    Task { await loadPlugins() }
                } label: {
                    Label(isLoadingPlugins ? "正在读取目录…" : "读取官方 MCP Registry", systemImage: "shippingbox")
                }
                .disabled(isLoadingPlugins)
                if !pluginStatus.isEmpty {
                    Text(pluginStatus).font(.caption).foregroundStyle(.secondary)
                }
                ForEach(plugins) { plugin in
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(plugin.name).font(.subheadline.weight(.semibold))
                            Text(plugin.description.isEmpty ? plugin.url : plugin.description)
                                .font(.caption).foregroundStyle(.secondary).lineLimit(3)
                            Text("v\(plugin.version) · HTTPS MCP")
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Button(plugin.isInstalled ? "已启用" : "启用") {
                            installPlugin(plugin)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                Text("仅显示 HTTPS 远程 MCP；iPad 不直接运行 stdio 插件。启用只保存远程地址，实际调用仍需权限确认和 MCP 会话。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("联网能力")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            webProvider = WebSearchProvider(rawValue: storedWebProvider) ?? .brave
            let token = NewAPIService.storedToken()
            if !token.isEmpty {
                newAPISession = NewAPISession(accessToken: token, userID: nil, username: nil, expiresAt: nil)
            }
        }
    }

    private func runSearch() async {
        searchStatus = "正在搜索…"
        IntegrationKeychain.save(webKey, account: "web-search-key")
        storedWebProvider = webProvider.rawValue
        do {
            searchResults = try await WebSearchService.search(query: searchQuery, provider: webProvider, apiKey: webKey)
            searchStatus = "找到 \(searchResults.count) 条来源"
        } catch { searchStatus = error.localizedDescription }
    }

    private func loginNewAPI() async {
        newAPIStatus = "正在登录…"
        do {
            newAPISession = try await NewAPIService.login(endpoint: endpoint, username: newAPIUsername, password: newAPIPassword)
            newAPIStatus = "登录成功"
            if let token = newAPISession?.accessToken,
               let models = try? await NewAPIService.models(endpoint: endpoint, token: token),
               let first = models.first, modelID.isEmpty {
                modelID = first
            }
        } catch { newAPIStatus = error.localizedDescription }
    }

    private func loadPlugins() async {
        isLoadingPlugins = true
        defer { isLoadingPlugins = false }
        do {
            let installed = Set(UserDefaults.standard.stringArray(forKey: "iPadAgent.mcpPlugins") ?? [])
            plugins = try await MCPRegistryService.list().map { plugin in
                var updated = plugin
                updated.isInstalled = installed.contains(plugin.id)
                return updated
            }
            pluginStatus = "已读取 \(plugins.count) 个 HTTPS MCP"
        } catch { pluginStatus = error.localizedDescription }
    }

    private func installPlugin(_ plugin: MCPRemotePlugin) {
        var installed = Set(UserDefaults.standard.stringArray(forKey: "iPadAgent.mcpPlugins") ?? [])
        installed.insert(plugin.id)
        UserDefaults.standard.set(Array(installed).sorted(), forKey: "iPadAgent.mcpPlugins")
        if let index = plugins.firstIndex(where: { $0.id == plugin.id }) { plugins[index].isInstalled = true }
    }
}
