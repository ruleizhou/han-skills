#!/usr/bin/env python3
"""BM25-based wiki search engine — pure Python stdlib, zero dependencies.

Hybrid tokenizer: word-level for English/numbers, character-level (unigram) for
Chinese/CJK.  Supports incremental index updates via file mtime comparison.

Usage:
  python3 wiki-search.py index  [--wiki .]
  python3 wiki-search.py search "query" [--top-k 10] [--wiki .]
  python3 wiki-search.py stats [--wiki .]

注: --wiki 指向 vault 根目录(内容页 00-Home/.. 在顶层, wiki/ 仅放基础设施)。
SKIP_PATTERNS 用 "wiki/xxx" 相对前缀, 故 wiki_dir 必须为 vault 根。
"""

import argparse
import json
import math
import os
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

# ─── BM25 Parameters ──────────────────────────────────────

K1 = 1.5   # term frequency saturation
B = 0.75   # length normalization (0 = no norm, 1 = full)

# ─── Tokens to exclude from indexing ──────────────────────

# Common Chinese stop characters (的/了/是/在 etc.) — character-level tokens
# that carry little semantic meaning
CJK_STOP_CHARS: set = set()

# English stop words — high-frequency, low-semantic-value tokens
EN_STOP_WORDS: set = {"the", "a", "an", "is", "are", "was", "were", "be", "been",
    "being", "have", "has", "had", "do", "does", "did", "will", "would", "could",
    "should", "may", "might", "can", "shall", "to", "of", "in", "for", "on", "with",
    "at", "by", "from", "as", "into", "through", "during", "before", "after",
    "above", "below", "between", "and", "but", "or", "not", "no", "if", "then",
    "than", "that", "this", "these", "those", "it", "its", "he", "she", "they",
    "we", "you", "i", "my", "your", "our", "their", "all", "each", "every",
    "some", "any", "both", "few", "more", "most", "other", "such", "only",
    "own", "same", "so", "just", "about", "up", "out", "also", "very", "too"}

# ─── Pages excluded from search index ─────────────────────

# These wiki structural pages should not appear in search results
SKIP_PATTERNS = [
    "wiki/log.md", "wiki/index.md", "wiki/hot.md",
    "wiki/overview.md", "wiki/.ingest-folders.yaml",
]

# ─── Tokenizer ────────────────────────────────────────────


def is_cjk(ch: str) -> bool:
    """Check if a character is in the CJK Unified Ideograph range."""
    cp = ord(ch)
    # CJK Unified Ideographs + Extensions A-B + Compatibility
    return (0x4E00 <= cp <= 0x9FFF or   # CJK Unified
            0x3400 <= cp <= 0x4DBF or   # CJK Extension A
            0x20000 <= cp <= 0x2A6DF or # CJK Extension B
            0xF900 <= cp <= 0xFAFF)     # CJK Compatibility


def tokenize(text: str) -> List[str]:
    """Hybrid tokenizer: English/numbers as word tokens, CJK as character unigrams.

    Example:
        "Transformer 架构" → ['transformer', '架', '构']
        "DMA 驱动与 dma-buf" → ['dma', '驱', '动', '与', 'dma', 'buf']
    """
    tokens: List[str] = []
    # Track positions already consumed by word-level regex, to avoid
    # double-tokenizing characters that appear inside matched words.
    consumed: set = set()

    # Pass 1: English words and numbers (consecutive [a-zA-Z0-9]+)
    for m in re.finditer(r'[a-zA-Z0-9]+', text):
        token = m.group().lower()
        if token not in EN_STOP_WORDS and len(token) > 0:
            tokens.append(token)
        # Mark these positions as consumed
        for pos in range(m.start(), m.end()):
            consumed.add(pos)

    # Pass 2: CJK characters as unigrams (only at unconsumed positions)
    for i, ch in enumerate(text):
        if i in consumed:
            continue
        if is_cjk(ch):
            if ch not in CJK_STOP_CHARS:
                tokens.append(ch)

    return tokens


# ─── Index I/O ────────────────────────────────────────────

INDEX_FILENAME = ".search_index.json"


def load_index(index_path: Path) -> Optional[Dict[str, Any]]:
    """Load existing index, or None if not found."""
    if not index_path.exists():
        return None
    with open(index_path, "r", encoding="utf-8") as f:
        return json.load(f)


