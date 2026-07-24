#!/bin/bash
# setup.sh — han-quota-watch 一键接线
# ---------------------------------------------------------------------------
# install.sh 只把 skill 目录 symlink 到 ~/.claude/skills/,但本 skill 的
# 真正生效还依赖两处 ~/.claude 全局配置:
#   1. CLAUDE.md 第五节(驱动 Claude 每轮自动查配额 + 休眠/唤醒规则)
#   2. settings*.json 智谱 profile 的 Agent PreToolUse hook(L2 熔断硬闸)
# 本脚本把这两处幂等缝好,保证 git clone + install.sh + setup.sh 后开箱即用。
#
# 用法:
#   setup.sh              接线(幂等,可重复跑)
#   setup.sh --check      只验证不写,报告接线状态
#   setup.sh --uninstall  移除注入的配置(skill 软链/脚本本体不动)
# ---------------------------------------------------------------------------
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"
SKILL_NAME="han-quota-watch"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
START_MARK="<!-- han-quota-watch:section:start -->"
END_MARK="<!-- han-quota-watch:section:end -->"

MODE="install"
case "${1:-}" in
  --check) MODE="check" ;;
  --uninstall) MODE="uninstall" ;;
  -h|--help)
    sed -n '2,15p' "$0"; exit 0 ;;
  "") MODE="install" ;;
  *) echo "未知参数: $1(可用: --check / --uninstall)"; exit 1 ;;
esac

ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
skip() { printf "  \033[33m→\033[0m %s\n" "$1"; }
fail() { printf "  \033[31m✗\033[0m %s\n" "$1"; }
hdr()  { printf "\n\033[1m%s\033[0m\n" "$1"; }

# ===================== [1/3] 依赖校验 =====================
hdr "[1/3] 依赖校验"
ERR=0
for c in jq curl python3; do
  if command -v "$c" >/dev/null 2>&1; then ok "$c"; else fail "$c 缺失"; ERR=1; fi
done
LINK="$CLAUDE_DIR/skills/$SKILL_NAME"
if [ -L "$LINK" ] || [ -d "$LINK" ]; then ok "skill 软链就位($LINK)"; else fail "$LINK 不存在(先跑 ./install.sh)"; ERR=1; fi
for s in quota-watch.sh quota-gate.sh; do
  if [ -x "$SCRIPT_DIR/$s" ]; then ok "$s 可执行"; else fail "$s 缺 +x"; ERR=1; fi
done
if [ -f "$CONFIG_DIR/claude-md-section.md" ] && [ -f "$CONFIG_DIR/settings-agent-hook.json" ]; then
  ok "config/ 资产齐全"
else
  fail "config/ 资产缺失(claude-md-section.md / settings-agent-hook.json)"; ERR=1
fi
if [ "$ERR" -eq 1 ]; then echo "依赖校验未通过,终止。"; exit 1; fi

# ===================== [2/3] CLAUDE.md 第五节 =====================
hdr "[2/3] CLAUDE.md 第五节"
RES=$(python3 - "$CLAUDE_MD" "$CONFIG_DIR/claude-md-section.md" "$START_MARK" "$END_MARK" "$MODE" <<'PY'
import sys, re, os
md_path, sec_path, start, end, mode = sys.argv[1:6]
section = open(sec_path).read().strip()
md = open(md_path).read() if os.path.exists(md_path) else ""

if mode == "check":
    print("present" if (start in md and end in md) else "absent"); sys.exit()

if mode == "uninstall":
    if start in md and end in md:
        new = re.sub(re.escape(start) + r".*?" + re.escape(end) + r"\n?", "", md, flags=re.DOTALL)
        open(md_path, "w").write(new.rstrip() + "\n")
        print("removed")
    else:
        print("noop")
    sys.exit()

# ---- install ----
# 情况1:已有标记段 → 原地替换
if start in md and end in md:
    new = re.sub(re.escape(start) + r".*?" + re.escape(end), section, md, flags=re.DOTALL)
    if new == md:
        print("noop"); sys.exit()
    open(md_path, "w").write(new); print("replaced"); sys.exit()

# 情况2:有旧无标记第五节(# 五、智谱配额…) → 升级为带标记改进版
m = re.search(r"^# 五、智谱配额[^\n]*\n", md, re.MULTILINE)
if m:
    rest = md[m.end():]
    em = re.search(r"\n(?:# |@\w)", rest)          # 节末 = 下个一级标题 或 @import
    sec_end = m.end() + em.start() + 1 if em else len(md)
    new = md[:m.start()] + section + "\n\n" + md[sec_end:].lstrip("\n")
    open(md_path, "w").write(new); print("upgraded"); sys.exit()

# 情况3:都没有 → 追加(优先插在首个 @import 前,否则文件尾)
if re.search(r"(?m)^@\w", md):
    new = re.sub(r"(?m)^(@\w)", section + "\n\n\\1", md, count=1)
else:
    new = (md.rstrip() + "\n\n" + section + "\n") if md.strip() else (section + "\n")
open(md_path, "w").write(new); print("appended")
PY
)
case "$MODE/$RES" in
  check/present)    ok "CLAUDE.md 已含第五节标记段" ;;
  check/absent)     fail "CLAUDE.md 缺第五节标记段" ;;
  install/replaced) ok "第五节标记段已更新" ;;
  install/upgraded) ok "旧第五节已升级为带标记改进版" ;;
  install/appended) ok "第五节已追加" ;;
  install/noop)     skip "第五节已是最新(无变化)" ;;
  uninstall/removed) skip "第五节标记段已移除" ;;
  uninstall/noop)   skip "无第五节标记段(无需移除)" ;;
  *) fail "CLAUDE.md 处理异常: ${RES:-空}" ;;
