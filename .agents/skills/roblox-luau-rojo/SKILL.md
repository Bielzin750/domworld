---
name: roblox-luau-rojo
description: Conventions, commands and security rules for DomWorld's Luau code built with Rojo (build, Selene lint, StyLua format, tests, server-authoritative RemoteEvent design, DataStore safety, lobby service). Use whenever editing Luau under src/, project files, remotes, game logic, data persistence, or the lobby service, or when asked to build/test/lint.
---

# roblox-luau-rojo

DomWorld is a real-time territorial strategy game in Luau (about 90% of the code), synced with Rojo, with a separate lobby service (Python/TypeScript). Inspect the repo first; do not assume tools that are not present.

## Detect, don't assume

Before running anything, check which of these exist and use what the repo actually uses:

- `default.project.json`, `release.project.json` (Rojo), `selene.toml` (Selene), `stylua.toml` (StyLua), `wally.toml` (Wally), the test folder (`testes/` or `tests/`) and its runner (TestEZ, Jest-Lua, or custom).
- Write the discovered commands into `AGENTS.md` under "Commands" so they are not rediscovered each time.

## Typical commands (verify availability first)

```bash
rojo build default.project.json -o build/DomWorld.rbxl
rojo build release.project.json -o build/DomWorld-release.rbxl
selene src
stylua --check src
stylua src
```

For tests, use the runner the repo already defines. If tests need Roblox Studio or a headless runner that is not installed, say so instead of faking a pass.

## Code rules

- Keep the existing structure (shared/server/client split) and naming. Do not refactor systems unless asked.
- Use `--!strict` where the file already does; do not downgrade type checking to make an error go away.
- No `loadstring`, no `getfenv`/`setfenv`, no `require` of asset IDs you do not own.
- Keep old copyright headers; add `-- Modified for DomWorld, <YEAR> - see git history.` to substantially modified files.
- The game name in UI strings comes from one constant module (for example `GameInfo.Name = "DomWorld"`), never hard-coded in many places.

## Security rules (the client is hostile)

Read `references/security.md` before touching any RemoteEvent/RemoteFunction, purchase flow, or data persistence. Summary:

1. The server owns all game state. The client only sends intent (for example "attack tile X"), never results (for example "I won", "give me +100").
2. Validate every remote argument on the server: type, range, ownership, cooldown, adjacency, and that the player is in the right match state.
3. Rate-limit remotes per player. Drop and log abusive calls.
4. Wrap DataStore and HTTP calls in `pcall` with retry and backoff; never block the game loop on them; handle shutdown with `BindToClose`.
5. Never trust names or values sent by the client for identity or purchases; use the server's `Player` object and `MarketplaceService` receipts (`ProcessReceipt` must be idempotent).
6. Secrets (lobby service key, Open Cloud keys) never live in place files or client-visible modules. Use server-only configuration and environment variables for external services.

## Lobby service

- Keep its config in environment variables; document them in `.env.example`.
- Validate every inbound request (auth, schema, size). Return generic errors.
- Pin and review dependencies for AGPL compatibility; record them in `docs/DEPENDENCIES.md`.

## Definition of done for a Luau change

- Builds with Rojo, passes Selene and the format check, and tests pass (or you explicitly state which could not be run and why).
- New remotes follow `references/security.md`.
- `license-audit` still passes if you touched UI, credits or names.
