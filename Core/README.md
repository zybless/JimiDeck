# Core runtime

The reviewed `codex-profile` v0.7.0 executable is pinned in this directory as `codex-profile`.

- Upstream tag: `v0.7.0`
- SHA-256: `d85f8a3cb479578d7d8cb436daec6c57f36b7a9a139558ed756501896ea58b2b`
- Source: `https://github.com/Ducksss/codex-profiles`

During development JimiDeck can fall back to `/opt/homebrew/bin/codex-profile` or `/usr/local/bin/codex-profile` if the bundled resource is absent. The UI never invokes shell commands directly; every Core operation goes through `CodexProfilesCLIAdapter`.