def save_index(index_path: Path, idx: Dict[str, Any]) -> None:
    """Save index as JSON."""
    idx["built_at"] = _timestamp()
    with open(index_path, "w", encoding="utf-8") as f:
        json.dump(idx, f, ensure_ascii=False, indent=2)


def _timestamp() -> str:
    import time
    return time.strftime("%Y-%m-%d %H:%M:%S")


# ─── Index Building ───────────────────────────────────────


def should_skip(path_relative: str) -> bool:
    """Check if a wiki page should be excluded from search index."""
    path_lower = path_relative.lower()
    for pat in SKIP_PATTERNS:
        if path_lower == pat.lower():
            return True
    return False


def file_mtime(path: Path) -> int:
    """Get file modification time as integer seconds."""
    try:
        return int(os.path.getmtime(path))
    except OSError:
        return 0


def parse_frontmatter_field(text: str, field: str) -> Optional[str]:
    """Extract a scalar YAML frontmatter field (e.g. 'type'), or None.

    Mirrors wiki-lint.py's parse_title regex so the two scripts agree on
    frontmatter boundaries.  Frontmatter must start the file; the closing
    marker is a '---' on its own line.
    """
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end == -1:
        return None
    fm = text[3:end]
    m = re.search(rf"^{field}:\s*(.+?)\s*$", fm, re.MULTILINE)
    if not m:
        return None
    return m.group(1).strip().strip("\"'")


def tokenize_file(filepath: Path) -> Tuple[Counter, int, Optional[str]]:
    """Tokenize a file; return (term_frequencies, doc_length, frontmatter_type)."""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            text = f.read()
    except (IOError, UnicodeDecodeError) as e:
        print(f"WARN: 无法读取 {filepath}: {e}", file=sys.stderr)
        return Counter(), 0, None

    doc_type = parse_frontmatter_field(text, "type")

    # Strip YAML frontmatter (between --- markers)
    if text.startswith("---"):
        end = text.find("---", 3)
        if end != -1:
            text = text[end + 3:]

    tokens = tokenize(text)
    return Counter(tokens), len(tokens), doc_type


def build_index(wiki_dir: Path, old_idx: Optional[Dict]) -> Dict[str, Any]:
    """Build or incrementally update the search index.

    Incremental strategy: for each existing doc, compare mtime with cached
    value.  Re-tokenize only if file changed or is new.
    """
    wiki_dir = wiki_dir.resolve()

    # Collect all .md files under wiki/ that should be indexed
    current_files: Dict[str, Path] = {}
    for root, dirs, files in os.walk(wiki_dir):
        # Skip hidden directories (like .locks/)
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        for f in files:
            if not f.endswith(".md"):
                continue
            full = Path(root) / f
            rel = str(full.relative_to(wiki_dir)).replace("\\", "/")
            if should_skip(rel):
                continue
            current_files[rel] = full

    print(f"扫描到 {len(current_files)} 个可索引页面", file=sys.stderr)

    # Prepare index structure
    idx: Dict[str, Any] = {
        "version": 1,
        "built_at": _timestamp(),
        "wiki_dir": str(wiki_dir),
        "N": 0,
        "avgdl": 0.0,
        "docs": {},
        "df": {},
    }

    # Reuse cached docs from old index if file unchanged
    old_docs = old_idx.get("docs", {}) if old_idx else {}
    new_docs: Dict[str, Any] = {}
    total_tokens = 0

    for rel, full in sorted(current_files.items()):
        mtime = file_mtime(full)
        old_doc = old_docs.get(rel)

        if old_doc and old_doc.get("mtime") == mtime:
            # Unchanged — reuse cached tokens
            cached_tf = old_doc.get("tf", {})
            cached_len = old_doc.get("length", 0)
            cached_type = old_doc.get("type")
            # Backfill `type` for docs indexed before frontmatter-type support
            # existed (cached doc lacks the field). One-time read; once
            # populated it is cached and reused on subsequent runs.
            if cached_type is None:
                try:
                    with open(full, "r", encoding="utf-8") as fh:
                        cached_type = parse_frontmatter_field(fh.read(), "type")
                except (IOError, UnicodeDecodeError):
                    cached_type = None
            new_docs[rel] = {
                "title": Path(rel).stem,
                "type": cached_type,
                "length": cached_len,
                "mtime": mtime,
                "tf": cached_tf,
            }
            total_tokens += cached_len
            info = " (复用)"
        else:
            # Changed or new — re-tokenize
            tf, length, doc_type = tokenize_file(full)
            if length == 0:
                continue  # Skip empty files
            new_docs[rel] = {
                "title": Path(rel).stem,
                "type": doc_type,
                "length": length,
                "mtime": mtime,
                "tf": {k: v for k, v in tf.items()},
            }
            total_tokens += length
            info = " (新建)" if not old_doc else " (更新)"

        print(f"  {rel}: {new_docs[rel]['length']} tokens{info}", file=sys.stderr)

    # Compute global statistics
    N = len(new_docs)
    if N == 0:
        # Empty wiki — return minimal index
        idx["N"] = 0
        idx["avgdl"] = 0.0
        idx["docs"] = {}
        idx["df"] = {}
        return idx

    avgdl = total_tokens / N

    # Compute document frequency (df) for each token
    df: Dict[str, int] = {}
    for rel, doc in new_docs.items():
        for token in doc["tf"]:
            df[token] = df.get(token, 0) + 1

    idx["N"] = N
    idx["avgdl"] = round(avgdl, 2)
    idx["docs"] = new_docs
    idx["df"] = df

    print(f"索引完成: N={N}, avgdl={avgdl:.1f}, 唯一词={len(df)}", file=sys.stderr)
    return idx


