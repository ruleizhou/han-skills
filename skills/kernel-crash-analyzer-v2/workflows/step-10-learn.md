# Step 10: 自主学习与收录

分析结束后，根据分析过程中的发现，执行对应的收录和反馈流程。

## 10.1 新 crash 类型收录

如果 Step 3 命中了 `[未知类型]`，用 `AskUserQuestion` 提示用户确认是否收录：

```
question: "本次分析发现了一个新的 crash 类型，是否收录到 skill？"
header: "收录"
options:
  - label: "收录并更新签名表"
    description: "将新类型加入 references/signature_table.md 和 data/signatures.json"
  - label: "仅收录到 data/signatures.json"
    description: "只更新自学习签名库，不修改参考文档"
  - label: "这次先不收录"
    description: "跳过，后续手动补充"
```

**用户选择收录时**：
- `data/signatures.json`：追加新条目（自动），包含 `pattern`、`type`、`priority_items`、`count`、`first_seen`
- `references/signature_table.md`：追加签名表行（仅在用户选"收录并更新签名表"时）
- 更新前展示 diff preview 让用户 review

收录的关键字段从本次分析中自动提取：
- **crash 特征签名**：从 crash log 中提取的异常字符串
- **类型名**：分析报告中使用的类型名
- **分析重点**：本次分析中验证有效的关键步骤

## 10.2 反馈闭环（被动触发）

**本轮分析不主动询问反馈。** 死机问题通常需要多轮定位验证，不应每次分析后都弹出反馈。

当用户后续主动发出信号（"问题解决了"、"修好了"、"修复生效"、"搞定了"、"根因确认了"、"不再复现"），skill 会进入**反馈闭环模式**（参见 `workflows/feedback-loop.md`），届时再回顾历史案例、确认有效分析、更新模式置信度。

---

**所有步骤完成。如果用户有新的 crash 需要分析，从 Step 0 重新开始。**
