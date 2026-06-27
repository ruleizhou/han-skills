#!/usr/bin/env python3
"""Generate Cursor rules (.cursor/rules/*.mdc) from skills/*/SKILL.md.

Cursor has no "skill" concept — it uses Project Rules (.cursor/rules/*.mdc).
Each skill is converted into one .mdc with alwaysApply:false so the user
references it on demand via @<name>, preserving the skill's lazy-load intent.

The description frontmatter (often a YAML folded `>` scalar spanning many
lines) is carried over verbatim: we locate the indented block rather than
parsing it to a flat string, so multi-line descriptions round-trip exactly.

CLI
---
    python3 scripts/gen_cursor_rules.py          # write .cursor/rules/*.mdc
    python3 scripts/gen_cursor_rules.py --check  # exit 1 if any rule missing/stale

Run after changing any SKILL.md, before committing.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = ROOT / "skills"
RULES_DIR = ROOT / ".cursor" / "rules"

_FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n?(.*)$", re.DOTALL)


def split_frontmatter(text: str) -> tuple[str | None, str]:
    """Split a SKILL.md into (frontmatter_block, body). frontmatter is None if absent."""
    m = _FRONTMATTER_RE.match(text)
    if not m:
        return None, text
    return m.group(1), m.group(2)


def _extract_description_field(fm_block: str) -> str | None:
    """Return the raw ``description:`` field, including any folded-scalar block.

    Carries the field over verbatim so multi-line folded (``>``) descriptions
    survive into the .mdc frontmatter exactly as written in the SKILL.md.
    """
    lines = fm_block.splitlines()
    start = None
    for i, line in enumerate(lines):
        if line.startswith((" ", "\t")):
            continue
        if re.match(r"^description\s*:", line):
            start = i
            break
    if start is None:
        return None
    field = [lines[start]]
    for j in range(start + 1, len(lines)):
        # continuation lines of a block scalar stay indented
        if lines[j].startswith((" ", "\t")):
            field.append(lines[j])
        else:
            break
    return "\n".join(field)


def render_mdc(skill_md_path: Path) -> str:
    """Render the full .mdc text for one SKILL.md (used by validate.py too)."""
    text = skill_md_path.read_text(encoding="utf-8")
    fm_block, body = split_frontmatter(text)
    desc_field = _extract_description_field(fm_block) if fm_block else None

    parts = ["---"]
    parts.append(desc_field if desc_field is not None else "description:")
    parts.append("alwaysApply: false")
    parts.append("globs:")
    parts.append("---")
    parts.append(body.lstrip("\n").rstrip() + "\n")
    return "\n".join(parts)


def _discover_skill_mds() -> list[Path]:
    if not SKILLS_DIR.is_dir():
        return []
    out: list[Path] = []
    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir():
            continue
        skill_md = skill_dir / "SKILL.md"
        if skill_md.is_file():
            out.append(skill_md)
    return out


def generate() -> int:
    RULES_DIR.mkdir(parents=True, exist_ok=True)
    skill_mds = _discover_skill_mds()
    written = 0
    for skill_md in skill_mds:
        mdc = RULES_DIR / f"{skill_md.parent.name}.mdc"
        mdc.write_text(render_mdc(skill_md), encoding="utf-8")
        written += 1
        print(f"wrote {mdc.relative_to(ROOT)}")
    print(f"\nDone: {written} cursor rule(s) under {RULES_DIR.relative_to(ROOT)}/")
    return 0


def check() -> int:
    skill_mds = _discover_skill_mds()
    if not skill_mds:
        print("no skills found", file=sys.stderr)
        return 1
    stale: list[str] = []
    for skill_md in skill_mds:
        mdc = RULES_DIR / f"{skill_md.parent.name}.mdc"
        if not mdc.is_file():
            stale.append(f"missing: {mdc.relative_to(ROOT)}")
            continue
        actual = mdc.read_text(encoding="utf-8")
        if actual != render_mdc(skill_md):
            stale.append(f"out of sync: {mdc.relative_to(ROOT)}")
    if stale:
        print(f"FAIL: {len(stale)} cursor rule(s) missing or stale:\n", file=sys.stderr)
        for s in stale:
            print(f"  {s}", file=sys.stderr)
        print(
            "\nRegenerate with: python3 scripts/gen_cursor_rules.py",
            file=sys.stderr,
        )
        return 1
    print(f"OK: {len(skill_mds)} cursor rule(s) in sync")
    return 0


def main() -> int:
    if "--check" in sys.argv[1:]:
        return check()
    return generate()


if __name__ == "__main__":
    sys.exit(main())
