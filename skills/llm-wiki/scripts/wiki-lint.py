#!/usr/bin/env python3
"""Wiki link & naming linter — pure Python stdlib, zero dependencies.

Checks the two deterministic P0 items from cmd-lint.md that can be automated:
  P0-1 链接完整性: every [[link]] resolves to an existing .md (dead-link scan)
  P0-2 文件名一致性: frontmatter `title:` == filename stem

It deliberately skips wikilinks inside fenced code blocks and inline code
(`…` / ``…``), matching Obsidian's rendering — so example links in config
docs like AGENTS.md are not false-positived. Semantic P1+ checks (contradictions,
orphans, staleness) are left to the AI.

Usage:
  python3 wiki-lint.py check [--wiki .]

Exit code: 0 = no P0 issues, 1 = dead links or naming mismatches found.

注: --wiki 指向 vault 根目录(内容页 00-Home/.. 在顶层, wiki/ 仅放基础设施)。
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

# ─── Pages excluded from NAME-consistency check ───────────
# These infrastructure pages use different naming conventions (e.g.
# wiki/overview.md has title "Overview") and should not trip P0-2.
# Dead-link scan still covers them (they contain links).
NAME_SKIP_PATTERNS = [
    "wiki/log.md", "wiki/index.md", "wiki/hot.md",
    "wiki/overview.md", "wiki/.ingest-folders.yaml", "AGENTS.md",
]

# Whole directories exempt from NAME-consistency: these hold scaffolding
# (driver/component templates created by init step C3), not real knowledge
# pages whose filename must mirror a concrete `title:`. Dead-link scan still
# runs on them (templates may contain real wikilinks).
NAME_SKIP_DIRS = ["templates/"]

WIKILINK_RE = re.compile(r"\[\[([^\]\n]+)\]\]")

# 图片引用：markdown ![alt](path) 与 HTML <img src="path">
# 只校验 _diagrams/ 路径（wiki 自动生成的 D2 图），避免误报 note/ 原始图片
MD_IMAGE_RE = re.compile(r"!\[[^\]]*\]\(([^)]+)\)")
HTML_IMG_RE = re.compile(r"""<img\s+[^>]*src=["']([^"']+)["']""")
DIAGRAM_DIR = "_diagrams/"


def image_exists(path: str, page_rel: str, wiki_dir: Path) -> bool:
    """图片引用相对页面所在目录是否存在。

    仅检查本地相对路径且含 _diagrams/ 的引用；URL/绝对路径/锚点/非 _diagrams/ 直接视为 OK。
    """
    if DIAGRAM_DIR not in path:
        return True
    if path.startswith(("http://", "https://", "data:", "/", "#")):
        return True
    target = wiki_dir / Path(page_rel).parent / path
    return target.is_file()


# ─── Code masking ─────────────────────────────────────────


def mask_code(text: str) -> str:
    """Replace fenced + inline code with equal-length spaces.

    Preserves byte offsets and newlines so line numbers computed from the
    masked text match the original. Wikilinks inside code are thus ignored.
    """
    out_lines: List[str] = []
    in_fence = False
    for line in text.split("\n"):
        # Fenced code block: a line whose first non-space chars are ```
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            out_lines.append(" " * len(line))
            continue
        if in_fence:
            out_lines.append(" " * len(line))
            continue
        # Inline code: mask double-backtick pairs first, then single.
        line = re.sub(r"``[^`\n]*``", lambda m: " " * len(m.group(0)), line)
        line = re.sub(r"`[^`\n]*`", lambda m: " " * len(m.group(0)), line)
        out_lines.append(line)
    return "\n".join(out_lines)


def line_of(text: str, offset: int) -> int:
    """1-based line number of a character offset."""
    return text.count("\n", 0, offset) + 1


# ─── Frontmatter ──────────────────────────────────────────


def parse_title(text: str) -> Optional[str]:
    """Extract the `title:` field from YAML frontmatter, or None."""
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end == -1:
        return None
    fm = text[3:end]
    m = re.search(r"^title:\s*(.+?)\s*$", fm, re.MULTILINE)
    if not m:
        return None
    title = m.group(1).strip().strip("\"'")
    return title or None


# ─── Link target resolution ───────────────────────────────


def resolve(target: str, all_md: set, stem_map: Dict[str, List[str]]
            ) -> Tuple[bool, Optional[str]]:
    """Resolve a wikilink target. Returns (exists, ambiguity_note).

    - target with '/': look up '{target}.md' directly.
    - target without '/': fall back to global basename (stem) lookup.
    """
    if "/" in target:
        return (target + ".md") in all_md, None
    hits = stem_map.get(target, [])
    if not hits:
        return False, None
    if len(hits) > 1:
        return True, f"歧义: {len(hits)} 个同名文件 {hits}"
    return True, None


# ─── Check ────────────────────────────────────────────────


def collect_pages(wiki_dir: Path) -> Dict[str, str]:
    """Map rel-path -> file content for every .md under wiki_dir."""
    pages: Dict[str, str] = {}
    for root, dirs, files in os.walk(wiki_dir):
        # Skip hidden dirs (.claude, .obsidian, .locks, .git)
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        for f in files:
            if not f.endswith(".md"):
                continue
            full = Path(root) / f
            rel = str(full.relative_to(wiki_dir)).replace("\\", "/")
            try:
                with open(full, "r", encoding="utf-8") as fh:
                    pages[rel] = fh.read()
            except (IOError, UnicodeDecodeError) as e:
                print(f"WARN: 无法读取 {rel}: {e}", file=sys.stderr)
    return pages


def run_check(wiki_dir: Path) -> Dict[str, Any]:
    wiki_dir = wiki_dir.resolve()
    pages = collect_pages(wiki_dir)

    all_md: set = set(pages.keys())
    # stem -> list of rel paths (for no-slash link fallback)
    stem_map: Dict[str, List[str]] = {}
    for rel in all_md:
        stem_map.setdefault(Path(rel).stem, []).append(rel)

    dead_links: List[Dict[str, Any]] = []
    name_mismatches: List[Dict[str, Any]] = []
    broken_images: List[Dict[str, Any]] = []
    ambiguities: List[str] = []

    for rel in sorted(pages):
        text = pages[rel]
        masked = mask_code(text)

        # P0-1: dead links
        for m in WIKILINK_RE.finditer(masked):
            raw = m.group(1)
            target = raw.split("|")[0].split("#")[0].strip()
            if not target:
                continue
            exists, note = resolve(target, all_md, stem_map)
            if not exists:
                dead_links.append({
                    "file": rel,
                    "line": line_of(masked, m.start()),
                    "target": target,
                })
            elif note:
                ambiguities.append(f"{rel}:{line_of(masked, m.start())}  [[{target}]]  {note}")

        # P0-3: 图片引用完整性（仅 _diagrams/，对所有页面执行——infra 页也可能引用图）
        for m in MD_IMAGE_RE.finditer(masked):
            path = m.group(1).strip()
            if not image_exists(path, rel, wiki_dir):
                broken_images.append({
                    "file": rel,
                    "line": line_of(masked, m.start()),
                    "path": path,
                })
        for m in HTML_IMG_RE.finditer(masked):
            path = m.group(1).strip()
            if not image_exists(path, rel, wiki_dir):
                broken_images.append({
                    "file": rel,
                    "line": line_of(masked, m.start()),
                    "path": path,
                })

        # P0-2: filename == title (skip infra pages, templates, + pages without title)
        if rel in NAME_SKIP_PATTERNS or rel.startswith(tuple(NAME_SKIP_DIRS)):
            continue
        title = parse_title(text)
        if title is None:
            continue
        stem = Path(rel).stem
        if title != stem:
            name_mismatches.append({
                "file": rel,
                "stem": stem,
                "title": title,
            })

    return {
        "checked": len(pages),
        "dead_links": dead_links,
        "name_mismatches": name_mismatches,
        "broken_images": broken_images,
        "ambiguities": ambiguities,
    }


def report(result: Dict[str, Any]) -> int:
    """Print human-readable report to stderr; return exit code (0 ok, 1 issues)."""
    nd = len(result["dead_links"])
    nn = len(result["name_mismatches"])
    ni = len(result["broken_images"])
    na = len(result["ambiguities"])

    print(f"\n扫描 {result['checked']} 个 .md 页面", file=sys.stderr)

    print(f"\nP0 死链 ({nd}):", file=sys.stderr)
    for d in result["dead_links"]:
        print(f"  ❌ {d['file']}:{d['line']}  [[{d['target']}]]", file=sys.stderr)
    if nd == 0:
        print("  ✅ 无死链", file=sys.stderr)

    print(f"\nP0 命名不一致 ({nn}):", file=sys.stderr)
    for n in result["name_mismatches"]:
        print(f"  ❌ {n['file']}  文件名={n['stem']} ≠ title=\"{n['title']}\"", file=sys.stderr)
    if nn == 0:
        print("  ✅ 文件名与 title 一致", file=sys.stderr)

    print(f"\nP0 图片引用缺失 ({ni}):", file=sys.stderr)
    for im in result["broken_images"]:
        print(f"  ❌ {im['file']}:{im['line']}  {im['path']}", file=sys.stderr)
    if ni == 0:
        print("  ✅ 图片引用完整", file=sys.stderr)

    if na:
        print(f"\nP2 链接歧义 ({na}, 提示, 不影响退出码):", file=sys.stderr)
        for a in result["ambiguities"]:
            print(f"  ⚠️ {a}", file=sys.stderr)

    status = "issues" if (nd or nn or ni) else "ok"
    print(f"\n结果: {status}（死链={nd}, 命名不一致={nn}, 图片缺失={ni}, 歧义={na}）", file=sys.stderr)
    return 1 if (nd or nn or ni) else 0


# ─── CLI ──────────────────────────────────────────────────


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Wiki 链接与命名一致性检查（P0 自动化，零依赖，纯 stdlib）",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""示例:
  python3 wiki-lint.py check --wiki .""",
    )
    sub = parser.add_subparsers(dest="command", help="子命令")

    p_check = sub.add_parser("check", help="检查死链与命名一致性")
    p_check.add_argument("--wiki", default=".",
                         help="wiki 目录路径，vault 根（默认: .，内容页在顶层）")

    args = parser.parse_args()
    if args.command is None:
        parser.print_help()
        sys.exit(1)

    wiki_dir = Path(args.wiki)
    if not wiki_dir.is_dir():
        print(f"ERROR: wiki 目录不存在: {wiki_dir}", file=sys.stderr)
        sys.exit(2)

    result = run_check(wiki_dir)
    code = report(result)
    # JSON to stdout for scripting (status mirrors exit semantics)
    out = {
        "status": "issues" if code else "ok",
        "checked": result["checked"],
        "dead_links": result["dead_links"],
        "name_mismatches": result["name_mismatches"],
        "broken_images": result["broken_images"],
        "ambiguities": result["ambiguities"],
    }
    print(json.dumps(out, ensure_ascii=False))
    sys.exit(code)


if __name__ == "__main__":
    main()
