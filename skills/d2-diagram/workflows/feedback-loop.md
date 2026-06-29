# 反馈闭环

当用户主动发出完成信号（"修好了"、"搞定了"、"问题解决了"、"不再复现"）时触发。

## Step 1: 回顾

从对话历史中提取本次任务的完整过程：
- 用户原始需求
- 选择的图表类型和 shapes
- 使用的模板和样式
- 遇到的问题和解决方案
- 最终结果

## Step 2: 展示

向用户展示分析时间线，列出关键步骤和决策点。

## Step 3: 确认

用 AskUserQuestion 让用户确认哪些部分是有效的：
- 图表类型选择是否正确？
- Shape 选择是否合适？
- 样式是否满足需求？
- 有哪些步骤可以改进？

## Step 4: 存档

将案例保存为双格式：

**JSON**（`data/cases/case-<简短描述>.json`）：
```json
{
  "id": "case-NNN",
  "date": "YYYY-MM-DD",
  "trigger": "用户原始输入",
  "diagram_type": "流程图/架构图/...",
  "shapes_used": ["oval", "rectangle", "diamond"],
  "template_used": "flowchart.d2",
  "theme": "--theme=300",
  "style": "clean/sketch",
  "issues_encountered": [],
  "resolution": "解决方法",
  "outcome": "success/partial/failed",
  "patterns_matched": ["ptrn-001"]
}
```

**Markdown**（同目录，供人阅读）：
```markdown
# 案例：<简短描述>
- 日期：YYYY-MM-DD
- 触发：<用户输入>
- 图表类型：<类型>
- 使用模板：<模板名>
- 遇到问题：<问题描述>
- 解决方案：<方法>
- 结果：<success/partial/failed>
```

## Step 5: 更新置信度

根据用户确认结果，更新 `data/patterns.json` 中匹配模式的 confidence：
- 成功的模式：`confidence += 1`, `frequency += 1`
- 失败的模式：`confidence -= 1`
- confidence < 0 的模式：从 patterns 数组中移除

## Step 6: 知识库

如果案例中包含新的知识点，追加到 `references/` 对应文件。

## Step 7: 总结

向用户输出闭环报告：
- 确认了哪些有效模式
- 更新了哪些模式置信度
- 新增了哪些知识
- 案例归档位置

---

**反馈闭环完成。**
