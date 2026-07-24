#!/bin/bash
# quota-watch.sh — 智谱 Coding Plan 配额判定
# 由 ~/.claude/CLAUDE.md 第五节"智谱配额自动休眠规则"每轮自动调用
# 逻辑源自 ~/.claude/statusline-command.sh 的 fetch_zhipu_quota()，保持一致避免分叉
#
# 用法: quota-watch.sh [--threshold N]    默认 threshold=90
# 非智谱环境(ANTHROPIC_BASE_URL 不含 bigmodel.cn)直接放行
#
# 输出 JSON(stdout), 供 Claude 解析:
#   { over_threshold, percentage, level, reset_ts, reset_iso, sleep_seconds, threshold, skipped? }

# ---------- 参数 ----------
THRESHOLD=90
while [[ $# -gt 0 ]]; do
  case "$1" in
    --threshold) THRESHOLD="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# ---------- provider 检测：非智谱透明放行 ----------
if [[ "${ANTHROPIC_BASE_URL,,}" != *bigmodel.cn* ]]; then
  printf '{"over_threshold":false,"skipped":true,"reason":"non-zhipu provider"}\n'
  exit 0
fi
TOKEN="${ANTHROPIC_AUTH_TOKEN:-}"
if [[ -z "$TOKEN" ]]; then
  printf '{"over_threshold":false,"skipped":true,"reason":"no ANTHROPIC_AUTH_TOKEN"}\n'
  exit 0
fi

# ---------- 配额查询：复用 statusline 缓存 + API ----------
# 缓存 /tmp/cc-statusline-quota-${USER}.cache  格式 level|pct|reset_ts  TTL 300s（与 statusline 共享，省 API）
CACHE="/tmp/cc-statusline-quota-${USER}.cache"
RAW_JSON="/tmp/cc-statusline-quota-${USER}.raw.json"
TTL=300
NOW=$(date +%s)
level="" pct="" reset_ts=""

# 1) 缓存命中(5min 内)?
if [[ -s "$CACHE" ]]; then
  mtime=$(stat -c %Y "$CACHE" 2>/dev/null || echo 0)
  if (( NOW - mtime < TTL )); then
    IFS='|' read -r level pct reset_ts < "$CACHE"
  fi
fi

# 2) 缓存未命中 → 打 API（最坏 3s）
if [[ -z "$pct" ]]; then
  resp=$(curl -s --max-time 3 -H "Authorization: $TOKEN" \
    "https://open.bigmodel.cn/api/monitor/usage/quota/limit" 2>/dev/null)
  if [[ -n "$resp" ]]; then
    printf '%s\n' "$resp" > "$RAW_JSON" 2>/dev/null
    level=$(printf '%s' "$resp" | jq -r '.data.level // ""' 2>/dev/null)
    pct=$(printf '%s' "$resp" | jq -r \
      '([.data.limits[]? | select(.type=="TOKENS_LIMIT")][0].percentage) // ""' 2>/dev/null)
    reset_raw=$(printf '%s' "$resp" | jq -r \
      '([.data.limits[]? | select(.type=="TOKENS_LIMIT")][0]
       | (.nextResetTime // .resetTime // .resetTimestamp // .windowEnd
          // .expireTime // .endTime // .resetAt)) // ""' 2>/dev/null)
    # 毫秒戳 → Unix 秒
    if [[ "$reset_raw" =~ ^[0-9]{13,}$ ]]; then
      reset_ts=$(( reset_raw / 1000 ))
    elif [[ "$reset_raw" =~ ^[0-9]+$ ]]; then
      reset_ts="$reset_raw"
    else
      reset_ts=$(date -d "$reset_raw" +%s 2>/dev/null || echo "")
    fi
    # 回写缓存（与 statusline 共享）
    if [[ -n "$level" || -n "$pct" ]]; then
      printf '%s|%s|%s\n' "$level" "$pct" "$reset_ts" > "${CACHE}.tmp" && mv "${CACHE}.tmp" "$CACHE"
    fi
  fi
fi

# 3) 解析失败 → 透明放行（不阻断 Claude）
if [[ -z "$pct" || "$pct" == "null" ]]; then
  printf '{"over_threshold":false,"skipped":true,"reason":"quota query failed","percentage":null}\n'
  exit 0
fi

# ---------- 判定 ----------
reset_iso=""
[[ -n "$reset_ts" && "$reset_ts" =~ ^[0-9]+$ ]] && reset_iso=$(date -d "@$reset_ts" '+%Y-%m-%d %H:%M' 2>/dev/null)

# ---------- sleep_seconds（缓冲策略）----------
BUFFER=120   # 重置时刻有抖动(延迟几十秒)，留 2 分钟缓冲 —— 与 CLAUDE.md cron 换算 reset_ts+120 对齐
if [[ -z "$reset_ts" || ! "$reset_ts" =~ ^[0-9]+$ ]]; then
  sleep_seconds=0    # reset_ts 缺失 → 无法估算，交由 Claude 按 reset_iso 自行判断
else
  sleep_seconds=$(( reset_ts - NOW + BUFFER ))
  (( sleep_seconds < 0 )) && sleep_seconds=0   # 已过重置时刻 → 不等
fi

# ---------- 输出 ----------
jq -n \
  --argjson pct "$pct" \
  --arg level "$level" \
  --argjson reset_ts "${reset_ts:-0}" \
  --arg reset_iso "$reset_iso" \
  --argjson sleep_seconds "$sleep_seconds" \
  --argjson threshold "$THRESHOLD" \
  '{over_threshold: ($pct >= $threshold), percentage:$pct, level:$level, reset_ts:$reset_ts, reset_iso:$reset_iso, sleep_seconds:$sleep_seconds, threshold:$threshold}'
