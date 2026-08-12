# JimiDeck 产品需求文档（PRD）v2

> **状态**：可直接交给 Codex 执行  
> **平台**：macOS 优先  
> **产品名**：JimiDeck（暂定）  
> **核心依赖**：`Ducksss/codex-profiles`  
> **核心定位**：Codex 多实例 / 多 Profile 管理器  
> **关键修订**：Desktop Profile 与 CLI Profile 的登录态彼此独立，因此 **Desktop 与 CLI 必须在“创建实例”阶段就确定类型，不能把它们视为同一个 Profile 的两种启动方式。**

---

# 0. 一句话定义

JimiDeck 是一个原生 macOS Codex 多实例管理器。

用户可以创建任意数量的 Codex 实例，每个实例在创建时明确选择：

- **Desktop 实例**：使用官方 ChatGPT/Codex Desktop GUI；
- **CLI 实例**：使用 Codex CLI。

两种实例拥有不同的本地认证状态、运行方式和交互流程。

JimiDeck 本身不实现 Codex，不修改官方 ChatGPT Desktop，不重写 `codex-profiles`，只负责：

> **创建、展示、启动、管理多个独立 Codex 实例。**

---

# 1. 背景

现有使用场景存在以下问题：

1. 官方 ChatGPT/Codex Desktop 不方便长期保持多个账号独立登录；
2. 多账号之间频繁退出、重新登录、验证非常麻烦；
3. `codex-profiles` 已经可以通过不同 Profile 启动多个独立 Desktop 环境；
4. `codex-profiles` 同时支持 Codex CLI；
5. 但 `codex-profiles` 是命令行工具，普通用户操作成本高；
6. Desktop 与 CLI 的认证状态不是同一份；
7. 因此“一个 Profile 里随时选 GUI 或 CLI”的设计是错误的。

本产品的目标是：

> 在 `codex-profiles` 之上增加一个真正适合日常使用的可视化管理层。

---

# 2. 最重要的产品模型

旧模型：

```text
Profile
└── 选择 Desktop / CLI
```

**禁止采用。**

正确模型：

```text
JimiDeck Instance
│
├── Desktop Instance
│   ├── 独立 Profile
│   ├── 独立 Desktop 登录态
│   ├── 独立 Electron user-data
│   └── 点击直接启动官方 Desktop
│
└── CLI Instance
    ├── 独立 Profile
    ├── 独立 CLI 登录态
    ├── 独立 CODEX_HOME
    └── 点击后每次选择项目，再启动 Terminal
```

也就是说：

> **Desktop 和 CLI 是两种不同的 Codex 实例类型，而不是同一个实例的两种打开方式。**

---

# 3. 为什么必须区分 Desktop 与 CLI

`codex-profile doctor` 已明确给出：

```text
CLI scope: Codex commands only; Desktop and CLI accounts must be verified separately
```

所以即使底层 Profile 名相同：

```text
plus2 → Desktop
```

可能登录账号 A；

但：

```text
plus2 → CLI
```

可能是未登录、账号 B 或另一套 CLI 认证状态。

因此：

- Desktop 登录成功不等于 CLI 登录成功；
- CLI 登录成功不等于 Desktop 登录成功；
- 两者不能在产品层面视为同一个账号实例；
- 用户创建实例时必须先确定类型。

---

# 4. 产品目标

1. 原生 macOS GUI；
2. 管理多个独立 Codex 实例；
3. 支持 Desktop 实例；
4. 支持 CLI 实例；
5. 实例创建时确定类型；
6. 类型创建后不可直接转换；
7. 用户可创建 50+ 实例；
8. 首页极简；
9. 卡片本身即启动入口；
10. Desktop 点击直接启动；
11. CLI 点击后每次都选择项目；
12. 不绑定项目；
13. 不收藏项目；
14. 不记住项目；
15. 不做账号自动轮换；
16. 不做额度规避；
17. 不做账号风控规避；
18. GUI 与 `codex-profiles` 内核彻底解耦；
19. 上游 Core 可替换、升级、回滚；
20. 不读取、不上传用户 Token。

