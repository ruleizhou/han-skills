---
name: han-quota-watch
description: 智谱 Coding Plan 配额判定与自动休眠唤醒。由 CLAUDE.md 第五节每轮自动调用，查询 5 小时 token 用量，超阈值时写检查点并设 CronCreate(durable)唤醒，实现 429 后会话主动恢复。
---

# han-quota-watch

智谱 GLM Coding Plan 套餐有每 5 小时 token 用量上限，超限触发 `API Error: Request rejected (429)`。本 skill 提供 `quota-watch.sh` 判定当前用量是否超阈值，配合 CLAUDE.md 的休眠/唤醒规则实现配额耗尽后会话自动恢复。

## 工作方式（无需手动触发）

由 `~/.claude/CLAUDE.md` 第五节"智谱配额自动休眠规则"驱动，Claude 每轮开始前自动调用：

```bash
bash ~/.claude/skills/han-quota-watch/scripts/quota-watch.sh
```

- `over_threshold: false` → 正常处理请求
- `over_threshold: true` → 写检查点（**固定名 + SID 双写**）+ CronCreate（**durable: true** 写磁盘）+ 结束本轮（详见 CLAUDE.md 第五节）

核心思路：唤醒闹钟在配额烧到阈值（90%）时、Claude 还能执行时就埋好，reset 时间一到 CronCreate 自动注入 prompt 唤醒会话。**durable: true 落盘**，跨夜/换会话不依赖"别关终端"。

## 脚本

- `scripts/quota-watch.sh [--threshold N]` — 默认阈值 90
- 配额查询逻辑源自 `~/.claude/statusline-command.sh` 的 `fetch_zhipu_quota()`，共享缓存 `/tmp/cc-statusline-quota-${USER}.cache`（5min TTL）
- 非智谱环境（`ANTHROPIC_BASE_URL` 不含 `bigmodel.cn`）自动放行
- API 不可达/解析失败时返回 `over_threshold:false`，透明放行不阻断

## 子 agent 防护（PreToolUse hook）

`scripts/quota-gate.sh` 是 PreToolUse hook，注册在 `~/.claude/settings*.json`（智谱 profile，matcher：`Agent`）。主会话每次派发子 agent 前，harness 自动跑它：超阈值 → `exit 2` deny + stderr 提示埋雷；其余放行。这是防子 agent 在轮中烧爆配额的**硬闸**（harness 级，不依赖 Claude 自觉）。

## 安装接线（首次 / 换机器）

> **关键**：`install.sh` 只 symlink skill 目录到 `~/.claude/skills/`，**不接** CLAUDE.md 第五节和 settings 的 Agent hook。装完必须跑 setup.sh 才会真正生效。

```bash
bash ~/.claude/skills/han-quota-watch/scripts/setup.sh              # 一键接线（幂等）
bash ~/.claude/skills/han-quota-watch/scripts/setup.sh --check      # 验证接线状态
bash ~/.claude/skills/han-quota-watch/scripts/setup.sh --uninstall  # 卸载注入（脚本本体不动）
```

setup.sh 做两件事：① 把第五节（带边界标记 `<!-- han-quota-watch:section:* -->`）幂等注入 `~/.claude/CLAUDE.md`（已有标记→替换，有旧无标记节→升级，都没有→追加）；② 给所有智谱 profile（`settings*.json` 含 `bigmodel.cn` env）幂等加 Agent hook。**重复跑安全**，不污染其他配置。

## Workflow 熔断模板

Workflow 内部的 `agent()` 调用**不经过主会话 PreToolUse hook**（在 workflow 脚本内部派发），需在脚本层熔断：

```js
const q = await agent('运行命令并返回原始 JSON：bash ~/.claude/skills/han-quota-watch/scripts/quota-watch.sh', {effort:'low'})
const quota = JSON.parse(String(q).match(/\{[\s\S]*\}/)[0])
if (quota.over_threshold) { log('配额超阈值，熔断'); break }
```

子 agent 失败（含 429）会返回 null，workflow 用 `.filter(Boolean)` 容错。

## 已知限制

`quota-watch.sh` 的 `percentage` 偶有假数据（曾出现全程显示 0% 却 429 烧穿）。长任务**不要只靠 percentage**，改用 batch 计数保守控速（实测每 5h 窗口约 15 个重 subagent 即 429，保守 ≤13 个就主动埋雷）。详见 CLAUDE.md 第五节"percentage 不可靠时的保守控速"。