# ─── BM25 Scoring ─────────────────────────────────────────


def idf(token: str, N: int, df: Dict[str, int]) -> float:
    """Inverse document frequency — smoothed variant."""
    n = df.get(token, 0)
    return math.log((N - n + 0.5) / (n + 0.5) + 1.0)


def bm25_score(query_tokens: List[str], doc: Dict, N: int, avgdl: float,
               df: Dict[str, int]) -> float:
    """Compute BM25 score for a single document against query tokens."""
    if len(query_tokens) == 0:
        return 0.0

    tf_map = doc.get("tf", {})
    doclen = doc.get("length", 1)
    score = 0.0

    # Count query token frequencies for term frequency in query
    qf = Counter(query_tokens)

    for token, qt in qf.items():
        if token not in tf_map:
            continue
        dt = tf_map[token]
        # IDF component
        idf_val = idf(token, N, df)
        # BM25 numerator and denominator
        numerator = dt * (K1 + 1)
        denominator = dt + K1 * (1 - B + B * doclen / avgdl)
        score += idf_val * numerator / denominator * qt

    return score


def resolve_type(path: str, doc: Dict) -> str:
    """Page type: prefer frontmatter `type` (captured at index time), else
    infer from path.  Generic-mode wikis file pages under concepts/ etc.;
    engineering-mode wikis carry `type` in frontmatter, which the path rule
    cannot recover — so the frontmatter value wins when present.
    """
    t = doc.get("type")
    if t:
        return t
    if "sources/" in path:    return "source"
    if "concepts/" in path:   return "concept"
    if "entities/" in path:   return "entity"
    if "analyses/" in path:   return "analysis"
    if "cards/" in path:      return "card"
    return "unknown"


def search(query: str, wiki_dir: Path, top_k: int = 10) -> List[Dict[str, Any]]:
    """Search the wiki index and return top-k results."""
    index_path = wiki_dir / INDEX_FILENAME

    if not index_path.exists():
        print("ERROR: 搜索索引不存在。请先执行: python3 wiki-search.py index", file=sys.stderr)
        return []

    idx = load_index(index_path)
    if idx is None or idx.get("N", 0) == 0:
        print("WARN: 索引为空，没有可搜索的页面", file=sys.stderr)
        return []

    N = idx["N"]
    avgdl = idx["avgdl"]
    df = idx["df"]
    docs = idx["docs"]

    query_tokens = tokenize(query)
    if not query_tokens:
        print("WARN: 查询词 token 为空", file=sys.stderr)
        return []

    print(f"查询: \"{query}\" | tokens: {query_tokens}", file=sys.stderr)

    # Score every document
    scores: List[Tuple[str, Dict, float]] = []
    for path, doc in docs.items():
        s = bm25_score(query_tokens, doc, N, avgdl, df)
        if s > 0:
            scores.append((path, doc, s))

    # Sort by score descending, take top-k
    scores.sort(key=lambda x: -x[2])
    top = scores[:top_k]

    results = []
    for path, doc, s in top:
        results.append({
            "path": path,
            "title": doc.get("title", Path(path).stem),
            "type": resolve_type(path, doc),
            "score": round(s, 2),
        })

    print(f"返回 {len(results)} 条结果/{len(scores)} 条命中", file=sys.stderr)
    return results