---

# 5. 非目标

禁止自行加入以下功能：

- Profile 创建后再切换 Desktop / CLI；
- “首次点击后选择 Desktop/CLI 并记住”；
- `preferredLaunchMode`；
- 收藏项目；
- Profile 绑定项目；
- 默认项目；
- 记住上次项目并自动打开；
- 项目标签；
- 项目分组；
- 首页“打开”按钮；
- 首页“删除”按钮；
- 首页“编辑”按钮；
- 复杂 Dashboard；
- 额度统计图；
- 自动账号轮换；
- 自动撞限额换账号；
- 账号池；
- 防关联；
- 防封号；
- 风控规避；
- 自动登录；
- 自动绕过验证码；
- 后端服务器；
- 云账号系统；
- 数据库；
- 远程同步；
- 自行分发 OpenAI 官方 ChatGPT Desktop 二进制；
- 重写 `codex-profiles` 核心逻辑。

---

# 6. 产品命名

当前推荐：

```text
JimiDeck
```

对外描述：

```text
JimiDeck
Codex Instance Manager
```

或者：

```text
JimiDeck
Codex Profile Manager
```

不要直接叫：

```text
JimiCodex
```

避免看起来像 OpenAI 官方 Codex 客户端。

---

# 7. 上游内核

核心项目：

```text
Ducksss/codex-profiles
```

JimiDeck 不重新实现其核心能力。

推荐架构：

```text
SwiftUI
   ↓
JimiDeck Service Layer
   ↓
CoreAdapter
   ↓
codex-profile 原版内核
   ↓
官方 ChatGPT Desktop / Codex CLI
```

---

# 8. GUI 与 Core 解耦

所有上游调用只能经过统一 Service。

推荐：

```text
CodexInstanceService
├── listInstances()
├── createDesktopInstance()
├── createCLIInstance()
├── launchDesktopInstance()
├── launchCLIInstance()
├── removeInstance()
├── renameInstance()
├── getStatus()
├── doctor()
└── getCoreVersion()
```

底层：

```text
CodexProfilesCLIAdapter
```

页面层禁止直接执行 shell。

---

# 9. 实例数据模型

建议：

```text
CodexInstance {
    id
    displayName
    type
    profileId
    createdAt
    lastUsedAt
}
```

其中：

```text
type = desktop | cli
```

---

# 10. 底层 Profile ID 必须区分类型

用户可以创建两个同名实例：

```text
Work
Desktop

Work
CLI
```

UI 允许同名，但底层 ID 不允许冲突。

推荐：

```text
desktop:
jimideck-desktop-<uuid>

cli:
jimideck-cli-<uuid>
```

例如：

```text
Work / Desktop
→ jimideck-desktop-a82f...

Work / CLI
→ jimideck-cli-c4d1...
```

用户正常情况下不需要看到内部 ID。

---

# 11. 创建实例流程

首页右上角：

```text
+
```

点击后第一步必须选择类型。

---

## 11.1 创建页面

```text
创建 Codex

选择类型

┌────────────────────┐
│  Desktop           │
│  图形界面 Codex    │
└────────────────────┘

┌────────────────────┐
│  CLI               │
│  终端 Codex        │
└────────────────────┘
```

用户点击其中一个以后进入名称输入。

例如：

```text
名称：Work
```

然后创建。

---

## 11.2 类型创建后固定

创建完成：

```text
Desktop
```

就永远是 Desktop Instance。

创建完成：

```text
CLI
```

就永远是 CLI Instance。

不要提供：

```text
转成 CLI
转成 Desktop
```

如果用户两种都需要：

> 创建两个独立实例。

---

# 12. 首页 UI

首页只做最核心的一件事：

> 找到 Codex，然后点它。

示意：

