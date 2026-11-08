# iPadAgent

SwiftUI iPad 客户端，用于连接云端 OpenAI-compatible API。应用支持多对话、流式回复、自动读取模型、Sub2API/NewAPI 用量探测、API Key Keychain 保存、系统提示词、文件附件、运行模式选择和插件入口。

应用不提供本地模型。模型请求始终发送到用户配置的云端 Endpoint；“本地模式”使用应用内受控虚拟工作区和白名单工作流，“沙盒模式”表示云端隔离环境。完整 Alpine Linux 和云端沙盒需要后续接入 iSH/rootfs 或独立执行服务。

## 云端构建

推送到 `main`，或在 GitHub Actions 中手动运行 **Build iPadAgent unsigned IPA**。工作流使用 macOS runner 构建 `iPadAgent.xcodeproj`，关闭代码签名，并上传 `iPadAgent-unsigned.ipa` artifact。

```bash
xcodebuild \
  -project iPadAgent.xcodeproj \
  -scheme iPadAgent \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build
```

未签名 IPA 不能直接安装。安装前需要使用与应用 Bundle ID、设备和 provisioning profile 匹配的证书重新签名。当前工程中的 `com.example.iPadAgent` 是开发占位 Bundle ID，发布前必须替换为正式 ID，并补齐应用图标、隐私清单和商店元数据。

## API 兼容性

- 模型读取：`/v1/models`、`/models`、`/api/models`
- 聊天：`/v1/chat/completions`、`/chat/completions`
- Sub2API 用量：`GET /v1/usage`
- NewAPI 用量：`GET /api/usage/token`

请求使用 `Authorization: Bearer <API_KEY>`。Endpoint、模型和运行环境保存于应用设置；API Key 保存于 iOS Keychain。

## 已接入能力

- 文件选择和 OpenAI-compatible `/v1/files`、`/files` multipart 上传；上传失败时文本文件可回退为内联内容。
- Brave、Tavily、Exa 网页研究 API。
- NewAPI 登录态、用户模型读取和独立 access token 保存。
- 官方 MCP Registry HTTPS 远程插件目录；iPad 不执行 stdio 插件。
- 本地受控虚拟工作区、工作流保存、步骤超时、取消和输出回传。

## 相关文档

- [API_INTEGRATION.md](API_INTEGRATION.md)：服务商探测、余额字段和运行环境接口约定。

## 许可证

MIT
