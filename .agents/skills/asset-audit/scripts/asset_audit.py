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
ICON_FILE_RE = re.compile(r"([a-z0-9_]+)\.(svg|png)", re.I)
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
icon_credit_hits = []

icon_root = ROOT / "ativos" / "domworld" / "icones"
credit_path = ROOT / "docs" / "ICON_CREDITS.md"
credit_rows = {}
if credit_path.is_file():
    for line in credit_path.read_text(encoding="utf-8", errors="ignore").splitlines():
        if not line.startswith("|"):
            continue
        cells = [cell.strip().strip("`") for cell in line.strip().strip("|").split("|")]
        if len(cells) >= 6 and cells[0] != "ID do ícone" and re.fullmatch(r"[a-z0-9_]+", cells[0]):
            credit_rows[cells[0]] = cells[1:6]
else:
    notes.append("docs/ICON_CREDITS.md not found; icon input files cannot be credited.")

if icon_root.is_dir():
    for p in icon_root.rglob("*"):
        if not p.is_file() or p.name == ".gitkeep":
            continue
        if p.suffix.lower() not in {".svg", ".png"}:
            icon_credit_hits.append(f"{rel(p)}: unsupported file in icon input folder")
            continue
        row = credit_rows.get(p.stem.lower())
        if row is None:
            icon_credit_hits.append(f"{rel(p)}: no ICON_CREDITS.md row for this icon ID")
            continue
        file_cell, source, author, license_name, attribution = [cell.strip() for cell in row]
        expected = {m.group(0).lower() for m in ICON_FILE_RE.finditer(file_cell)}
        missing = []
        if p.name.lower() not in expected:
            missing.append("expected filename")
        if not source:
            missing.append("source URL")
        if not author:
            missing.append("author")
        if not license_name:
            missing.append("license")
        if attribution.lower() not in {"sim", "não", "nao"}:
            missing.append("credit required (Sim/Não)")
        if missing:
            icon_credit_hits.append(f"{rel(p)}: ICON_CREDITS.md missing/invalid: {', '.join(missing)}")

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
if icon_credit_hits:
    problems.append(f"{len(icon_credit_hits)} icon file(s) lack a complete ICON_CREDITS.md entry")

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
if icon_credit_hits:
    print("\nIcon credit problems (max 40):")
    for hit in icon_credit_hits[:40]:
        print("  " + hit)

if problems:
    print("\nFAIL:")
    for pr in problems:
        print("  - " + pr)
    sys.exit(1)
print("PASS: no third-party assets detected.")