```text
JimiDeck                              +   ⚙︎


Codex

┌──────────────────────────────────────┐
│ 🖥  Main                             │
│     Desktop                          │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│ >_  Work                             │
│     CLI                              │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│ 🖥  Backup                           │
│     Desktop                          │
└──────────────────────────────────────┘
```

---

# 13. Desktop / CLI 图标必须明显不同

Desktop：

```text
macwindow / display
```

CLI：

```text
terminal
```

优先使用 macOS / SF Symbols。

不要依赖两套不同 OpenAI Logo 表达类型。

目标：

> 用户不看副标题，也能大致知道这是 GUI 还是 CLI。

---

# 14. 首页卡片行为

## Desktop Instance

点击：

```text
Desktop Instance
↓
直接启动对应 Desktop Profile
↓
官方 ChatGPT/Codex Desktop
```

不弹项目。

不弹启动方式。

不弹额外确认。

---

## CLI Instance

点击：

```text
CLI Instance
↓
项目选择器
↓
用户选择本次项目
↓
Terminal
↓
启动对应 Codex CLI
```

每次都走项目选择。

---

# 15. 首页禁止出现

不要显示：

```text
[打开]
[删除]
[编辑]
```

整个卡片就是“打开”。

删除、重命名、批量管理属于设置 / 管理页。

---

# 16. 运行状态

卡片可用简单状态：

```text
● 运行中
○ 未运行
```

不要把首页做成监控面板。

---

# 17. Desktop 实例

Desktop 实例底层调用：

```bash
codex-profile app <profile>
```

其作用：

- 使用官方 ChatGPT Desktop；
- 使用独立 Desktop local state；
- 使用独立 Electron user-data；
- 多个 Named Desktop Profile 可以同时运行；
- 不修改官方 App；
- 不 clone 官方 App；
- 不 patch；
- 不 re-sign。

---

# 18. Desktop 首次登录

新 Desktop Instance 第一次打开时：

```text
JimiDeck
↓
codex-profile app instance-x
↓
打开一个新的独立 Desktop 环境
↓
用户在官方 GUI 中自行登录
```

JimiDeck：

- 不填写账号密码；
- 不保存账号密码；
- 不处理验证码；
- 不读 Token；
- 不判断具体登录的是谁。

以后同一实例继续使用同一 Desktop local state。

---

# 19. CLI 实例

CLI Instance 对应独立 CLI Profile。

CLI 的登录状态与 Desktop 独立。

新 CLI Instance 第一次运行时，如未登录：

> 由 Codex CLI 自身正常进入认证流程。

JimiDeck 不替用户认证。

---

# 20. CLI 每次必须选择项目

这是硬性产品规则。

不能：

```text
Profile → 自动进入上次项目
```

不能：

```text
Profile → 绑定固定项目
```

正确流程：

```text
CLI Instance
↓
每次打开项目选择器
↓
最近项目 / 打开其他项目
↓
选择
↓
Terminal
↓
Codex CLI
```

---

# 21. CLI 项目选择器

参考 JetBrains / IDEA 的简洁思路。

只保留：

1. 最近项目
2. 打开其他项目

示意：

```text
选择项目

最近项目

JimiShot
~/Projects/JimiShot

JimiLatex
~/Projects/JimiLatex

jimidou-web
~/Projects/jimidou-web

backend
~/Projects/backend


[ 打开其他项目… ]
```

---

# 22. 最近项目

规则：

- 全局列表；
- 与实例无关；
- Desktop 实例不需要；
- CLI 实例共享；
- 按最近使用时间排序；
- 点击后立即启动；
- 不再出现第二个确认按钮。

数据模型：

```text
RecentProject {
    path
    displayName
    lastOpenedAt
}
```

绝对不要加入：

```text
profileId
```

---

# 23. 打开其他项目

点击：

```text
打开其他项目…
```

调用 macOS 原生目录选择器。

用户选择目录后：

```text
立即启动对应 CLI Instance
```

并加入最近项目列表。

---

# 24. 禁止的项目功能

绝对不要实现：

