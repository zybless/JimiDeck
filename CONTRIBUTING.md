# Contributing to JimiDeck

[简体中文](CONTRIBUTING.zh-CN.md)

Thank you for helping improve JimiDeck. Small, reviewable changes with a clear reason are the easiest to merge.

## Before opening an issue

- Search existing issues for the same behavior.
- Confirm the problem on the latest release or `main`.
- Remove account names, tokens, profile contents, and private file paths from logs or screenshots.
- Use the security reporting process for vulnerabilities.

## Development setup

### macOS

Install Xcode 16 or later and XcodeGen, then run:

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

Install Node.js 22 LTS, then run:

```powershell
cd Windows
npm ci
npm run check
```

## Pull requests

1. Keep a pull request focused on one problem.
2. Add or update tests when behavior changes.
3. Update user-facing documentation for changed behavior or platform support.
4. Do not commit credentials, local profile data, build artifacts, or generated dependency directories.
5. Confirm that the checks above pass before requesting review.

Use imperative, descriptive commit subjects such as `fix(macOS): preserve imported profile metadata`.

## Project boundaries

This repository contains the JimiDeck application and its release tooling. The public website is maintained separately under `site/JimiDeck` in the parent workspace and is not vendored into this repository. `Scripts/check_project_boundaries.sh` enforces that separation.

## Licensing

By contributing, you agree that your contribution is licensed under the repository's [MIT License](LICENSE). Do not submit code or assets that cannot be distributed under compatible terms.
