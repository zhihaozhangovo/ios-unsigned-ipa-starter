import Foundation
import SwiftUI

/// 应用内受控运行层。iPadOS 不能直接启动 Alpine 进程，因此这里提供一个只操作
/// /workspace 的虚拟文件系统和白名单命令执行器。接入 Alpine/沙盒服务后可复用同一工作流协议。
enum AgentExecutionEnvironment: String, Codable, CaseIterable, Identifiable {
    case local
    case sandbox

    var id: String { rawValue }

    var title: String {
        switch self {
        case .local: return "本地虚拟工作区"
        case .sandbox: return "云端沙盒"
        }
    }
}

enum VirtualRuntimeError: LocalizedError {
    case invalidPath
    case fileNotFound(String)
    case unsupportedCommand(String)
    case outputTooLarge
    case timedOut
    case sandboxUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidPath: return "只能访问 /workspace 下的文件"
        case .fileNotFound(let path): return "文件不存在：\(path)"
        case .unsupportedCommand(let command): return "虚拟运行层不支持命令：\(command)"
        case .outputTooLarge: return "命令输出超过 256 KB"
        case .timedOut: return "工作流步骤超时"
        case .sandboxUnavailable: return "云端沙盒尚未配置执行服务"
        }
    }
}

actor VirtualWorkspace {
    static let shared = VirtualWorkspace()

    private var files: [String: String] = [
        "/workspace/README.txt": "iPadAgent virtual workspace\n"
    ]
    private let maxFileBytes = 256 * 1024
    private let maxOutputBytes = 256 * 1024

    func execute(command: String, timeout: TimeInterval = 30) async throws -> String {
        let operation = Task { try await self.perform(command: command) }
        return try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask { try await operation.value }
            group.addTask {
                let nanos = UInt64(max(0.1, timeout) * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanos)
                throw VirtualRuntimeError.timedOut
            }
            defer {
                group.cancelAll()
                operation.cancel()
            }
            let output = try await group.next()!
            guard output.utf8.count <= maxOutputBytes else { throw VirtualRuntimeError.outputTooLarge }
            return output
        }
    }

    func snapshot() -> [String: String] { files }

    private func perform(command: String) async throws -> String {
        try Task.checkCancellation()
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let parts = trimmed.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true).map(String.init)
        guard let name = parts.first else { return "" }

        switch name {
        case "help":
            return "支持：pwd、ls、cat <path>、echo <text>、write <path> <text>、touch <path>"
        case "pwd":
            return "/workspace"
        case "ls":
            let directory = parts.count > 1 ? try workspacePath(parts[1]) : "/workspace"
            let prefix = directory.hasSuffix("/") ? directory : directory + "/"
            let names = Set(files.keys.compactMap { path -> String? in
                guard path.hasPrefix(prefix) else { return nil }
                let rest = String(path.dropFirst(prefix.count))
                guard !rest.isEmpty else { return nil }
                return rest.split(separator: "/").first.map(String.init)
            }).sorted()
            return names.joined(separator: "\n")
        case "echo":
            return parts.dropFirst().joined(separator: " ")
        case "cat":
            guard parts.count >= 2 else { throw VirtualRuntimeError.fileNotFound("<path>") }
            let path = try workspacePath(parts[1])
            guard let content = files[path] else { throw VirtualRuntimeError.fileNotFound(path) }
            return content
        case "touch":
            guard parts.count >= 2 else { throw VirtualRuntimeError.invalidPath }
            let path = try workspacePath(parts[1])
            if files[path] == nil { files[path] = "" }
            return ""
        case "write":
            guard parts.count >= 3 else { throw VirtualRuntimeError.invalidPath }
            let path = try workspacePath(parts[1])
            let content = parts[2]
            guard content.utf8.count <= maxFileBytes else { throw VirtualRuntimeError.outputTooLarge }
            files[path] = content
            return "已写入 \(path)（\(content.utf8.count) 字节）"
        default:
            throw VirtualRuntimeError.unsupportedCommand(name)
        }
    }

    private func workspacePath(_ raw: String) throws -> String {
        var path = raw.hasPrefix("/") ? raw : "/workspace/\(raw)"
        while path.contains("//") { path = path.replacingOccurrences(of: "//", with: "/") }
        guard path == "/workspace" || path.hasPrefix("/workspace/"),
              !path.contains("..") else { throw VirtualRuntimeError.invalidPath }
        while path.count > 1 && path.hasSuffix("/") { path.removeLast() }
        return path
    }
}

enum WorkflowStepKind: String, Codable, CaseIterable, Identifiable {
    case command
    case writeText
    case delay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .command: return "运行受控命令"
        case .writeText: return "写入工作区文件"
        case .delay: return "等待"
        }
    }
}

struct WorkflowStep: Identifiable, Codable {
    let id: UUID
    var name: String
    var kind: WorkflowStepKind
    var input: String
    var timeout: TimeInterval

    init(id: UUID = UUID(), name: String, kind: WorkflowStepKind, input: String, timeout: TimeInterval = 30) {
        self.id = id
        self.name = name
        self.kind = kind
        self.input = input
        self.timeout = timeout
    }
}

struct AgentWorkflow: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var environment: AgentExecutionEnvironment
    var steps: [WorkflowStep]
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, description: String, environment: AgentExecutionEnvironment = .local, steps: [WorkflowStep], updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.environment = environment
        self.steps = steps
        self.updatedAt = updatedAt
    }
}

struct WorkflowEvent: Identifiable, Codable {
    let id: UUID
    let workflowID: UUID
    let stepID: UUID?
    let message: String
    let isError: Bool
    let createdAt: Date