```text
收藏项目
项目标签
项目分组
Profile 绑定项目
默认项目
记住本次项目
下次自动打开项目
Profile 专属最近项目
```

---

# 25. CLI 终端流程

MVP 只需要支持：

```text
Terminal.app
```

流程：

```text
选择项目目录
↓
打开 Terminal.app
↓
cd <project>
↓
启动对应 Codex CLI Profile
```

后续可支持：

- iTerm2
- Warp
- Ghostty
- Kitty

但不是第一版必需。

---

# 26. default 的重新定义

这里必须与旧 PRD 不同。

因为 Desktop default 与 CLI default 的认证并不是同一份。

JimiDeck 不应该把它们合并成一个模糊的：

```text
Default
```

推荐区分为两个系统实例：

```text
🖥 Default Desktop
>_ Default CLI
```

---

# 27. Default Desktop

对应：

```text
官方 Desktop stock session
```

用户直接双击官方 ChatGPT Desktop，仍进入这一套环境。

JimiDeck 不破坏它。

底层仍使用 default Desktop。

---

# 28. Default CLI

对应：

```text
~/.codex
```

下的默认 CLI 环境。

注意：

> Default CLI 登录状态不等于 Default Desktop 登录状态。

两者必须作为两个不同实体展示。

---

# 29. 默认实例展示规则

如果检测到 Desktop：

```text
显示 Default Desktop
```

如果检测到 CLI：

```text
显示 Default CLI
```

如果二者都有：

```text
两个都显示
```

例如：

```text
🖥 Default Desktop
   Desktop

>_ Default CLI
   CLI
```

---

# 30. 环境检测

必须分别检测：

```text
ChatGPT Desktop
Codex CLI
```

---

# 31. 四种环境

| Desktop | CLI | 可创建实例 |
|---|---|---|
| ✅ | ✅ | Desktop + CLI |
| ✅ | ❌ | Desktop |
| ❌ | ✅ | CLI |
| ❌ | ❌ | 无，进入安装引导 |

如果 Desktop 内部自带可用 Codex CLI：

> 可视为 CLI capability 存在，但必须由 Core 检测结果确认。

---

# 32. 当前已验证环境示例

实际 `doctor` 已出现：

```text
Desktop product: ChatGPT
Desktop app: /Applications/ChatGPT.app
CLI: /Applications/ChatGPT.app/Contents/Resources/codex
CLI scope: Codex commands only; Desktop and CLI accounts must be verified separately
```

因此：

- Desktop 能力存在；
- CLI 能力也存在；
- CLI 来自 ChatGPT.app bundled Codex；
- 二者认证状态独立。

---

# 33. 无运行环境时

如果 Desktop 与 CLI 都不存在：

```text
JimiDeck

需要安装至少一种 Codex 运行环境

ChatGPT Desktop
用于图形界面
[前往 OpenAI 官网]

Codex CLI
用于终端
[查看官方安装方式]

[重新检测]
```

---

# 34. 下载策略

ChatGPT Desktop：

> 只指向 OpenAI 官方来源。

不要在：

```text
jimidou.com
自建 CDN
OSS/COS
GitHub Release
```

自行镜像或重新分发官方 ChatGPT `.dmg`，除非未来获得明确授权。

JimiDeck 可以：

- 打开官方页面；
- 提供说明；
- 检测是否安装；
- 安装后重新检测。

---

# 35. Core 自带策略

用户不应该被要求：

```text
先 brew install codex-profile
```

正式产品应自带经过验证的 `codex-profiles` Core。

用户看到的是：

```text
JimiDeck
```

而不是：

```text
一个 codex-profile GUI wrapper
```

---

# 36. Core 目录建议

```text
JimiDeck.app
├── GUI
└── 内置初始 Core
```

首次运行可复制到：

```text
~/Library/Application Support/JimiDeck/
└── cores/
    ├── 0.7.0/
    ├── 0.8.0/
    └── current
```

正式版本不要运行时修改已签名 App bundle 内部文件。

