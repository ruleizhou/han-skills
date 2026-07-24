#!/bin/bash
# quota-gate.sh — PreToolUse hook: 派发 Agent 子agent 前查智谱配额，超阈值 deny
# 配合 quota-watch.sh（共享 5min 缓存）。非智谱环境放行。
# 注册: ~/.claude/settings_zhipu.json → PreToolUse matcher "Agent" → 本脚本
#
# 工作流:
#   tool_name=Agent + 智谱 + over_threshold → exit 2 (deny) + stderr 提示埋雷
#   其余 → exit 0 (allow，绝不卡住 Claude)

# 1) 读 PreToolUse stdin（JSON: {tool_name, tool_input, ...}）
input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null)

# 2) 只拦子 agent 派发工具（兼容旧名 Task）
case "$tool" in
  Agent|Task) ;;
  *) exit 0 ;;
esac

# 3) 调 quota-watch.sh（同目录，共享 5min 缓存，开销极小）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
q=$(bash "$SCRIPT_DIR/quota-watch.sh" --threshold 90 2>/dev/null)
[[ -z "$q" ]] && exit 0   # 脚本异常 → 放行（hook 绝不阻断 Claude 正常工作）

over=$(printf '%s' "$q" | jq -r '.over_threshold // false' 2>/dev/null)
skipped=$(printf '%s' "$q" | jq -r '.skipped // false' 2>/dev/null)
[[ "$skipped" == "true" ]] && exit 0   # 非智谱放行

if [[ "$over" == "true" ]]; then
  pct=$(printf '%s' "$q" | jq -r '.percentage // "?"')
  reset_iso=$(printf '%s' "$q" | jq -r '.reset_iso // "?"')
  printf '智谱配额已达 %s%%（≥90%% 阈值），禁止派发子 agent 以防烧爆。请按 CLAUDE.md 第五节：写 /tmp/cc-checkpoint-%s.json 检查点 + 设 CronCreate 在 %s 后唤醒，然后结束本轮（勿重试派发）。\n' "$pct" "${CLAUDE_CODE_SESSION_ID:-unknown}" "$reset_iso" >&2
  exit 2   # PreToolUse deny 标准方式：exit 2 + stderr 反馈给 Claude
fi

exit 0   # 未超阈值 → allow
