---
name: license-audit
description: Audit DomWorld's compliance with the AGPL v3 license and its additional terms (OpenFront copyright notice, source-code offer, attribution, naming). Use before any release or push to main, after renaming or touching UI/credits/license files, or when asked "are we compliant?". Do not use for secrets (secret-scan) or asset ownership (asset-audit).
---

# license-audit

DomWorld is a derivative of `lukechatton/roworld`, which carries the GNU AGPL v3 plus additional terms (Section 7) in its `LICENSE`. This skill verifies we still comply.

## Run

```bash
python3 .agents/skills/license-audit/scripts/license_audit.py
```

Exit code `0` = all checks pass. Exit code `1` = at least one FAIL. Warnings (WARN) do not fail the run but must be read.

## What the script checks

1. `LICENSE` exists, still contains the AGPL v3 text and the "ADDITIONAL TERMS" section, and still requires the `© OpenFront and Contributors` notice.
2. `NOTICE.md` exists and mentions DomWorld, the origin (RoWorld / Luke Chatton), OpenFront, the real repo URL, and the modification date.
3. `LICENSE-ASSETS` exists (license for the new art).
4. `README.md` mentions AGPL and the origin.
5. No leftover placeholders (`<URL_DO_MEU_FORK>`, `<ANO>`).
6. The Luau code shows `© OpenFront and Contributors` to the player, mentions AGPL, and exposes the DomWorld repository URL (in-game credits / about screen).
7. "RoWorld" / "OpenFront" appear only as attribution (lines with words like "based on", "©", "derived", "not affiliated"), never as the game's name, in code and UI strings.
8. File or folder names that still use the old names (WARN).

## When something fails

- Fix the root cause, then re-run until exit code `0`.
- Never "fix" a failure by editing `LICENSE`, deleting the OpenFront notice, or weakening the script.
- If a failure is a false positive (e.g. a legitimate attribution line without a keyword), improve the attribution wording in the file, or record the decision in `docs/DECISIONS.md`. Do not silence the check.

## Manual checks the script cannot do

- Open the game menu and confirm "About / License / Credits" is reachable in one click and the OpenFront notice is visible without opening submenus.
- Confirm the source link in the game, `README.md`, `NOTICE.md` and the Roblox description all point to the same repository and that the published tag matches what is running (AGPL Section 13).
- Confirm modified files kept their original copyright headers.

## Report format

Reply with: PASS/FAIL per check, the exact files and lines for each failure, and what you changed.