# ─── Stats ────────────────────────────────────────────────


def show_stats(wiki_dir: Path) -> Dict[str, Any]:
    """Show search index statistics."""
    index_path = wiki_dir / INDEX_FILENAME
    if not index_path.exists():
        return {"error": "索引不存在"}
    idx = load_index(index_path)
    if idx is None:
        return {"error": "索引为空"}
    return {
        "version": idx.get("version"),
        "built_at": idx.get("built_at"),
        "N": idx["N"],
        "avgdl": idx["avgdl"],
        "unique_terms": len(idx["df"]),
        "wiki_dir": idx.get("wiki_dir"),
    }


# ─── TF-IDF Cosine Rerank ──────────────────────────────────


def tfidf_vector(tokens: List[str], df: Dict[str, int], N: int) -> Dict[str, float]:
    """Convert token list to a sparse TF-IDF vector.

    Uses the same IDF formula as BM25 for consistency.
    """
    vec: Dict[str, float] = {}
    tf = Counter(tokens)
    for t, f in tf.items():
        idf_val = idf(t, N, df)
        vec[t] = f * idf_val
    return vec


def cosine_similarity(vec_a: Dict[str, float], vec_b: Dict[str, float]) -> float:
    """Cosine similarity between two sparse vectors."""
    if not vec_a or not vec_b:
        return 0.0
    # Dot product over shared keys
    dot = sum(vec_a.get(k, 0.0) * vec_b.get(k, 0.0) for k in set(vec_a) | set(vec_b))
    # L2 norms
    norm_a = math.sqrt(sum(v * v for v in vec_a.values()))
    norm_b = math.sqrt(sum(v * v for v in vec_b.values()))
    return dot / (norm_a * norm_b) if norm_a > 0 and norm_b > 0 else 0.0


def rerank(query: str, candidate_paths: List[str], wiki_dir: Path,
           top_k: int = 5) -> List[Dict[str, Any]]:
    """Re-rank BM25 candidates using TF-IDF cosine similarity.

    BM25 is good at recall (finding relevant docs) but its term-frequency
    saturation can hide semantic relevance.  Cosine similarity over TF-IDF
    vectors captures the overall topical match and often surfaces the most
    relevant result to the top.

    Args:
        query: Original user query (no contextual prefix — for semantic match)
        candidate_paths: List of wiki-relative paths from BM25 (e.g. ["concepts/DMA.md"])
        wiki_dir: Path to wiki root
        top_k: Number of results to return after re-ranking
    """
    index_path = wiki_dir / INDEX_FILENAME
    if not index_path.exists():
        print("ERROR: 搜索索引不存在", file=sys.stderr)
        return []

    idx = load_index(index_path)
    if idx is None or idx.get("N", 0) == 0:
        return []

    N = idx["N"]
    df = idx["df"]
    docs = idx["docs"]

    query_tokens = tokenize(query)
    if not query_tokens:
        return []
    query_vec = tfidf_vector(query_tokens, df, N)

    print(f"重排序: \"{query}\" | BM25候选={len(candidate_paths)} → Top-{top_k}", file=sys.stderr)

    scored: List[Tuple[str, Dict, float]] = []
    for path in candidate_paths:
        doc = docs.get(path)
        if not doc:
            continue
        # Represent document as TF-IDF vector from its token frequencies
        doc_tokens = list(doc.get("tf", {}).keys())
        doc_vec = tfidf_vector(doc_tokens, df, N)
        sim = cosine_similarity(query_vec, doc_vec)
        if sim > 0:
            scored.append((path, doc, sim))

    scored.sort(key=lambda x: -x[2])
    top = scored[:top_k]

    results = []
    for path, doc, sim in top:
        results.append({
            "path": path,
            "title": doc.get("title", Path(path).stem),
            "type": resolve_type(path, doc),
            "cosine_score": round(sim, 4),
        })

    print(f"重排序完成: {len(results)} 条结果", file=sys.stderr)
    return results


