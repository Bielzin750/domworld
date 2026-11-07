---
name: asset-audit
description: Audit DomWorld's art, audio, models and Roblox asset IDs so nothing from RoWorld, OpenFront or any third party remains. Use after replacing art, before releases, when you see a rbxassetid:// or a file in the art folder, or when asked whether assets are safe to ship. Not for license text (license-audit) or secrets (secret-scan).
---

# asset-audit

Rule of the project: **no asset from the original repository or any third party may remain in DomWorld**. Only original assets in `ativos/domworld/` (or `assets/domworld/`) and Roblox asset IDs owned by the DomWorld account are allowed.

## Run

```bash
python3 .agents/skills/asset-audit/scripts/asset_audit.py
```

Exit `0` = clean. Exit `1` = problems found.

## Inputs this skill relies on

- `docs/OWN_ASSET_IDS.txt`: one Roblox asset ID per line, optional `# comment`. Only IDs uploaded by the DomWorld account belong here. Never add an ID just to silence the script. If you do not know who owns an ID, it is **not** ours.
- `docs/ASSET_MAP.md`: table of `old use -> status -> replacement`.

## What the script checks

1. Every `rbxassetid://<id>` / `asset?id=<id>` in code and config appears in `docs/OWN_ASSET_IDS.txt` (ID `0` is ignored as a placeholder).
2. Files in the art folder live under the `domworld/` subfolder. Anything else is a leftover from the original.
3. No `proprietary/` directory exists.
4. No references to OpenFront or RoWorld CDNs/asset hosts.
5. `ativos/domworld/README.md` exists and states the art license (CC BY-SA 4.0), and `LICENSE-ASSETS` exists.

## How to fix findings

- Unknown asset ID: replace with a placeholder (`rbxassetid://0`) or an original asset, then record it in `docs/ASSET_MAP.md`.
- Leftover file: delete it from the working tree and replace it with an original (simple geometric shapes, flat colors, procedural textures, generated tones). Do not trace, recolor or "slightly modify" the original art, as that is still a derivative of it.
- Never create art that imitates logos, characters or marks of other games or brands. The DomWorld logo is an original geometric mark.

## Report format

List each finding (file:line or path), the decision (replaced/removed/kept-with-reason), and the final script result.
