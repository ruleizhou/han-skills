# Step 6: 自主学习与收录

任务执行结束后，根据过程中发现的新模式/新模板/新场景，执行收录流程。

## 1. 新模板收录

如果本次创建了通用模板（不在 `assets/templates/` 中），用 AskUserQuestion 确认是否收录。

收录时执行：
1. 将模板写入 `assets/templates/<new-type>.d2`
2. 添加模板注释头：`# <类型> Template | Created: YYYY-MM-DD | Usage: d2 --theme=300 -l elk <file>.d2 output.png`
3. 更新 SKILL.md 参考资料速查中的模板列表

## 2. 新模式收录

如果发现了新的用户需求模式或 D2 使用模式：

### 提取
- **触发信号**：用户说了什么
- **处理流程**：采用了什么步骤
- **关键决策**：做了哪些关键选择
- **结果评估**：success/partial/failed

### 收录
用 AskUserQuestion 确认后，更新 `data/patterns.json`：

```json
{
  "id": "ptrn-NNN",
  "name": "模式名称",
  "category": "图表类型识别 / 样式偏好 / 布局优化 / 错误避免",
  "description": "详细描述",
  "confidence": 1,
  "frequency": 1,
  "keywords": ["关键词1", "关键词2"],
  "first_seen": "YYYY-MM-DD",
  "last_seen": "YYYY-MM-DD",
  "outcome": "success",
  "template_ref": "assets/templates/xxx.d2"
}
```

**confidence 评分**：success +1, fail -1, <0 移除

## 3. 新场景收录

如果用户提供了新的需求场景（不在 Step 0 模式判断表中），用 AskUserQuestion 确认后：
- 在 `workflows/step-00-diagnose.md` 的决策树中添加新分支
- 在 SKILL.md 的模式判断表中添加新行

## 4. 反馈闭环（被动触发）

**本轮不主动询问反馈！** 复杂任务通常需要多轮验证。

当用户后续主动发出完成信号（"修好了"、"搞定了"、"问题解决了"），读取 `workflows/feedback-loop.md`：
- 回顾历史过程
- 确认有效步骤
- 更新模式置信度
- 存档案例（JSON + Markdown 双格式）

## 5. 知识库更新

如果本次揭示了新的 D2 语法知识或最佳实践，确认后追加到 `references/` 对应文件。

---

**所有步骤完成。如果用户有新的任务，从 Step 0 重新开始。**
