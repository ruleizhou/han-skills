# Step 4: 收录经验(自动)

任务结束,把本次的「内容类型 + 风格 + 密度」组合沉淀到 patterns.json。学习自动,反馈延迟——不弹反馈框。

## 4.1 判断是否新组合

读取 [data/patterns.json](../data/patterns.json),看本次 `(content_type, style, density)` 是否已有匹配。

## 4.2 收录

- **新组合 / 新内容类型** → AskUserQuestion 轻量问一句「是否收录这条参数经验?」(默认收录),追加 `confidence: 1`。
- **已有匹配** → 暂不改动 confidence(留给反馈闭环)。

## 4.3 完成

所有步骤完成。如需重新执行,从 [step-00-analyze.md](step-00-analyze.md) 开始。

用户若主动说「这版不错 / 就用这版 / 搞定了」,读取 [feedback-loop.md](feedback-loop.md) 走反馈闭环。
