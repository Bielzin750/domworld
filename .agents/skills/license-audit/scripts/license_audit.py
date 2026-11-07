#!/usr/bin/env python3
"""DomWorld license audit.

Usage: python3 license_audit.py [repo_root]
Exit code: 0 = no failures, 1 = at least one failure.
Only uses the Python standard library.
"""
import os
import re
import sys
from pathlib import Path

ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()

SKIP_DIRS = {".git", "node_modules", "build", "Packages", "DevPackages",
             ".venv", "__pycache__", "dist", "out"}
TEXT_EXT = {".lua", ".luau", ".py", ".ts", ".tsx", ".js", ".json", ".toml",
            ".md", ".txt", ".yaml", ".yml", ".sh", ".html", ".css", ".cfg", ".ini"}
CODE_EXT = {".lua", ".luau"}
# Places where the old names may legitimately appear (credits, legal, docs, skills).
ALLOWED_PREFIXES = ("LICENSE", "NOTICE.md", "README.md", "CHANGELOG.md",
                    "AGENTS.md", "CLAUDE.md", "DOMWORLD_CODEX_PROMPT.md",
                    "docs/", ".agents/", ".github/")
ATTRIBUTION = re.compile(
    r"(based on|baseado|derived|derivado|fork of|powered by|©|\(c\)|copyright|"
    r"credit|crédito|credito|affiliat|afiliad|endors|licen[sc]|agpl|origin)", re.I)
OLD_NAMES = re.compile(r"roworld|ro_world|ro world|openfront", re.I)

results = []  # (status, message)


def add(status, msg):
    results.append((status, msg))


def rel(p):
    return p.relative_to(ROOT).as_posix()


def walk():
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            yield Path(dirpath) / name


def read(p):
    try:
        return p.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def first_existing(*names):
    for n in names:
        p = ROOT / n
        if p.is_file():
            return p
    return None


# 1. LICENSE
lic = first_existing("LICENSE", "LICENSE.md", "LICENSE.txt")
if not lic:
    add("FAIL", "LICENSE file not found.")
else:
    t = read(lic).lower()
    add("PASS" if "gnu affero general public license" in t else "FAIL",
        "LICENSE contains the AGPL v3 text.")
    add("PASS" if "additional terms" in t else "FAIL",
        "LICENSE still contains the ADDITIONAL TERMS (Section 7) block.")
    add("PASS" if "openfront and contributors" in t else "FAIL",
        "LICENSE still requires the 'OpenFront and Contributors' copyright notice.")

# 2. NOTICE.md
notice = first_existing("NOTICE.md")
if not notice:
    add("FAIL", "NOTICE.md not found.")
else:
    t = read(notice).lower()
    for label, needle in [("DomWorld", "domworld"), ("origin RoWorld", "roworld"),
                          ("author Luke Chatton", "chatton"),
                          ("OpenFront", "openfront"),
                          ("AGPL", "agpl"),
                          ("repository URL", "github.com/")]:
        add("PASS" if needle in t else "FAIL", f"NOTICE.md mentions {label}.")
    add("PASS" if re.search(r"20\d\d", t) else "FAIL",
        "NOTICE.md records a modification date/year.")

# 3. LICENSE-ASSETS
add("PASS" if first_existing("LICENSE-ASSETS", "LICENSE-ASSETS.md") else "FAIL",
    "LICENSE-ASSETS exists (license for the new art).")

# 4. README
readme = first_existing("README.md")
if not readme:
    add("FAIL", "README.md not found.")
else:
    t = read(readme).lower()
    add("PASS" if "agpl" in t else "FAIL", "README.md mentions AGPL.")
    add("PASS" if "roworld" in t and "openfront" in t else "FAIL",
        "README.md credits RoWorld and OpenFront.")

# 5-8. Scan files
placeholder_hits, name_hits, name_paths = [], [], []
ingame_notice = ingame_agpl = ingame_url = False

for p in walk():
    r = rel(p)
    if OLD_NAMES.search(r) and not r.startswith(ALLOWED_PREFIXES):
        name_paths.append(r)
    if p.suffix.lower() not in TEXT_EXT and p.name not in ("LICENSE", "NOTICE"):
        continue
    text = read(p)
    in_allowed = r.startswith(ALLOWED_PREFIXES)

    if not r.startswith((".agents/",)) and r != "DOMWORLD_CODEX_PROMPT.md":
        for ph in ("<URL_DO_MEU_FORK>", "<ANO>"):
            if ph in text:
                placeholder_hits.append(f"{r}: {ph}")

    if p.suffix.lower() in CODE_EXT:
        low = text.lower()
        if "openfront and contributors" in low:
            ingame_notice = True
        if "agpl" in low:
            ingame_agpl = True
        if re.search(r"github\.com/[^\s\"']*domworld", low):
            ingame_url = True

    if not in_allowed:
        for i, line in enumerate(text.splitlines(), 1):
            if OLD_NAMES.search(line) and not ATTRIBUTION.search(line):
                name_hits.append(f"{r}:{i}: {line.strip()[:100]}")

add("PASS" if not placeholder_hits else "FAIL",
    "No leftover placeholders." + ("" if not placeholder_hits else
                                    " Found: " + "; ".join(placeholder_hits[:10])))
add("PASS" if ingame_notice else "FAIL",
    "Luau code shows '(c) OpenFront and Contributors' to the player.")
add("PASS" if ingame_agpl else "FAIL", "Luau code mentions AGPL in the credits/about UI.")
add("PASS" if ingame_url else "FAIL", "Luau code exposes the DomWorld repository URL.")
add("PASS" if not name_hits else "FAIL",
    "Old names only appear as attribution." + ("" if not name_hits else
                                                " Offenders listed below."))
add("PASS" if not name_paths else "WARN",
    "No file/folder names with the old names." + ("" if not name_paths else
                                                   " Found: " + "; ".join(name_paths[:10])))

# Output
fails = 0
for status, msg in results:
    print(f"[{status}] {msg}")
    if status == "FAIL":
        fails += 1
if name_hits:
    print("\nOld-name offenders (max 50):")
    for h in name_hits[:50]:
        print("  " + h)
print(f"\n{fails} failure(s).")
sys.exit(1 if fails else 0)