    init(workflowID: UUID, stepID: UUID? = nil, message: String, isError: Bool = false) {
        self.id = UUID()
        self.workflowID = workflowID
        self.stepID = stepID
        self.message = message
        self.isError = isError
        self.createdAt = Date()
    }
}

struct WorkflowRunRecord: Identifiable, Codable {
    let id: UUID
    let workflowID: UUID
    var events: [WorkflowEvent]
    var output: String
    var finishedAt: Date?

    init(workflowID: UUID) {
        self.id = UUID()
        self.workflowID = workflowID
        self.events = []
        self.output = ""
        self.finishedAt = nil
    }
}

enum WorkflowExecutionError: LocalizedError {
    case unsupportedEnvironment(AgentExecutionEnvironment)

    var errorDescription: String? {
        switch self {
        case .unsupportedEnvironment(let environment):
            return "\(environment.title)尚未配置执行服务"
        }
    }
}

actor WorkflowEngine {
    static let shared = WorkflowEngine()

    func run(_ workflow: AgentWorkflow, workspace: VirtualWorkspace = .shared) async throws -> WorkflowRunRecord {
        guard workflow.environment == .local else {
            throw WorkflowExecutionError.unsupportedEnvironment(workflow.environment)
        }

        var record = WorkflowRunRecord(workflowID: workflow.id)
        for step in workflow.steps {
            try Task.checkCancellation()
            record.events.append(WorkflowEvent(workflowID: workflow.id, stepID: step.id, message: "开始：\(step.name)"))
            do {
                let result: String
                switch step.kind {
                case .command:
                    result = try await workspace.execute(command: step.input, timeout: step.timeout)
                case .writeText:
                    result = try await workspace.execute(command: "write \(step.input)", timeout: step.timeout)
                case .delay:
                    let nanos = UInt64(max(0.1, step.timeout) * 1_000_000_000)
                    try await Task.sleep(nanoseconds: nanos)
                    result = "等待完成"
                }
                record.output += "[\(step.name)]\n\(result)\n"
                record.events.append(WorkflowEvent(workflowID: workflow.id, stepID: step.id, message: result))
            } catch {
                record.events.append(WorkflowEvent(workflowID: workflow.id, stepID: step.id, message: error.localizedDescription, isError: true))
                throw error
            }
        }
        record.finishedAt = Date()
        return record
    }
}

final class WorkflowLibrary {
    static let shared = WorkflowLibrary()
    private let key = "iPadAgent.workflows"

    func load() -> [AgentWorkflow] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let workflows = try? JSONDecoder().decode([AgentWorkflow].self, from: data) else {
            return Self.defaults
        }
        return workflows
    }

    func save(_ workflows: [AgentWorkflow]) {
        guard let data = try? JSONEncoder().encode(workflows) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func upsert(_ workflow: AgentWorkflow) {
        var workflows = load()
        if let index = workflows.firstIndex(where: { $0.id == workflow.id }) {
            workflows[index] = workflow
        } else {
            workflows.insert(workflow, at: 0)
        }
        save(workflows)
    }

    private static let defaults: [AgentWorkflow] = [
        AgentWorkflow(
            name: "检查虚拟工作区",
            description: "查看当前工作区并读取说明文件。",
            steps: [
                WorkflowStep(name: "当前目录", kind: .command, input: "pwd"),
                WorkflowStep(name: "文件列表", kind: .command, input: "ls"),
                WorkflowStep(name: "读取说明", kind: .command, input: "cat /workspace/README.txt")
            ]
        )
    ]
}

struct WorkflowManagerView: View {
    @State private var workflows = WorkflowLibrary.shared.load()
    @State private var runningID: UUID?
    @State private var output = ""
    @State private var showingEditor = false

    var body: some View {
        List {
            Section {
                Text("本地模式使用应用内受控虚拟工作区，只允许 /workspace 和白名单命令。沙盒模式需要配置云端执行服务。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("工作流") {
                ForEach(workflows) { workflow in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(workflow.name).font(.subheadline.weight(.semibold))
                                Text(workflow.description).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(runningID == workflow.id ? "运行中…" : "运行") {
                                run(workflow)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(runningID != nil)
                        }
                        Text("\(workflow.environment.title) · \(workflow.steps.count) 步")
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
            if !output.isEmpty {
                Section("最近输出") {
                    Text(output)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("工作流")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingEditor = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            WorkflowEditorView { workflow in
                WorkflowLibrary.shared.upsert(workflow)
                workflows = WorkflowLibrary.shared.load()
            }
        }
    }

    private func run(_ workflow: AgentWorkflow) {
        runningID = workflow.id
        output = "正在运行：\(workflow.name)"
        Task {
            do {
                let record = try await WorkflowEngine.shared.run(workflow)
                output = record.output.isEmpty ? "工作流完成，没有输出。" : record.output
            } catch {
                output = "运行失败：\(error.localizedDescription)"
            }
            runningID = nil
        }
    }
}

private struct WorkflowEditorView: View {
    let onSave: (AgentWorkflow) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var command = "pwd"

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("工作流名称", text: $name)
                    TextField("说明", text: $description, axis: .vertical)
                }
                Section("第一步") {
                    TextField("受控命令，例如 ls 或 cat /workspace/README.txt", text: $command, axis: .vertical)
                    Text("支持 pwd、ls、cat、echo、write、touch。")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("新建工作流")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let step = WorkflowStep(name: "执行命令", kind: .command, input: command)
                        onSave(AgentWorkflow(name: title.isEmpty ? "未命名工作流" : title, description: description, steps: [step]))
                        dismiss()
                    }
                    .disabled(command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
