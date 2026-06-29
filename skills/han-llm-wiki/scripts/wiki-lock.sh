#!/usr/bin/env bash
# wiki-lock.sh — Wiki 文件锁管理
# 为 wiki 共享文件（index.md / overview.md / log.md 等）提供劝告锁，
# 防止多 agent 并发写入导致数据损坏。
#
# 用法：
#   wiki-lock.sh lock <file>    # 获取锁（阻塞等待，超时 30s）
#   wiki-lock.sh unlock <file>  # 释放锁
#   wiki-lock.sh stale          # 清理僵尸锁（超过 10 分钟的锁文件）
#
# 锁机制：使用 mkdir 原子操作，跨平台无需 flock(1)。
#   wiki/index.md → wiki/.locks/index.md.lock/（目录锁）
#
# 退出码：
#   0 — 成功
#   1 — 获取锁超时或参数错误

set -euo pipefail

STALE_MINUTES=10
LOCK_TIMEOUT=30

# ─── 内部函数 ───────────────────────────────────

# 根据目标文件路径生成锁目录路径
# 例：wiki/index.md → wiki/.locks/index.md.lock
_lock_dir() {
  local target="$1"
  local dir
  dir="$(dirname "$target")"
  local base
  base="$(basename "$target")"
  echo "${dir}/.locks/${base}.lock"
}

# ─── lock：获取文件锁（基于 mkdir 原子操作）────

lock() {
  local target="$1"

  if [ ! -f "$target" ] && [ ! -e "$target" ]; then
    echo "WARN: 目标文件不存在: $target（仍会加锁）" >&2
  fi

  local lockdir
  lockdir=$(_lock_dir "$target")

  # mkdir 是原子操作：成功 = 获取锁，失败 = 锁已被占用
  local waited=0
  while ! mkdir "$lockdir" 2>/dev/null; do
    sleep 1
    waited=$((waited + 1))
    if [ "$waited" -ge "$LOCK_TIMEOUT" ]; then
      echo "ERROR: 获取锁超时 (${LOCK_TIMEOUT}s): $lockdir" >&2
      echo "  可能原因：其他 ingest 会话正在操作同一文件" >&2
      echo "  解决方法：等待其他会话完成，或运行 wiki-lock.sh stale 清理僵尸锁" >&2
      return 1
    fi
  done

  # 记录持有者信息（调试用）
  echo "pid=$$ time=$(date +%s) file=$target" > "${lockdir}/info"
}

# ─── unlock：释放文件锁 ────────────────────────

unlock() {
  local target="$1"
  local lockdir
  lockdir=$(_lock_dir "$target")

  if [ -d "$lockdir" ]; then
    rm -rf "$lockdir"
  fi
}

# ─── stale：清理僵尸锁 ────────────────────────

stale() {
  local now
  now=$(date +%s)
  local cleaned=0

  # 从当前目录向下查找所有 .locks/*.lock 目录
  while IFS= read -r ld; do
    [ -z "$ld" ] && continue
    # .lock 是目录
    [ -d "$ld" ] || continue
    local info_file="$ld/info"
    local mtime
    mtime=$(stat -c %Y "$info_file" 2>/dev/null || stat -c %Y "$ld" 2>/dev/null || echo 0)
    local age=$(( (now - mtime) / 60 ))

    if [ "$age" -gt "$STALE_MINUTES" ]; then
      local holder
      holder=$(cat "$info_file" 2>/dev/null || echo "unknown")
      echo "清理僵尸锁: $ld (${age}分钟前) [$holder]"
      rm -rf "$ld"
      cleaned=$((cleaned + 1))
    fi
  done < <(find . -path '*/.locks/*.lock' -type d 2>/dev/null)

  if [ "$cleaned" -eq 0 ]; then
    echo "未发现僵尸锁"
  else
    echo "已清理 ${cleaned} 个僵尸锁"
  fi
}

# ─── 主入口 ─────────────────────────────────────

case "${1:-help}" in
  lock)
    if [ -z "${2:-}" ]; then
      echo "用法: wiki-lock.sh lock <文件路径>" >&2
      exit 1
    fi
    lock "$2"
    ;;
  unlock)
    if [ -z "${2:-}" ]; then
      echo "用法: wiki-lock.sh unlock <文件路径>" >&2
      exit 1
    fi
    unlock "$2"
    ;;
  stale)
    stale
    ;;
  help|*)
    echo "wiki-lock.sh — Wiki 文件锁管理"
    echo ""
    echo "用法:"
    echo "  wiki-lock.sh lock <file>    获取锁（阻塞，超时 ${LOCK_TIMEOUT}s）"
    echo "  wiki-lock.sh unlock <file>  释放锁"
    echo "  wiki-lock.sh stale          清理超过 ${STALE_MINUTES} 分钟的僵尸锁"
    echo ""
    echo "锁目录位置：<目标文件同目录>/.locks/<文件名>.lock/"
    ;;
esac
