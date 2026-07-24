# han-quota-watch

智谱 Coding Plan 配额监控 + 自动休眠唤醒，429 后会话主动恢复。camx-chi `/understand` 110-batch 马拉松（跨 5 个配额窗口）实战验证。

## 四层协作原理

| 层 | 组件 | 位置 | 作用 |
|----|------|------|------|
| **L0 规则** | CLAUDE.md 第五节 | `~/.claude/CLAUDE.md` | 每轮开始前 Claude 自觉查配额 + 休眠/恢复流程 |
| **L1 查询** | `scripts/quota-watch.sh` | skill 自带 | 查智谱 API，输出 `over_threshold` 判定 |
| **L2 熔断** | `scripts/quota-gate.sh` + settings Agent hook | skill + `~/.claude/settings*.json` | PreToolUse 硬闸，派发子 agent 前 deny |
| **L3 唤醒** | CronCreate(durable) + 检查点 | 运行时 `/tmp/cc-checkpoint-*.json` | reset 后注入 prompt 唤醒会话续传 |

**关键**：L0 和 L2 在 `~/.claude` 全局配置里，`install.sh` 不会自动接——必须跑 `setup.sh`。

## 部署（git clone 后开箱即用）

```bash
git clone <repo> han-skills && cd han-skills
./install.sh                                            # symlink skill 到 ~/.claude/skills/
bash ~/.claude/skills/han-quota-watch/scripts/setup.sh   # 接 CLAUDE.md 第五节 + settings Agent hook
bash ~/.claude/skills/han-quota-watch/scripts/setup.sh --check   # 验证
```

## 验证清单

- [ ] `setup.sh --check` 全 ✓（依赖/软链/执行位/CLAUDE.md 标记/settings hook）
- [ ] `quota-watch.sh` 返回合法 JSON（智谱时 `percentage` 有值；非智谱 `skipped:true`）
- [ ] `grep -c 'han-quota-watch:section' ~/.claude/CLAUDE.md` ≥ 2（start+end 标记）
- [ ] `jq '.hooks.PreToolUse[] | select(.matcher=="Agent")' ~/.claude/settings.json` 含 `quota-gate.sh`
- [ ] **幂等**：setup.sh 连跑两次，第二次全 SKIP
- [ ] （熔断实测）`quota-watch.sh --threshold 1` 后派 Agent，应被 `exit 2` deny（测完恢复阈值）

## 卸载

```bash
bash ~/.claude/skills/han-quota-watch/scripts/setup.sh --uninstall
```

移除 CLAUDE.md 第五节标记段 + settings 的 quota-gate Agent hook。**skill 软链/脚本本体不动**，重跑 setup.sh 可恢复。

## 故障排查

| 症状 | 排查 |
|------|------|
| 没拦住 / 没休眠 | `setup.sh --check`，看 CLAUDE.md/settings 是否接好；确认**生效的**是哪个 settings profile（可能 settings.json 漏 Agent hook，只有 settings_zhipu.json 有） |
| 跨夜 cron 没响 | 确认 CronCreate 用 `durable:true`（第五节改进版）；session-only(durable:false) 跨夜失约 |
| percentage 全程 0% 却 429 | percentage 不可靠，改 batch 计数（≤13/窗口），见第五节"保守控速" |
| 检查点找不到 | 用双写的**固定名** `/tmp/cc-checkpoint-<标识>.json`，不依赖会变动的 SID |

## 配置资产（可迁移）

- `config/claude-md-section.md` — 第五节全文（带边界标记，setup.sh 注入用）
- `config/settings-agent-hook.json` — Agent PreToolUse hook 片段
- `scripts/setup.sh` — 一键接线 / `--check` / `--uninstall`
- `scripts/quota-watch.sh` / `quota-gate.sh` — L1 查询 / L2 熔断（原样保留，不动逻辑）

## 外部依赖

- 环境变量：`ANTHROPIC_BASE_URL`（含 `bigmodel.cn` 触发智谱逻辑）、`ANTHROPIC_AUTH_TOKEN`（API 认证）
- 共享缓存：`/tmp/cc-statusline-quota-${USER}.cache`（与 `~/.claude/statusline-command.sh` 共用，5min TTL）
- 命令：`jq` / `curl` / `python3`