---

# 37. Core 更新

目标：

```text
JimiDeck GUI
长期稳定

codex-profiles Core
可独立升级
```

流程：

```text
发现新版本
↓
下载
↓
校验
↓
兼容测试
↓
切换 current
```

失败：

```text
回滚旧版本
```

---

# 38. 上游代码处理原则

尽量保持：

```text
Ducksss/codex-profiles
```

源码原样。

推荐：

- Git Submodule；
- Git Subtree；
- CI 自动同步。

不要大量改上游源码后再混入主工程。

---

# 39. MIT License

`codex-profiles` 使用 MIT License。

JimiDeck 必须保留：

- 原作者版权声明；
- MIT License 文本。

About：

```text
Core powered by codex-profiles
Licensed under the MIT License
```

JimiDeck 自己无需因此开源。

---

# 40. Profile 管理页

危险操作只放这里。

支持：

- 查看全部实例；
- 重命名显示名；
- 删除；
- 多选；
- 批量删除；
- 查看类型；
- 查看底层 Profile ID；
- 查看运行状态。

---

# 41. 删除

删除必须二次确认。

例如：

```text
删除 “Work”？

这将删除该 Codex 实例的本地 Profile 数据和登录状态。

不会删除你的项目代码。

取消       删除
```

---

# 42. 删除绝不能影响项目目录

必须保证：

```text
删除 Codex Instance
≠
删除代码仓库
```

禁止删除：

- 用户项目目录；
- Git 仓库；
- 工作区源码。

---

# 43. 实例数量

支持：

```text
50+
```

甚至更多。

首页使用：

```text
LazyVStack / LazyGrid
```

保证大量 Profile 时仍流畅。

---

# 44. 同时运行数量

不限制用户保存多少实例。

但不要提供：

```text
全部启动
```

因为 Desktop 本质是多个 Electron/Chromium 环境。

同时启动几十个可能占用大量内存。

---

# 45. 本地隔离边界

Profile 隔离代表：

- CODEX_HOME 独立；
- Desktop local state 独立；
- Electron user-data 独立；
- sessions 独立；
- cache 独立；
- 登录态独立。

不代表：

- OS 隔离；
- 设备隔离；
- IP 隔离；
- 服务端匿名；
- 防账号关联；
- 防封号。

产品描述不得误导。

---

# 46. 安全原则

JimiDeck：

- 不读取账号密码；
- 不保存账号密码；
- 不解析 auth token；
- 不上传 auth.json；
- 不上传登录态；
- 不做代理；
- 不做账号池；
- 不做自动登录；
- 不做自动验证码；
- 不做自动账号轮换。

---

# 47. UI 风格

目标：

- 原生 macOS；
- SwiftUI；
- 极简；
- 低干扰；
- 少按钮；
- 不做“AI 生成后台面板”。

首页核心：

```text
卡片列表
+
设置
```

即可。

---

# 48. 推荐技术栈

```text
Swift
SwiftUI
Foundation
Foundation.Process
```

本地数据：

优先：

```text
UserDefaults / JSON
```

如确有必要再用 SwiftData。

不需要：

- SQLite；
- MySQL；
- 后端；
- 云服务。

---

# 49. 推荐目录结构

```text
JimiDeck/
│
├── App/
│   ├── Views/
│   ├── Models/
│   ├── Components/
│   └── Settings/
│
├── Services/
│   ├── CodexInstanceService.swift
│   ├── RecentProjectsService.swift
│   └── EnvironmentService.swift
│
├── CoreAdapter/
│   └── CodexProfilesCLIAdapter.swift
│
├── Upstream/
│   └── codex-profiles/
│
├── Resources/
│
├── Tests/
│
└── THIRD_PARTY_LICENSES/
```

---

# 50. 错误模型

统一错误：

```text
CoreNotFound
CoreIncompatible
DesktopNotInstalled
CLINotInstalled
DesktopLaunchFailed
CLILaunchFailed
ProfileAlreadyExists
ProfileNotFound
InvalidProfileName
ProjectPathMissing
PermissionDenied
UnknownCoreError
```

