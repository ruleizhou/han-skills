#!/usr/bin/env python3
"""Validate han-skill repository structure and four-platform conventions.

Checks
------
1. Every skills/<name>/SKILL.md exists and has YAML frontmatter.
2. Frontmatter contains non-empty 'name' and 'description'; 'name' matches dir.
3. The plugin manifests have synchronized 'name' and 'version':
   - .claude-plugin/plugin.json
   - .claude-plugin/marketplace.json (metadata.version + plugins[0].name)
   - .codex-plugin/plugin.json
   - package.json (version only; pi package manifest)
4. The 'skills' path declared in .claude-plugin/plugin.json exists.
5. package.json is a valid pi package: 'pi.skills' paths exist + 'pi-package' keyword.
6. Each .cursor/rules/<name>.mdc exists and matches gen_cursor_rules.render_mdc().
7. install.sh, hooks/*.sh and skills/<name>/scripts/*.sh have the +x bit.

Exit 0 on success, 1 on any violation.

Run locally:
    python3 scripts/validate.py
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
errors: list[str] = []
DEPRECATED_DIR_NAME = "Deprecated"

# gen_cursor_rules lives next to this file; import its renderer for sync checks.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from gen_cursor_rules import render_mdc  # noqa: E402


def fail(msg: str) -> None:
    errors.append(msg)


def rel(p: Path) -> str:
    return str(p.relative_to(ROOT))


def parse_frontmatter(path: Path) -> dict[str, str] | None:
    """Return YAML frontmatter as a flat dict of string scalars, or None if absent."""
    text = path.read_text(encoding="utf-8")
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.DOTALL)
    if not m:
        return None
    fm: dict[str, str] = {}
    for line in m.group(1).splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.startswith((" ", "\t")):
            continue
        mm = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*)\s*:\s*(.*)$", line)
        if not mm:
            continue
        key, val = mm.group(1), mm.group(2).strip()
        if (val.startswith('"') and val.endswith('"')) or (
            val.startswith("'") and val.endswith("'")
        ):
            val = val[1:-1]
        fm[key] = val
    return fm


def check_skills() -> int:
    skills_dir = ROOT / "skills"
    if not skills_dir.is_dir():
        fail(f"missing skills/ directory at {rel(skills_dir)}")
        return 0
    count = 0
    for skill_dir in sorted(skills_dir.iterdir()):
        if not skill_dir.is_dir():
            continue
        if skill_dir.name == DEPRECATED_DIR_NAME:
            continue
        count += 1
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.is_file():
            fail(f"missing SKILL.md: {rel(skill_dir)}/SKILL.md")
            continue
        fm = parse_frontmatter(skill_md)
        if fm is None:
            fail(f"no YAML frontmatter: {rel(skill_md)}")
            continue
        name = fm.get("name", "").strip()
        desc = fm.get("description", "").strip()
        if not name:
            fail(f"missing or empty 'name' field: {rel(skill_md)}")
        elif name != skill_dir.name:
            fail(
                f"name mismatch: {rel(skill_md)} has name='{name}', "
                f"expected '{skill_dir.name}'"
            )
        if not desc:
            fail(f"missing or empty 'description' field: {rel(skill_md)}")
    return count


def check_manifests() -> None:
    claude_plugin = ROOT / ".claude-plugin" / "plugin.json"
    claude_market = ROOT / ".claude-plugin" / "marketplace.json"
    codex_plugin = ROOT / ".codex-plugin" / "plugin.json"
    pkg_json = ROOT / "package.json"

    for p in (claude_plugin, claude_market, codex_plugin, pkg_json):
        if not p.is_file():
            fail(f"missing manifest: {rel(p)}")
            return

    try:
        cdata = json.loads(claude_plugin.read_text(encoding="utf-8"))
        cmdata = json.loads(claude_market.read_text(encoding="utf-8"))
        xdata = json.loads(codex_plugin.read_text(encoding="utf-8"))
        pdata = json.loads(pkg_json.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        fail(f"manifest is not valid JSON: {e}")
        return

    cm_plugins = cmdata.get("plugins") or []
    cm_plugin = cm_plugins[0] if cm_plugins else {}

    # Plugin name must sync across the 3 manifests that declare a plugin name.
    names = {
        ".claude-plugin/plugin.json": cdata.get("name"),
        ".codex-plugin/plugin.json": xdata.get("name"),
        ".claude-plugin/marketplace.json (plugins[0].name)": cm_plugin.get("name"),
    }
    if len({v for v in names.values() if v is not None}) > 1 or None in names.values():
        fail(f"plugin 'name' out of sync across manifests: {names}")

    # Version sync: the two plugin.json files plus claude marketplace metadata.
    versions = {
        ".claude-plugin/plugin.json": cdata.get("version"),
        ".claude-plugin/marketplace.json (metadata.version)": cmdata.get(
            "metadata", {}
        ).get("version"),
        ".codex-plugin/plugin.json": xdata.get("version"),
        "package.json": pdata.get("version"),
    }
    if (
        len({v for v in versions.values() if v is not None}) > 1
        or None in versions.values()
    ):
        fail(f"plugin 'version' out of sync across manifests: {versions}")

    skills_path = cdata.get("skills")
    if skills_path:
        full = (ROOT / skills_path).resolve()
        if not full.is_dir():
            fail(
                f".claude-plugin/plugin.json 'skills' path does not exist: "
                f"{skills_path}"
            )


def check_package_json() -> None:
    """Validate package.json as a pi package: pi.skills paths + pi-package keyword.

    The version sync is handled by check_manifests(); here we only enforce the
    pi-specific structure so that `pi install` / `pi -e ./` can discover skills.
    """
    pkg_json = ROOT / "package.json"
    if not pkg_json.is_file():
        return  # Already reported in check_manifests().
    try:
        data = json.loads(pkg_json.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return  # Already reported.
    if not data.get("name"):
        fail("package.json missing or empty 'name'")
    pi = data.get("pi") or {}
    skills_paths = pi.get("skills") or []
    if not skills_paths:
        fail("package.json 'pi.skills' is empty (pi needs at least one skills path)")
        return
    for sp in skills_paths:
        if any(ch in sp for ch in "*?![]"):
            continue  # glob pattern (e.g. ./skills/* or !./skills/Deprecated)
        full = (ROOT / sp).resolve()
        if not full.is_dir():
            fail(f"package.json 'pi.skills' path does not exist: {sp}")
    # pi discovers SKILL.md recursively, so skills/Deprecated/ would be loaded
    # by `pi install` unless excluded. Two equivalent mechanisms:
    #   (a) skills/.ignore with a "Deprecated/" rule (pi native ignore, git-agnostic)
    #   (b) a "!./skills/Deprecated" negation in pi.skills (package.json glob)
    deprecated_dir = ROOT / "skills" / DEPRECATED_DIR_NAME
    if deprecated_dir.is_dir() and any(deprecated_dir.rglob("SKILL.md")):
        ignore_file = ROOT / "skills" / ".ignore"
        has_ignore_rule = (
            ignore_file.is_file()
            and "Deprecated" in ignore_file.read_text(encoding="utf-8")
        )
        has_negation = any(
            isinstance(s, str) and "!" in s and "Deprecated" in s
            for s in skills_paths
        )
        if not (has_ignore_rule or has_negation):
            fail(
                "skills/Deprecated/ contains SKILL.md but is not excluded from pi "
                "discovery (pi recurses into SKILL.md). Add 'Deprecated/' to "
                "skills/.ignore (git-agnostic) OR '!./skills/Deprecated' to "
                "package.json pi.skills"
            )
    keywords = data.get("keywords") or []
    if "pi-package" not in keywords:
        fail(
            "package.json missing 'pi-package' keyword "
            "(required for pi package discovery)"
        )


def check_cursor_rules_sync() -> int:
    """Every skill must have a .mdc that matches a fresh render."""
    rules_dir = ROOT / ".cursor" / "rules"
    skills_dir = ROOT / "skills"
    if not rules_dir.is_dir():
        fail("missing .cursor/rules/ directory (run: python3 scripts/gen_cursor_rules.py)")
        return 0
    if not skills_dir.is_dir():
        return 0
    synced = 0
    for skill_dir in sorted(skills_dir.iterdir()):
        if not skill_dir.is_dir():
            continue
        if skill_dir.name == DEPRECATED_DIR_NAME:
            continue
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.is_file():
            continue
        mdc = rules_dir / f"{skill_dir.name}.mdc"
        if not mdc.is_file():
            fail(f"missing cursor rule: {rel(mdc)} (run: python3 scripts/gen_cursor_rules.py)")
            continue
        if mdc.read_text(encoding="utf-8") != render_mdc(skill_md):
            fail(f"cursor rule out of sync: {rel(mdc)} (run: python3 scripts/gen_cursor_rules.py)")
            continue
        synced += 1
    return synced


def check_executable_bits() -> int:
    targets: list[Path] = []
    installer = ROOT / "install.sh"
    if installer.is_file():
        targets.append(installer)
    hooks_dir = ROOT / "hooks"
    if hooks_dir.is_dir():
        targets.extend(sorted(hooks_dir.glob("*.sh")))
    skills_dir = ROOT / "skills"
    if skills_dir.is_dir():
        targets.extend(sorted(skills_dir.glob("*/scripts/*.sh")))
    for sh in targets:
        if not os.access(sh, os.X_OK):
            fail(f"script missing executable bit (run chmod +x): {rel(sh)}")
    return len(targets)


def main() -> int:
    skill_count = check_skills()
    check_manifests()
    check_package_json()
    cursor_count = check_cursor_rules_sync()
    sh_count = check_executable_bits()

    if errors:
        print(f"FAIL: {len(errors)} error(s)\n", file=sys.stderr)
        for e in errors:
            print(f"  error: {e}", file=sys.stderr)
        return 1

    print(
        f"OK: {skill_count} skills, 3 manifests synced (+ package.json), "
        f"{cursor_count} cursor rule(s) in sync, "
        f"{sh_count} shell script(s) executable"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
