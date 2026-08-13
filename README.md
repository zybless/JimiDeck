# JimiDeck

JimiDeck 是一个跨平台的 Codex 实例管理器，用来分开工作、个人及不同项目的登录状态和本地配置。

当前版本为 **0.2.0 Alpha**。软件完全在本地管理实例元数据，不提供云端账号服务。

> 仓库边界：本仓库只包含桌面 App。官网源码和静态产物严格位于独立的 `site/JimiDeck` 项目中，禁止把网站代码、依赖或构建目录放入 App 仓库。

## 平台支持

| 功能 | macOS | Windows |
|---|---:|---:|
| 启动系统默认 ChatGPT Desktop | ✓ | ✓ |
| 自定义 ChatGPT Desktop 多实例 | ✓ 兼容层 | 暂不支持 |
| 导入已有 `codex-profile` | ✓ | 暂不支持 |
| 系统默认 Codex CLI | ✓ | ✓ |
| 独立 Codex CLI Profile | ✓ | ✓ |
| CLI 项目目录选择 | ✓ | ✓ |

macOS 使用原生 SwiftUI/AppKit 实现；Windows 使用 Electron/PowerShell 实现。两端共享产品行为、Profile 命名和安全边界，但平台 UI 与启动适配代码不同。

macOS 会在设置中发现由命令行创建的 Profile。导入时需要明确选择 Desktop 或 CLI；导入不会复制或迁移底层数据。外部 Profile 可仅从 JimiDeck 移除，也可在明确确认后连同底层数据一起删除。

实例清单和最近项目保存在用户应用数据目录，并维护原子写入的本地备份。主数据损坏时会自动恢复；诊断页可打开数据目录并复制不含登录令牌的环境摘要。

Windows 官方 ChatGPT App 原生支持 PowerShell，但目前没有面向外部应用公开稳定的“指定独立 Desktop Profile 启动”接口，因此 Windows Alpha 暂不提供自定义 Desktop 多实例。

## 下载与安装

发布目录会生成四种文件：

- `JimiDeck-0.2.0-Alpha-macOS-universal.dmg`
- `JimiDeck-0.2.0-Alpha-macOS-universal.zip`
- `JimiDeck-0.2.0-Alpha-Windows-x64.exe`
- `JimiDeck-0.2.0-Alpha-Windows-x64.zip`

项目目前没有付费的 Apple Developer 或 Windows Code Signing 证书，所以公开包均为无认证发布。下载后请先对照旁边的 `SHA256SUMS` 文件校验哈希。

### macOS

支持 macOS 14 及以上、Apple Silicon 与 Intel Mac。首次启动若被拦截：

1. 按住 Control 点击 `JimiDeck.app`，选择“打开”；
2. 再次确认“打开”；
3. 若仍被拦截，前往“系统设置 → 隐私与安全性 → 仍要打开”。

### Windows

支持 Windows 10/11 x64。SmartScreen 显示“未知发布者”时，只在哈希核对无误后选择“更多信息 → 仍要运行”。

使用 CLI 实例前需确保 `codex` 命令已加入 PATH；Desktop 入口需要安装官方 ChatGPT Windows App。

## 参考项目与第三方许可

macOS 的 Profile 隔离 Core 参考并内置了固定版本的 [`Ducksss/codex-profiles`](https://github.com/Ducksss/codex-profiles) `v0.7.0`，SHA-256：

```text
d85f8a3cb479578d7d8cb436daec6c57f36b7a9a139558ed756501896ea58b2b
```

其 MIT License 位于 `THIRD_PARTY_LICENSES/`。JimiDeck 的产品界面不展示上游项目宣传信息，所有上游调用均经过独立 Adapter。

## 本地开发

macOS：

```bash
xcodegen generate
xcodebuild -project JimiDeck.xcodeproj -scheme JimiDeck -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

Windows 外壳：

```bash
cd Windows
npm ci
npm run check
npm start
```

生成发布包：

```bash
./Scripts/package_macos.sh
./Scripts/package_windows.sh
```

Windows 包可以在 macOS 上交叉生成，但发布前仍应在真实 Windows 10/11 x64 机器上做一次安装和启动测试。
