# Release artifacts

Release staging produces four end-user packages and two checksum manifests under `dist/`.

| Platform | Package | Architecture |
| --- | --- | --- |
| macOS | DMG | Universal |
| macOS | ZIP | Universal |
| Windows | NSIS installer | x64 |
| Windows | Portable ZIP | x64 |

Build and stage the artifacts with:

```bash
Scripts/package_macos.sh
Scripts/package_windows.sh
node Scripts/stage_release.mjs
```

Before publishing, run the test suites, verify each SHA-256 manifest, install both standard packages on clean systems, and open both portable archives. Version numbers in `project.yml`, `Windows/package.json`, the website, and release notes should match.

Version 0.2.0 Alpha artifacts are unsigned. The release page and download page should retain the unsigned-build notice. Current Windows support covers independent Codex CLI profiles and the default ChatGPT Desktop entry.
