# API 读取与执行架构

## 服务商自动探测

客户端只保存 `baseURL` 和 `Bearer API Key`，不要求用户先选择 Sub2API 或 NewAPI。

探测顺序：

1. `GET /v1/usage`
2. `GET /api/usage/token`
3. 读取模型列表：`GET /v1/models`、`GET /models`、`GET /api/models`

接口请求统一携带：

```http
Authorization: Bearer <API_KEY>
Accept: application/json
```

`404` 会继续探测下一个适配器；`401/403` 显示认证失败；返回 HTML、非法 JSON 或没有余额字段时显示未识别，不伪造余额。

## Sub2API

官方仓库：[Wei-Shaw/sub2api](https://github.com/Wei-Shaw/sub2api)

用户用量接口：

```http
GET /v1/usage
Authorization: Bearer <API_KEY>
```

余额字段按以下顺序读取：`remaining`、`quota.remaining`、`balance`、`user_balance`。单位读取 `unit` 或 `quota.unit`。

参考官方 Issue：[增加用户余额接口的讨论](https://github.com/Wei-Shaw/sub2api/issues/7886)

## NewAPI

官方仓库：[QuantumNous/new-api](https://github.com/QuantumNous/new-api)

官方 Token 用量接口：

```http
GET /api/usage/token
Authorization: Bearer <API_KEY>
```

主要响应字段：`data.total_granted`、`data.total_used`、`data.total_available`、`data.unlimited_quota`、`data.expires_at`。

余额使用 `data.total_available`，总额度使用 `data.total_granted`，已用额度使用 `data.total_used`。

官方文档：[Token Usage](https://doc.newapi.pro/en/api/token-usage/)

模型列表在登录态下还可以使用：

```http
GET /api/models
Authorization: Bearer <API_KEY>
New-Api-User: <USER_ID>
```

只有 API Key 时优先尝试 OpenAI 兼容的 `/v1/models`。

## 执行环境

Agent 控制层和云端模型调用保持在服务端。执行任务时选择运行时：

- 本地模式：为任务创建受控的 Alpine Linux 虚拟环境。
- 沙盒模式：为任务创建独立的云端隔离环境。
- 插件和 MCP：通过受限工具接口连接执行环境。

Alpine 只负责轻量基础用户空间，真正的隔离应由容器或 Firecracker microVM 提供。每个任务应独立限制网络、文件系统、CPU、内存、进程数和运行时间，并在任务结束或超时后销毁。

参考：[Alpine 镜像](https://hub.docker.com/_/alpine)、[Firecracker](https://github.com/firecracker-microvm/firecracker)、[OpenHands Docker Sandbox](https://github.com/OpenHands/docs/blob/main/openhands/usage/sandboxes/docker.mdx)、[E2B Runtime](https://github.com/e2b-dev/runtime)

## 插件市场

插件包应至少声明：

- `manifest.json`：名称、版本、作者、权限、入口和兼容版本。
- `skills/`：可复用技能和提示词。
- `mcp.json`：MCP Server 配置。
- `hooks/`：可选生命周期钩子。

安装前展示权限、数据范围、网络域名和运行环境；安装后支持启用、禁用、卸载、版本回滚和调用日志。

参考：[Open WebUI Extensibility](https://docs.openwebui.com/features/extensibility/)、[LibreChat Agent Plugins](https://www.librechat.ai/docs/features/agent_plugins)、[LobeChat](https://github.com/lobehub/lobe-chat)、[MCP Tools Specification](https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/docs/specification/2025-11-25/server/tools.mdx)

## 已接入的联网能力

### 网页研究

应用设置中的“联网能力”支持三类官方 API：

- Brave：`GET https://api.search.brave.com/res/v1/web/search`，使用 `X-Subscription-Token`。
- Tavily：`POST https://api.tavily.com/search`，使用请求体中的 `api_key`。
- Exa：`POST https://api.exa.ai/search`，使用 `x-api-key`。

密钥保存在 iOS Keychain，搜索结果只保留标题、URL 和摘要。网页抓取、引用核验和最终回答仍由云端模型完成。

### NewAPI 登录态

联网能力页面支持：

- `POST /api/user/login`
- `GET /api/user/self`
- `GET /api/user/models`
- `GET /api/usage/token`

登录返回的 `access_token` 使用独立 Keychain 项保存，不覆盖 OpenAI-compatible API Key。服务要求二次验证时会显示明确错误，不会把挑战响应当成登录成功。

### 远程插件目录

插件目录读取官方 MCP Registry：`GET https://registry.modelcontextprotocol.io/v0/servers`。iPad 只展示并保存 HTTPS `streamable-http`/`sse` 远程服务；不执行 `stdio` 包。真正调用 MCP 仍需要工具会话、权限确认和服务器端实现。

### 本地虚拟运行层与工作流

应用内提供受控虚拟工作区，不声称是完整 Alpine Linux。工作区只允许 `/workspace`，支持 `pwd`、`ls`、`cat`、`echo`、`write`、`touch`，并限制文件大小、输出大小、步骤超时和取消。完整 Alpine 需要后续嵌入 iSH/PRoot/rootfs 或连接独立执行服务。
