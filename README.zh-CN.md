<p align="center">
  <img src="Assets.xcassets/AppIcon.appiconset/appicon-256.png" width="112" alt="JimiDeck 图标">
</p>

<h1 align="center">JimiDeck</h1>

<p align="center">
  在一个启动器中管理 ChatGPT 桌面端与 Codex CLI 配置。
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="https://deck.jimidou.com">官方网站</a> ·
  <a href="https://github.com/zybless/JimiDeck/releases">下载</a>
</p>

<p align="center">
  <a href="https://github.com/zybless/JimiDeck/actions/workflows/ci.yml"><img src="https://github.com/zybless/JimiDeck/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-2ea44f" alt="MIT 许可证"></a>
  <img src="https://img.shields.io/badge/release-0.2.0--alpha-orange" alt="0.2.0 Alpha">
</p>

JimiDeck 用一个清晰的入口管理多个 Codex 使用环境。你可以为工作、个人或不同项目分别命名配置，并让它们使用各自独立的本地数据目录。

## 主要功能

- 在一个界面中启动默认环境和具名配置。
- 在 macOS 管理 ChatGPT 桌面端配置，在 macOS 与 Windows 管理 Codex CLI 配置。
- 将已有的 `codex-profile` 配置导入桌面应用。
- 为 CLI 配置选择项目目录，并快速重新打开最近项目。
- 启动前检查运行环境、目录与配置完整性。
- 配置元数据只保存在本机；JimiDeck 不提供账户服务，也不会读取认证令牌。

## 平台支持

| 功能 | macOS 14+ | Windows 10/11 x64 |
| --- | --- | --- |
| ChatGPT 桌面端配置 | 支持 | 仅默认配置 |
| Codex CLI 配置 | 支持 | 支持 |
| 导入已有 `codex-profile` 配置 | 支持 | 计划中 |
| 应用界面 | 原生 SwiftUI | Electron |

JimiDeck 目前仍处于 Alpha 阶段。Windows 版本以 Codex CLI 配置为主，因为 ChatGPT 桌面端在 Windows 上没有提供相同的配置目录启动方式。

## 安装

请从 [GitHub Releases](https://github.com/zybless/JimiDeck/releases) 或 [JimiDeck 官网](https://deck.jimidou.com) 下载最新版本。

| 平台 | 格式 | 适用场景 |
| --- | --- | --- |
| macOS | `.dmg` | 标准安装 |
| macOS | `.zip` | 免安装归档 |
| Windows | `.exe` | 标准安装 |
| Windows | `.zip` | 便携版本 |

当前 Alpha 构建尚未签名。打开下载文件前，请核对发布页提供的 SHA-256 校验值。

## 从源码构建

### macOS

需要 Xcode 16 或更高版本，以及 [XcodeGen](https://github.com/yonaskolb/XcodeGen)。

```bash
xcodegen generate
xcodebuild test \
  -project JimiDeck.xcodeproj \
  -scheme JimiDeck \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO
```

### Windows

需要 Node.js 22 LTS 与 npm。

```powershell
cd Windows
npm ci
npm run check
npm start
```

## 配置隔离方式

每个具名配置都拥有独立的数据目录。JimiDeck 将该目录交给兼容的启动器，并只保存展示和再次启动所需的元数据。这能避免日常使用中的状态混用，但不等同于操作系统级安全沙箱。

存储、启动和删除流程详见[架构说明](ARCHITECTURE.md)。

## 参与贡献

欢迎提交可复现的问题报告和范围明确的拉取请求。请先阅读[贡献指南](CONTRIBUTING.zh-CN.md)与[行为准则](CODE_OF_CONDUCT.md)；安全问题请按照[安全策略](SECURITY.md)私下报告。

## 许可证

JimiDeck 采用 [MIT 许可证](LICENSE)，在遵守许可证条款的前提下可用于私人或商业用途。项目名称与标志适用单独的[商标指引](TRADEMARKS.md)，第三方组件保留各自的许可证与声明。

## 致谢

macOS 兼容层基于 [`Ducksss/codex-profiles`](https://github.com/Ducksss/codex-profiles) 构建，具体版本与许可证见[第三方声明](THIRD_PARTY_NOTICES.md)。
