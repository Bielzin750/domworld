#!/usr/bin/env python3
"""DomWorld asset audit.

Usage: python3 asset_audit.py [repo_root]
Exit code: 0 = clean, 1 = problems. Standard library only.
"""
import os
import re
import sys
from pathlib import Path

ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
SKIP_DIRS = {".git", "node_modules", "build", "Packages", "DevPackages", ".venv",
             "__pycache__", "dist", "out", ".agents"}
TEXT_EXT = {".lua", ".luau", ".py", ".ts", ".tsx", ".js", ".json", ".toml", ".md",
            ".txt", ".yaml", ".yml", ".html", ".css"}
ART_DIRS = ("ativos", "assets")
ID_RE = re.compile(r"rbxassetid://(\d+)|asset/?\?id=(\d+)", re.I)
HOST_RE = re.compile(r"(openfront\.(io|dev|com)|roworld\.[a-z]{2,}|cdn\.openfront)", re.I)
DOC_PREFIXES = ("docs/", "README.md", "NOTICE.md", "CHANGELOG.md", "LICENSE")

problems, notes = [], []


def rel(p):
    return p.relative_to(ROOT).as_posix()


own_ids = set()
own_file = ROOT / "docs" / "OWN_ASSET_IDS.txt"
if own_file.is_file():
    for line in own_file.read_text(encoding="utf-8", errors="ignore").splitlines():
        m = re.match(r"\s*(\d+)", line)
        if m:
            own_ids.add(m.group(1))
else:
    notes.append("docs/OWN_ASSET_IDS.txt not found; every non-zero asset ID will be flagged.")

unknown_ids = {}
host_hits = []
leftover_files = []
proprietary_dirs = []

for dirpath, dirnames, filenames in os.walk(ROOT):
    dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
    d = Path(dirpath)
    for dn in dirnames:
        if dn.lower() == "proprietary":
            proprietary_dirs.append(rel(d / dn))
    for name in filenames:
        p = d / name
        r = rel(p)
        parts = r.split("/")
        # leftover art outside domworld/
        if parts[0] in ART_DIRS and len(parts) > 1:
            if parts[1].lower() != "domworld" and name.lower() != "readme.md":
                leftover_files.append(r)
        if p.suffix.lower() not in TEXT_EXT:
            continue
        try:
            text = p.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for i, line in enumerate(text.splitlines(), 1):
            for m in ID_RE.finditer(line):
                aid = m.group(1) or m.group(2)
                if aid != "0" and aid not in own_ids:
                    unknown_ids.setdefault(aid, []).append(f"{r}:{i}")
            if not r.startswith(DOC_PREFIXES) and HOST_RE.search(line):
                host_hits.append(f"{r}:{i}: {line.strip()[:90]}")

if unknown_ids:
    problems.append(f"{len(unknown_ids)} Roblox asset ID(s) not listed in docs/OWN_ASSET_IDS.txt")
if leftover_files:
    problems.append(f"{len(leftover_files)} file(s) in the art folder outside domworld/")
if proprietary_dirs:
    problems.append("proprietary/ directory present: " + ", ".join(proprietary_dirs))
if host_hits:
    problems.append(f"{len(host_hits)} reference(s) to third-party asset hosts")

art_readme = None
for a in ART_DIRS:
    c = ROOT / a / "domworld" / "README.md"
    if c.is_file():
        art_readme = c
if art_readme is None:
    problems.append("art README (ativos/domworld/README.md) missing")
else:
    txt = art_readme.read_text(encoding="utf-8", errors="ignore").upper().replace("CC-BY-SA", "CC BY-SA")
    if "CC BY-SA" not in txt:
        problems.append("art README does not state CC BY-SA 4.0")
if not any((ROOT / n).is_file() for n in ("LICENSE-ASSETS", "LICENSE-ASSETS.md")):
    problems.append("LICENSE-ASSETS missing")

for n in notes:
    print("[NOTE]", n)
if unknown_ids:
    print("\nUnknown asset IDs:")
    for aid, locs in list(unknown_ids.items())[:40]:
        print(f"  {aid}  <- {', '.join(locs[:3])}")
if leftover_files:
    print("\nLeftover art files (max 40):")
    for f in leftover_files[:40]:
        print("  " + f)
if host_hits:
    print("\nThird-party host references (max 40):")
    for h in host_hits[:40]:
        print("  " + h)

if problems:
    print("\nFAIL:")
    for pr in problems:
        print("  - " + pr)
    sys.exit(1)
print("PASS: no third-party assets detected.")