UI 不直接显示 shell 原始错误作为唯一提示。

---

# 51. 环境诊断页

设置 → 诊断：

```text
JimiDeck                正常
Core                    0.7.0
ChatGPT Desktop         已安装
Desktop Path            /Applications/ChatGPT.app
Codex CLI               已安装
CLI Source              Desktop bundle
Codex CLI Version       ...
Profile Storage         正常
```

支持：

```text
重新检测
复制诊断信息
```

必须脱敏。

---

# 52. 设置页面

建议：

```text
设置

Profile
├── 实例管理
└── 批量管理

终端
└── 默认 Terminal

运行环境
├── ChatGPT Desktop
├── Codex CLI
└── 重新检测

Core
├── Core 版本
├── 检查更新
└── 回滚

高级
├── 诊断
└── 日志

关于
├── JimiDeck
├── codex-profiles
└── Third Party Licenses
```

不要再存在：

```text
启动偏好
Desktop / CLI 选择
重置启动模式
```

因为实例类型创建时已经固定。

---

# 53. MVP

第一版必须：

- SwiftUI macOS App；
- Core Adapter；
- Core 内置；
- 环境检测；
- Default Desktop；
- Default CLI；
- Desktop / CLI 两种实例类型；
- `+` 创建；
- 创建时选择类型；
- 名称输入；
- 首页列表；
- 类型图标；
- 点击 Desktop 直接打开；
- 点击 CLI 显示项目选择器；
- 最近项目；
- 打开其他项目；
- Terminal.app 启动；
- Profile 管理；
- 删除确认；
- 基础诊断；
- MIT License。

---

# 54. v0.2

可增加：

- 实例搜索；
- 最近使用排序；
- 更可靠的运行状态；
- 已运行实例聚焦；
- 多终端支持；
- Core 在线更新；
- Core 回滚；
- 更好的 doctor 展示；
- 日志页面。

---

# 55. v1.0

可增加：

- 签名；
- notarization；
- DMG；
- Sparkle 自动更新；
- GitHub Actions；
- 上游自动同步；
- Core 兼容测试；
- 自动回滚；
- 正式官网；
- 完整文档。

---

# 56. 不建议第一版加入

- CC Switch 深度集成；
- Provider 管理；
- 国产模型配置 GUI；
- API Key 管理；
- 额度显示；
- 自动账号切换；
- 自动模型切换；
- 云同步。

先把：

> **多 Codex 实例 + Desktop / CLI 清晰分离**

做好。

---

# 57. Desktop 验收标准

- [ ] 可创建 Desktop Instance；
- [ ] 第一次打开出现独立 Desktop local state；
- [ ] 用户可自行登录账号；
- [ ] 关闭后再次打开仍复用该 local state；
- [ ] 不影响系统默认 Desktop；
- [ ] 多个 Desktop Instance 可同时存在；
- [ ] GUI 模式不询问项目。

---

# 58. CLI 验收标准

- [ ] 可创建 CLI Instance；
- [ ] CLI 登录状态独立；
- [ ] Desktop 登录状态不会被误认为 CLI 登录状态；
- [ ] 每次点击 CLI Instance 必须选择项目；
- [ ] 项目选择器只有最近项目和打开其他项目；
- [ ] 不存在收藏；
- [ ] 不存在项目绑定；
- [ ] 不存在默认项目；
- [ ] 选择项目后启动 Terminal.app；
- [ ] Terminal 进入正确项目目录；
- [ ] 使用正确 CLI Profile。

---

# 59. 首页验收标准

- [ ] Desktop 与 CLI 图标明显不同；
- [ ] 卡片整体可点击；
- [ ] 没有“打开”按钮；
- [ ] 没有“删除”按钮；
- [ ] 危险操作不常驻；
- [ ] 50 个实例仍流畅；
- [ ] 用户一眼能看懂实例类型。