# ─── CLI ──────────────────────────────────────────────────


def main() -> None:
    parser = argparse.ArgumentParser(
        description="BM25 中文/英文混合检索引擎（零依赖，纯 stdlib）",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""示例:
  python3 wiki-search.py index --wiki .
  python3 wiki-search.py search "DMA 驱动" --top-k 5 --wiki .
  python3 wiki-search.py stats --wiki .""",
    )

    sub = parser.add_subparsers(dest="command", help="子命令")

    # --- index ---
    p_index = sub.add_parser("index", help="构建或增量更新搜索索引")
    p_index.add_argument("--wiki", default=".", help="wiki 目录路径，vault 根（默认: .，内容页在顶层）")

    # --- search ---
    p_search = sub.add_parser("search", help="搜索 wiki 页面")
    p_search.add_argument("query", help="搜索查询（支持中文）")
    p_search.add_argument("--top-k", type=int, default=10, help="返回结果数（默认: 10）")
    p_search.add_argument("--wiki", default=".", help="wiki 目录路径，vault 根（默认: .，内容页在顶层）")

    # --- stats ---
    p_stats = sub.add_parser("stats", help="显示索引统计信息")
    p_stats.add_argument("--wiki", default=".", help="wiki 目录路径，vault 根（默认: .，内容页在顶层）")

    # --- rerank ---
    p_rerank = sub.add_parser("rerank", help="对 BM25 候选集做 TF-IDF 余弦重排序")
    p_rerank.add_argument("query", help="原始查询（用于语义匹配）")
    p_rerank.add_argument("--candidates", required=True,
                          help="BM25 候选路径 JSON 数组，如 '[\"concepts/X.md\",\"concepts/Y.md\"]'")
    p_rerank.add_argument("--top-k", type=int, default=5, help="重排序后返回数（默认: 5）")
    p_rerank.add_argument("--wiki", default=".", help="wiki 目录路径，vault 根（默认: .，内容页在顶层）")

    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        sys.exit(1)

    wiki_dir = Path(args.wiki)

    if args.command == "index":
        if not wiki_dir.is_dir():
            print(f"ERROR: wiki 目录不存在: {wiki_dir}", file=sys.stderr)
            sys.exit(1)
        index_path = wiki_dir / INDEX_FILENAME
        old_idx = load_index(index_path) if index_path.exists() else None
        idx = build_index(wiki_dir, old_idx)
        save_index(index_path, idx)
        # Also output stats as JSON for scripting
        resp = {"status": "ok", "N": idx["N"], "avgdl": idx["avgdl"],
                "unique_terms": len(idx["df"]), "built_at": idx["built_at"]}
        print(json.dumps(resp, ensure_ascii=False))

    elif args.command == "search":
        if not wiki_dir.is_dir():
            print(f"ERROR: wiki 目录不存在: {wiki_dir}", file=sys.stderr)
            sys.exit(1)
        results = search(args.query, wiki_dir, args.top_k)
        # JSON to stdout, info already went to stderr
        print(json.dumps({"results": results}, ensure_ascii=False))

    elif args.command == "stats":
        stats = show_stats(wiki_dir)
        print(json.dumps(stats, ensure_ascii=False, indent=2))

    elif args.command == "rerank":
        if not wiki_dir.is_dir():
            print(f"ERROR: wiki 目录不存在: {wiki_dir}", file=sys.stderr)
            sys.exit(1)
        try:
            candidates = json.loads(args.candidates)
            if not isinstance(candidates, list):
                print("ERROR: --candidates 必须是 JSON 数组", file=sys.stderr)
                sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"ERROR: --candidates JSON 解析失败: {e}", file=sys.stderr)
            sys.exit(1)
        results = rerank(args.query, candidates, wiki_dir, args.top_k)
        print(json.dumps({"results": results}, ensure_ascii=False))


if __name__ == "__main__":
    main()
