<!-- han-quota-watch:section:start -->
# 五、智谱配额自动休眠规则

> **仅智谱 Coding Plan(`ANTHROPIC_BASE_URL` 含 `bigmodel.cn`)生效。** DeepSeek/其他 provider 无此限制,脚本自动放行。

智谱 Coding Plan 每 5 小时 TOKENS_LIMIT 配额限制。长任务中配额 ≥90% 时自动休眠等待重置。

## 每轮开始前必须执行

在处理用户请求之前(即使是第一轮"你好"),先用以下命令检查配额:

```bash
bash ~/.claude/skills/han-quota-watch/scripts/quota-watch.sh
```

## 判定与行动

- **`over_threshold: false`** → 正常处理用户请求,不做任何提醒
- **`over_threshold: true`(≥90%)** → **强制休眠,不处理用户本轮请求**

## 休眠流程(over_threshold: true 时执行)

1. **写检查点(双写——固定名 + SID 名)**,两者内容一致,以防会话 SID 跨夜/重启变化导致找不到:
   - 固定名 `/tmp/cc-checkpoint-<项目或任务标识>.json`(标识取任务相关短名,如 `camxchi-understand`,跨会话稳)
   - SID 名 `/tmp/cc-checkpoint-${CLAUDE_CODE_SESSION_ID}.json`(兼容旧规范,bash 里 `$CLAUDE_CODE_SESSION_ID` 自动展开)
   ```json
   {
     "task": "<当前正在做的任务,一句话>",
     "plan": "<当前计划的步骤,如 步骤3/7: xxx>",
     "todo": ["<待办项1>", "<待办项2>"],
     "reset_ts": <reset_ts Unix秒, 取自脚本输出字段>,
     "saved_at": "<ISO 时间>"
   }
   ```
2. **用 CronCreate 设定一次性定时唤醒**(在 reset 后约 2 分钟;闹钟此刻埋下,之后无论是否真 429,reset 时间一到必响):
   - `cron`: 把 `reset_ts + 缓冲` 换成本地时间 5 字段(一次性任务 dow 用 *):
     ```bash
     fire_ts=$((reset_ts + 120))
     read -r M H DOM MON < <(date -d "@$fire_ts" '+%-M %-H %-d %-m')
     cron="$M $H $DOM $MON *"
     ```
   - `prompt`: `"配额已重置,读检查点 /tmp/cc-checkpoint-<项目标识>.json 继续之前的长任务:<任务简述>"`
   - `recurring`: false
   - **`durable`: true** ← 必须写磁盘!session-only(durable:false)跨夜/换会话会失约(曾踩坑:session-only cron 没响)
3. **告知用户**:简要说明"配额 ≥90%,休眠到 <脚本输出的 reset_iso> 后自动醒来继续"
4. **结束本 turn**,不处理用户本轮请求

## 收到 CronCreate 恢复 prompt 时

1. 读检查点(优先固定名 `/tmp/cc-checkpoint-<标识>.json`,找不到再试 SID 名)
2. 调 `quota-watch.sh` 验证配额确实已恢复(percentage 应该很低)
3. **以磁盘产物为真实进度**(如 `batch-*.json`、输出文件等),不盲信检查点的数字描述 → 从 `task`/`plan`/`todo` 恢复上下文继续干活

## 注意事项

- 仅查 `TOKENS_LIMIT`,不关心 `TIME_LIMIT`(MCP 工具额度,月级窗口)
- 如果 API 不可达/解析失败,脚本返回 `over_threshold: false`,透明放行不阻断
- 子 agent 消耗也会计入 TOKENS_LIMIT(Workflow/Agent 派发的每个 sub-agent 走同一 provider)
- **派发子 agent(Agent 工具)被 hook deny 时**(配额超阈值):按本节休眠流程写检查点 + 设 CronCreate 埋雷,**勿重试派发**。PreToolUse hook(`quota-gate.sh`)已在每次派发前强制查配额,是防子 agent 轮中烧爆的硬闸

## percentage 不可靠时的保守控速(重要)

`quota-watch.sh` 的 `percentage` 偶有假数据——曾出现**全程显示 0% 却 429 烧穿**的情况(percentage 基于 TOKENS_LIMIT 额度,额度设得大时算出来一直低位,但实际 429 是"5 小时绝对 token 上限",口径不一致)。因此:

- **长任务绝不只依赖 percentage**,改用任务计数:实测每 5 小时窗口约能跑 **15 个**重 subagent(file-analyzer 级)就 429,保守取 **≤13 个就主动埋雷休眠**
- 每跑 10 个查一次 `percentage` 看趋势,但**仅参考**,以计数为准
- 详见 memory `zhipu-quota-percentage-unreliable`
<!-- han-quota-watch:section:end -->