---

# 60. 创建流程验收标准

- [ ] 点击 `+` 后首先选择 Desktop / CLI；
- [ ] 用户不能跳过类型；
- [ ] 创建后类型固定；
- [ ] 同显示名的 Desktop/CLI 可共存；
- [ ] 底层 Profile ID 不冲突；
- [ ] 不存在创建后切换类型的入口。

---

# 61. 核心数据模型验收

必须类似：

```text
CodexInstance {
    id
    displayName
    type: desktop | cli
    profileId
    createdAt
    lastUsedAt
}
```

禁止重新引入：

```text
preferredLaunchMode
projectPath
favoriteProjects
```

---

# 62. 关键状态机

## 创建

```text
+
↓
选择 Desktop / CLI
↓
输入名称
↓
创建对应独立 Profile
↓
首页
```

---

## Desktop 点击

```text
Desktop Instance
↓
直接启动
↓
官方 ChatGPT/Codex Desktop
```

---

## CLI 点击

```text
CLI Instance
↓
项目选择器
↓
最近项目 / 打开其他项目
↓
Terminal
↓
cd project
↓
Codex CLI
```

---

# 63. 开发优先级

```text
正确理解 Desktop/CLI 分离
>
不破坏用户现有 Codex
>
Core 可替换
>
启动流程正确
>
UI 简单
>
视觉打磨
>
附加功能
```

---

# 64. 给 Codex 的明确要求

开发前：

1. 阅读 `Ducksss/codex-profiles` 当前 README；
2. 阅读核心 Bash 源码；
3. 确认 `app` 与 `cli` 的本地状态差异；
4. 不假设 Desktop 与 CLI 共享认证；
5. 不自行设计另一套 Profile 引擎。

开发中：

1. 所有 Core 调用经过 Adapter；
2. Desktop 与 CLI 代码路径分开；
3. 类型创建时固定；
4. CLI 每次选择项目；
5. 不做收藏；
6. 不绑定项目；
7. 不做自动轮换；
8. 不读取 Token；
9. destructive 操作必须二次确认；
10. 对 default 行为写回归测试。

---

# 65. 最终产品心智

用户打开 JimiDeck 后：

```text
🖥 Main
>_ Work
🖥 Backup
>_ Local
```

用户不需要理解：

- CODEX_HOME；
- Electron user-data；
- Bash；
- auth.json；
- `codex-profile` 命令。

用户只需要知道：

```text
Desktop 图标
→ 点一下直接打开 GUI
```

以及：

```text
CLI 图标
→ 点一下
→ 选项目
→ Terminal
```

这就是 JimiDeck 的核心体验。

---

# 66. 本次 v2 修订摘要

相较上一版 PRD，本版进行了以下架构级修改：

1. 删除“一个 Profile 同时支持 Desktop / CLI”的设计；
2. 删除首次点击时询问 Desktop / CLI；
3. 删除“记住启动方式”；
4. 删除 `preferredLaunchMode`；
5. `+` 创建实例时必须先选择 Desktop / CLI；
6. Desktop / CLI 创建后类型固定；
7. Desktop 与 CLI 使用不同实例；
8. 底层 Profile ID 增加类型隔离；
9. 首页使用不同图标区分 Desktop 与 CLI；
10. Default Desktop 与 Default CLI 分开展示；
11. CLI 登录态不再假设继承 Desktop；
12. CLI 每次启动仍必须选择项目；
13. 最近项目继续保持全局共享；
14. GUI 不询问项目；
15. 设置中删除“启动偏好”相关功能。

---

# 67. 最终结论

JimiDeck 管理的不是：

> “多个账号 + 一个可切换 GUI/CLI 的 Profile”。

而是：

> **多个独立 Codex 实例。**

每个实例从创建那一刻起就是：

```text
Desktop
```

或者：

```text
CLI
```

这两个类型的认证状态、启动流程和用户体验分别独立。

这是整个产品后续实现必须遵守的最核心架构约束。
