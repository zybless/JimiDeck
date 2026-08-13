# Compatibility runtime

This directory contains the macOS profile runtime used by `CodexProfilesCLIAdapter`.

| Field | Value |
| --- | --- |
| Upstream | [`Ducksss/codex-profiles`](https://github.com/Ducksss/codex-profiles) |
| Version | `v0.7.0` |
| SHA-256 | `d85f8a3cb479578d7d8cb436daec6c57f36b7a9a139558ed756501896ea58b2b` |
| License | MIT |

Development builds may use `/opt/homebrew/bin/codex-profile` or `/usr/local/bin/codex-profile` when the bundled resource is unavailable. UI code does not call the runtime directly; argument mapping and error translation stay in the adapter.

See the repository [Third-Party Notices](../THIRD_PARTY_NOTICES.md) for distribution details.
