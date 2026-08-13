# Security Policy

## Supported versions

Security fixes are applied to the latest release line and `main`.

| Version | Supported |
| --- | --- |
| 0.2.x | Yes |
| 0.1.x | No |

## Reporting a vulnerability

Please use [GitHub's private vulnerability reporting](https://github.com/zybless/JimiDeck/security/advisories/new). Include the affected platform and version, reproduction steps, expected impact, and any suggested mitigation. Do not include active credentials or publish a working exploit in a public issue.

You should receive an acknowledgement within seven days. Confirmation and release timing depend on severity and reproducibility. Coordinated disclosure is appreciated.

JimiDeck separates profile state into local directories, but it is not a security sandbox. Anyone who can read the same operating-system account may be able to access those files.

---

# 安全策略

## 支持范围

安全修复会应用到最新发布分支和 `main`。

| 版本 | 是否支持 |
| --- | --- |
| 0.2.x | 是 |
| 0.1.x | 否 |

## 报告漏洞

请使用 [GitHub 私密漏洞报告](https://github.com/zybless/JimiDeck/security/advisories/new)，并提供受影响的平台与版本、复现步骤、预期影响及可能的缓解方式。请勿提交仍然有效的凭据，也不要在公开 Issue 中发布可直接利用的代码。

项目通常会在七天内确认收到报告。确认与修复发布时间取决于问题严重程度和可复现性，感谢配合协调披露。

JimiDeck 会将配置状态存放在不同的本地目录中，但这不等同于安全沙箱。能够读取同一操作系统账户文件的用户，也可能读取这些数据。
