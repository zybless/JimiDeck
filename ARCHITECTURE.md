# Architecture

This document describes JimiDeck's main components and the boundaries that protect local profile data.

## Components

| Area | macOS | Windows |
| --- | --- | --- |
| User interface | SwiftUI | Electron renderer |
| Application coordination | `AppModel` | Electron main process |
| Persistent metadata | Actor-backed JSON store | Atomic JSON store |
| Profile runtime | `CodexProfilesCLIAdapter` | Native Node.js launcher |
| External processes | `ProcessRunner` | `child_process.spawn` |

The platform implementations share the same product model but use native launch and storage conventions. They do not share a cross-platform runtime.

## Profile model

A profile contains a stable identifier, display name, target kind, and creation metadata. The display name is for people; the identifier is safe to use in directory names and process arguments. Default Desktop and CLI entries represent the operating system's existing environment and are not deletable.

Named profiles use independent data directories:

- ChatGPT Desktop on macOS uses a dedicated `--user-data-dir` through the compatibility runtime.
- Codex CLI uses a dedicated `CODEX_HOME`.

This prevents normal application state from being mixed between profiles. It does not prevent another process running as the same operating-system user from reading those files.

## Storage

JimiDeck stores its own metadata in the user's application-support directory. Writes use a temporary file followed by replacement so an interrupted save does not leave a partially written JSON document. Recovery keeps the last readable state when possible and surfaces actionable errors in the UI.

Authentication state remains in the profile directories owned by ChatGPT Desktop or Codex. JimiDeck does not parse tokens or copy credentials between profiles.

## Launch flow

1. The app validates the selected profile and required executable.
2. CLI launches resolve a project directory chosen by the user or a recent-project entry.
3. Arguments and environment variables are passed as structured process values rather than assembled shell commands.
4. Launch failures return to the app as typed errors with recovery guidance.

## Import and deletion

On macOS, import reads profile records exposed by the bundled compatibility runtime and creates corresponding JimiDeck metadata without duplicating profile contents. Stable IDs prevent repeated imports from creating duplicates.

Deletion removes JimiDeck metadata and, after confirmation, the associated named profile through the platform runtime. A failed runtime deletion leaves enough metadata to report and retry the operation. Default system entries are never deleted.

## Compatibility runtime

The macOS implementation bundles a reviewed, pinned copy of `codex-profile` and places all calls behind `CodexProfilesCLIAdapter`. The adapter owns argument mapping, output decoding, and error translation so compatibility changes remain isolated from the UI and storage layers. See [Third-Party Notices](THIRD_PARTY_NOTICES.md) for provenance and licensing.

## Repository boundaries

Application source, tests, platform packaging, and release staging live in this repository. The marketing website is maintained in a separate repository. `Scripts/check_project_boundaries.sh` rejects common website source and output paths if they appear here.
