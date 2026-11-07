---
name: secret-scan
description: Scan the DomWorld repo for leaked secrets (Roblox cookies, API keys, tokens, private keys, webhooks, credentialed URLs) in the working tree, staged changes, or git history. Use before every commit, push, tag or release, after adding config or lobby-service code, and whenever a key, token or .env is mentioned. Not for license or asset checks.
---

# secret-scan

The original project removed its lobby-service key from git; DomWorld must never contain anyone's keys, including ours.

## Run

```bash
# tracked files + untracked files not ignored
python3 .agents/skills/secret-scan/scripts/secret_scan.py

# only what is about to be committed
python3 .agents/skills/secret-scan/scripts/secret_scan.py --staged

# full git history (slower; run before the first public push and before releases)
python3 .agents/skills/secret-scan/scripts/secret_scan.py --history
```

Exit `0` = clean, `1` = findings. Output never prints the full secret, only a masked preview, file and line.

## Rules

1. Real secrets live only in environment variables or git-ignored files (`.env`, `*.key`, `secrets/`). Commit only `.env.example` with fake values.
2. `.gitignore` must ignore `.env`, `*.key`, `secrets/`, `.DS_Store`. The script checks this.
3. If a real secret was ever committed: **it is compromised**. Rotate/revoke it first, then remove it from history (e.g. `git filter-repo`), then force-push only after telling the human. Rewriting a public history is destructive, so confirm before doing it.
4. Never paste a secret into chat, logs, docs, or issue text.
5. Placeholders (`YOUR_...`, `changeme`, `example`, `xxxx`) are fine.

## False positives

If a hit is clearly a placeholder or a test fixture, change it to an obvious placeholder (`YOUR_API_KEY`) instead of weakening the script.

## Report format

For each finding: masked value, file:line, type, action taken (removed / rotated / moved to env). End with the script's exit status.
