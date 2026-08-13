# 参与 JimiDeck 开发

[English](CONTRIBUTING.md)

感谢你参与改进 JimiDeck。范围明确、理由清晰、便于审查的变更最容易被合并。

## 提交问题前

- 搜索已有 Issue，确认没有相同问题。
- 在最新发布版本或 `main` 分支复现问题。
- 从日志和截图中移除账户名、令牌、配置内容与私人文件路径。
- 发现安全漏洞时，请使用安全策略中说明的私密渠道。

## 开发环境

### macOS

安装 Xcode 16 或更高版本及 XcodeGen，然后运行：

```bash
xcodegen generate
Scripts/check_project_boundaries.sh
xcrun swift-format lint --strict --recursive App CoreAdapter Models Services Views JimiDeckTests
xcodebuild test \
  -project JimiDeck.xcodeproj \
  -scheme JimiDeck \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO
```

### Windows

安装 Node.js 22 LTS，然后运行：

```powershell
cd Windows
npm ci
npm run check
```

## 拉取请求

1. 一个拉取请求只解决一个明确问题。
2. 行为发生变化时，添加或更新测试。
3. 功能和平台支持发生变化时，同步更新面向用户的文档。
4. 不要提交凭据、本地配置数据、构建产物或生成的依赖目录。
5. 请求审查前，确认上述检查全部通过。

提交标题应简洁并使用祈使语气，例如 `fix(macOS): preserve imported profile metadata`。

## 项目边界

本仓库只包含 JimiDeck 应用及其发布工具。官网在父工作区的 `site/JimiDeck` 中独立维护，不会被复制到本仓库。`Scripts/check_project_boundaries.sh` 用于检查这一边界。

## 许可

提交贡献即表示你同意以本仓库的 [MIT 许可证](LICENSE)发布该贡献。请勿提交无法按兼容条款分发的代码或资源。
