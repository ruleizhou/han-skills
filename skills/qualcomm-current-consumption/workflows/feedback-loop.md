# 反馈闭环

用户已发出「完成/电流达标/根因确认」信号，回顾历史、存档案例、更新模式库。

## 步骤 1：回顾本次过程

从对话提取：

- 用户输入/项目平台  
- 执行步骤与关键读数（aosd/cxsd/ddr、spm、GPIO、QDSS）  
- 最终主因类与 ΔmA  
- **领域字段**：`root_cause_class`、`aosd_count`、`delta_mA_total`、`platform`、`aop_target`

若缺失，AskUserQuestion 补齐。

## 步骤 2：呈现回顾

```markdown
## 回顾

| # | 输入 | 关键决策 | 结果 |
|---|------|---------|------|
| 1 | ... | ... | ... |
```

## 步骤 3：确认最终结果

AskUserQuestion：

- 全部正确 / 部分正确 / 都不对  

## 步骤 4：存档案例（双格式）

### JSON → `data/cases/<YYYYMMDD-HHMMSS>-power-idle.json`

```json
{
  "id": "<YYYYMMDD-HHMMSS>",
  "timestamp": "<ISO8601>",
  "input_summary": "",
  "process_steps": [],
  "key_findings": [],
  "final_result": "",
  "result_assessment": "success|partial|failed",
  "root_cause_class": "CLASS_AOSS_STUCK|...",
  "platform": "",
  "aop_target": "",
  "aosd_count": 0,
  "delta_mA": {}
}
```

### Markdown → **当前工程目录** `<YYYYMMDD-HHMMSS>-power-idle.md`

含：问题描述、睡眠/电流表、检查点、根因、方案、引用。

## 步骤 5：更新 `data/patterns.json`

按 success/partial/failed 调整 confidence/frequency；展示 diff 供用户确认。

## 步骤 6：更新 `references/domain-knowledge.md`（如有新规则）

## 步骤 7：闭环总结

输出案例路径与模式库变更。

---

**闭环完成。**