esac

# ===================== [3/3] settings Agent hook =====================
hdr "[3/3] settings Agent hook(智谱 profile)"
shopt -s nullglob
profiles=()
for f in "$CLAUDE_DIR"/settings*.json; do
  base=$(jq -r '.env.ANTHROPIC_BASE_URL // ""' "$f" 2>/dev/null)
  if [[ "$base" == *bigmodel.cn* ]]; then profiles+=("$f"); fi
done
if [ "${#profiles[@]}" -eq 0 ]; then
  fail "未找到智谱 profile(~/.claude/settings*.json 无 bigmodel.cn env)"
  exit 1
fi

for f in "${profiles[@]}"; do
  fn=$(basename "$f")
  R=$(python3 - "$f" "$CONFIG_DIR/settings-agent-hook.json" "$MODE" <<'PY'
import json, sys, os
f, hook_file, mode = sys.argv[1:4]
d = json.load(open(f))
pt = d.setdefault("hooks", {}).setdefault("PreToolUse", [])

def has_gate():
    for e in pt:
        if e.get("matcher") == "Agent" and any("quota-gate.sh" in h.get("command", "") for h in e.get("hooks", [])):
            return True
    return False

if mode == "check":
    print("present" if has_gate() else "absent"); sys.exit()

if mode == "uninstall":
    new = [e for e in pt if not (e.get("matcher") == "Agent" and any("quota-gate.sh" in h.get("command", "") for h in e.get("hooks", [])))]
    d["hooks"]["PreToolUse"] = new
    tmp = f + ".tmp"
    json.dump(d, open(tmp, "w"), ensure_ascii=False, indent=2)
    os.replace(tmp, f)
    print("removed"); sys.exit()

# install
if has_gate():
    print("noop"); sys.exit()
hook = json.load(open(hook_file))
hook.pop("_comment", None)
pt.append(hook)
tmp = f + ".tmp"
json.dump(d, open(tmp, "w"), ensure_ascii=False, indent=2)
os.replace(tmp, f)
print("injected")
PY
)
  case "$MODE/$R" in
    check/present)     ok "$fn: Agent hook 已接" ;;
    check/absent)      fail "$fn: 缺 Agent hook" ;;
    install/injected)  ok "$fn: Agent hook 已注入" ;;
    install/noop)      skip "$fn: Agent hook 已存在" ;;
    uninstall/removed) skip "$fn: Agent hook 已移除" ;;
    uninstall/noop)    skip "$fn: 无 Agent hook(无需移除)" ;;
    *) fail "$fn 处理异常: ${R:-空}" ;;
  esac
done

# ===================== 完成 =====================
hdr "完成"
case "$MODE" in
  check)      echo "验证模式(未写任何文件)。有 ✗ 项就跑 setup.sh 修复。" ;;
  install)    echo "接线完成。setup.sh --check 复验 / setup.sh --uninstall 卸载。" ;;
  uninstall)  echo "已移除注入配置。skill 软链/脚本本体未动,重跑 setup.sh 可恢复。" ;;
esac
