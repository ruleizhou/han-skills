# Step 6: 自主学习与收录

任务执行结束后，根据过程中发现的新模式/新类型，执行收录流程。

## 1. 新 U 盘/设备模式收录

如果本次测试的 U 盘表现不在已知模式中（如异常的读写比、特殊 quirk 需求），用 `AskUserQuestion` 提示用户确认是否收录：

```
question: "本次发现了一个新的 U 盘/设备表现模式，是否收录到 skill 知识库？"
header: "收录新模式"
options:
  - label: "收录并更新知识库"
    description: "将新模式同时加入 references/ 和 data/patterns.json"
  - label: "仅收录到 data/patterns.json（自学习库）"
    description: "只更新自学习库，不修改参考文档"
  - label: "这次先不收录"
    description: "跳过，后续手动补充"
```

收录时自动提取的关键字段：
- **vid/pid**（如有）：设备标识
- **读写速度比**：关键性能特征
- **使用的协议**：BOT / UAS
- **有效的优化参数**：哪些参数改动有效

## 2. 新内核参数发现

如果排查过程中发现了新的可调内核参数（不在现有 `step-03-kernel-params.md` 列表中）：

1. 从内核代码中确认参数位置和默认值
2. 用 `AskUserQuestion` 确认是否收录为新检查项
3. 用户确认后，更新 `step-03-kernel-params.md` 的参数表

## 3. 反馈闭环（被动触发）

**本轮不主动询问反馈。** 复杂性能问题通常需要多轮验证（设备端命令执行 → 结果对比），不应每次都弹出反馈。

当用户后续主动发出完成信号（"修好了"、"搞定了"、"问题解决了"等），skill 进入**反馈闭环模式**（参见 `workflows/feedback-loop.md`），届时再：
- 回顾完整分析链路
- 确认有效步骤
- 存档案例到 `data/cases/`
- 更新 `data/patterns.json` 置信度

---

所有步骤完成。如果用户有新的任务，从 Step 0 重新开始。
