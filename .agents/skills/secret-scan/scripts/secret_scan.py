#!/usr/bin/env python3
"""DomWorld secret scanner (heuristic, standard library only).

Usage:
  python3 secret_scan.py             scan tracked + untracked (non-ignored) files
  python3 secret_scan.py --staged    scan staged changes only
  python3 secret_scan.py --history   scan added lines across all git history
Exit code: 0 = clean, 1 = findings, 2 = not a git repository.
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path.cwd()
PATTERNS = [
    ("Roblox .ROBLOSECURITY cookie", re.compile(r"_\|WARNING:-DO-NOT-SHARE-THIS[^\s\"']{20,}")),
    ("Roblox cookie assignment", re.compile(r"\.ROBLOSECURITY\s*[=:]\s*[\"']?[A-Za-z0-9_|\-\.]{40,}")),
    ("GitHub token", re.compile(r"\b(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{30,}\b")),
    ("GitHub fine-grained token", re.compile(r"\bgithub_pat_[A-Za-z0-9_]{40,}\b")),
    ("AWS access key id", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("Private key block", re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----")),
    ("OpenAI / Anthropic style key", re.compile(r"\bsk-(?:ant-)?[A-Za-z0-9_\-]{30,}\b")),
    ("Discord webhook", re.compile(r"https://(?:ptb\.|canary\.)?discord(?:app)?\.com/api/webhooks/\d+/[A-Za-z0-9_\-]+")),
    ("Slack token", re.compile(r"\bxox[baprs]-[A-Za-z0-9\-]{10,}\b")),
    ("URL with credentials", re.compile(r"[a-z][a-z0-9+.\-]*://[^/\s:@\"']+:[^/\s:@\"']{4,}@[^/\s\"']+", re.I)),
    ("Roblox Open Cloud key", re.compile(
        r"(?i)(?:x-api-key|open[_-]?cloud[_-]?(?:api[_-]?)?key)[\"']?\s*[:=]\s*[\"']?[A-Za-z0-9+/=_\-]{40,}")),
    ("Generic secret assignment", re.compile(
        r"(?i)\b(?:api[_-]?key|secret|token|passwd|password|auth[_-]?key|private[_-]?key)\b"
        r"[\"']?\s*[:=]\s*[\"'][^\"'\s]{16,}[\"']")),
]
PLACEHOLDER = re.compile(r"(?i)(your_|<.*>|changeme|example|placeholder|dummy|xxxx|\*{4,}|replace_me|todo)")
BINARY_EXT = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico", ".mp3", ".ogg", ".wav",
              ".rbxl", ".rbxm", ".rbxlx", ".rbxmx", ".zip", ".gz", ".pdf", ".ttf", ".otf",
              ".woff", ".woff2"}
SELF_SKIP = ".agents/skills/secret-scan/"


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True,
                          encoding="utf-8", errors="ignore")


def mask(s):
    s = s.strip()
    return s[:4] + "..." + s[-3:] if len(s) > 10 else "***"


def check_line(line):
    hits = []
    for name, rx in PATTERNS:
        m = rx.search(line)
        if m and not PLACEHOLDER.search(m.group(0)):
            hits.append((name, mask(m.group(0))))
    return hits


findings = []


def scan_text(label, text):
    for i, line in enumerate(text.splitlines(), 1):
        for name, masked in check_line(line):
            findings.append(f"{label}:{i}  [{name}]  {masked}")


mode = sys.argv[1] if len(sys.argv) > 1 else ""

if git("rev-parse", "--is-inside-work-tree").stdout.strip() != "true":
    print("Not a git repository.")
    sys.exit(2)

if mode == "--history":
    log = git("log", "--all", "-p", "--no-color", "--unified=0")
    current = "?"
    for line in log.stdout.splitlines():
        if line.startswith("+++ b/"):
            current = line[6:]
        elif line.startswith("+") and not line.startswith("+++"):
            if SELF_SKIP in current:
                continue
            for name, masked in check_line(line[1:]):
                findings.append(f"history:{current}  [{name}]  {masked}")
else:
    if mode == "--staged":
        names = git("diff", "--cached", "--name-only", "--diff-filter=ACM").stdout.splitlines()
    else:
        names = git("ls-files", "--cached", "--others", "--exclude-standard").stdout.splitlines()
    for n in names:
        p = ROOT / n
        if (not p.is_file() or p.suffix.lower() in BINARY_EXT or n.startswith(SELF_SKIP)
                or p.stat().st_size > 2_000_000):
            continue
        if mode == "--staged":
            text = git("show", f":{n}").stdout
        else:
            text = p.read_text(encoding="utf-8", errors="ignore")
        scan_text(n, text)
    for n in git("ls-files").stdout.splitlines():
        base = n.rsplit("/", 1)[-1]
        if base == ".env" or base.endswith((".key", ".pem", ".p12")) or n.startswith("secrets/"):
            findings.append(f"{n}  [Sensitive file tracked by git]  -")

gi = ROOT / ".gitignore"
gi_text = gi.read_text(encoding="utf-8", errors="ignore") if gi.is_file() else ""
for needed in (".env", "*.key", "secrets/", ".DS_Store"):
    if needed not in gi_text:
        findings.append(f".gitignore  [Missing ignore rule]  {needed}")

if findings:
    print("FINDINGS:")
    for f in findings[:100]:
        print("  " + f)
    print(f"\n{len(findings)} finding(s). Treat any real secret as compromised: rotate it first.")
    sys.exit(1)
print("PASS: no secrets detected.")
