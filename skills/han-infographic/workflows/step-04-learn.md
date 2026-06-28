# Step 4: 收录经验(自动)

任务结束,把本次的「内容类型 + 布局 + 风格」组合沉淀到 patterns.json。

**学习是自动的,反馈是延迟的** —— 这一步不弹反馈框,不替用户判断出图好坏;质量判定延迟到用户主动发反馈信号(Step 3 提示过)。

## 4.1 判断是否新组合

读取 [data/patterns.json](../data/patterns.json),看本次 `(content_type, layout, style)` 是否已有匹配条目。

## 4.2 收录

- **新组合 / 新内容类型** → 用 AskUserQuestion 轻量问一句「是否收录这条参数经验?」(默认收录),追加一条 `confidence: 1` 的 pattern。
- **已有匹配** → 暂不改动 confidence(留给反馈闭环,等用户确认满意时再 +1,避免自我吹捧)。

## 4.3 完成

所有步骤完成。如需重新执行,从 [step-00-analyze.md](step-00-analyze.md) 开始。

用户若主动说「这版不错 / 就用这版 / 搞定了」,读取 [feedback-loop.md](feedback-loop.md) 走反馈闭环(回顾 → 确认 → 存 case → 更新 confidence)。
