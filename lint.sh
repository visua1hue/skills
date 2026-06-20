#!/usr/bin/env bash
# Lint skills against the SKILL.md spec. Runs locally and in CI.
set -euo pipefail
cd "$(dirname "$0")"

python3 - <<'PY'
import os, re, sys, yaml

errors, warnings = [], []
RESERVED = ("anthropic", "claude")
NAME_RE = re.compile(r"^[a-z0-9-]+$")
XML_RE = re.compile(r"</?[a-zA-Z]")

def frontmatter(path):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    if not text.startswith("---"):
        return None, "", "no YAML frontmatter (file must start with '---')"
    parts = text.split("---", 2)
    if len(parts) < 3:
        return None, "", "unterminated frontmatter block"
    try:
        return (yaml.safe_load(parts[1]) or {}), parts[2], None
    except yaml.YAMLError as e:
        return None, "", f"invalid YAML frontmatter: {e}"

# MANIFEST entries must resolve to a skill dir + SKILL.md
with open("MANIFEST.yaml", encoding="utf-8") as f:
    manifest = yaml.safe_load(f) or {}
for skill in (manifest.get("upstreams") or {}):
    if not os.path.isdir(skill):
        errors.append(f"MANIFEST entry '{skill}' has no directory ./{skill}/")
    elif not os.path.isfile(f"{skill}/SKILL.md"):
        errors.append(f"missing {skill}/SKILL.md")

skill_dirs = [d for d in sorted(os.listdir("."))
              if os.path.isdir(d) and not d.startswith(".")]
seen = {}

for d in skill_dirs:
    md = f"{d}/SKILL.md"
    if not os.path.isfile(md):
        errors.append(f"directory '{d}/' has no SKILL.md")
        continue

    fm, body, err = frontmatter(md)
    if err:
        errors.append(f"{md}: {err}")
        continue

    name, desc = fm.get("name"), fm.get("description")

    if not name:
        errors.append(f"{md}: frontmatter missing 'name'")
    else:
        name = str(name)
        if not NAME_RE.match(name):
            errors.append(f"{md}: name '{name}' must be lowercase letters, numbers, hyphens only")
        if len(name) > 64:
            errors.append(f"{md}: name exceeds 64 chars ({len(name)})")
        if name != d:
            errors.append(f"{md}: name '{name}' must match directory '{d}'")
        if any(w in name for w in RESERVED):
            errors.append(f"{md}: name '{name}' contains a reserved word (anthropic/claude)")
        seen.setdefault(name, []).append(d)

    if not desc or not str(desc).strip():
        errors.append(f"{md}: frontmatter missing non-empty 'description'")
    else:
        desc = str(desc)
        if len(desc) > 1024:
            errors.append(f"{md}: description exceeds 1024 chars ({len(desc)})")
        if XML_RE.search(desc):
            errors.append(f"{md}: description contains XML tags")
        if re.search(r"\b(I can|I will|I'll|you can|you should|we can)\b", desc, re.I):
            warnings.append(f"{md}: description should be third person (avoid 'I'/'you')")

    if body.count("\n") > 500:
        warnings.append(f"{md}: body is {body.count(chr(10))} lines (>500; consider splitting)")

    for m in re.finditer(r"\]\(([^)]+)\)", body):
        if "\\" in m.group(1):
            errors.append(f"{md}: link '{m.group(1)}' uses backslashes; use forward slashes")

for name, dirs in seen.items():
    if len(dirs) > 1:
        errors.append(f"duplicate skill name '{name}' in: {', '.join(dirs)}")

for w in warnings:
    print(f"warning: {w}")
for e in errors:
    print(f"error: {e}")

if errors:
    sys.exit(1)
print(f"ok — {len(skill_dirs)} skills linted"
      + (f", {len(warnings)} warning(s)" if warnings else ""))
PY
