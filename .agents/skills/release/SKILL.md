---
name: release
description: Cut a DomWorld release - run all audits, update CHANGELOG and version, tag, push and create the GitHub release so the public source matches what players run (AGPL section 13). Use ONLY when the human explicitly asks to release, tag, publish a version or prepare a Roblox publish. Never run implicitly.
---

# release

Explicit-only skill (`allow_implicit_invocation: false`). It creates tags and releases, so run it only on request.

## Preconditions

- `gh auth status` succeeds and the working tree is clean (`git status --porcelain` is empty).
- You are on `main` (or a release branch that will be merged first).

## Steps

1. **Audits** (all must exit 0; stop and fix otherwise):
   ```bash
   python3 .agents/skills/license-audit/scripts/license_audit.py
   python3 .agents/skills/asset-audit/scripts/asset_audit.py
   python3 .agents/skills/secret-scan/scripts/secret_scan.py
   python3 .agents/skills/secret-scan/scripts/secret_scan.py --history
   ```
2. **Quality**: Rojo build for `release.project.json`, Selene, StyLua check, tests (see `roblox-luau-rojo`). If a step cannot run, say so in the release notes; do not claim it passed.
3. **Version**: choose the next semantic version (`vMAJOR.MINOR.PATCH`). Update the version constant used by the in-game credits screen, if one exists.
4. **CHANGELOG.md**: add a dated entry listing user-visible changes, license-relevant changes (notices, assets replaced) and any DataStore migration.
5. **Source link consistency**: the repo URL must be identical in the in-game credits, `README.md`, `NOTICE.md` and `docs/ROBLOX_DESCRIPTION.md`.
6. **Commit, tag, push**:
   ```bash
   git add -A && git commit -m "release: vX.Y.Z"
   git tag -a vX.Y.Z -m "DomWorld vX.Y.Z"
   git push origin main --follow-tags
   gh release create vX.Y.Z --generate-notes --title "DomWorld vX.Y.Z"
   ```
7. **Build artifact**: attach the release `.rbxl` only if it contains no secrets.
8. **Hand-off to the human** (you cannot do this): publish the place in Roblox Studio from that exact tag and make sure the game description contains the text from `docs/ROBLOX_DESCRIPTION.md`.

## Never

- Force-push or rewrite published tags or history without explicit approval.
- Publish if any audit fails.
- Put real keys, or asset IDs that are not ours, into the release.

## Report format

Version, tag, release URL, audit results (exit codes), anything that could not be verified.
