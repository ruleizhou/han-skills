# 反馈闭环（用户触发："能开机了 / 降频生效了 / 验证通过了"）

## 1. 回顾本轮对话

提取：平台、原频率→目标频率、走过的 Step、每轮实验配置与结果、最终生效的三层组合。

## 2. 呈现分析轮次表

| 轮次 | 配置 | 结果 | 关键发现 |
|------|------|------|----------|

## 3. 确认有效性（AskUserQuestion 三选）

- 第 N 轮（终局组合）单独起效 → outcome=success，该轮涉及模式 confidence +1
- 多轮共同作用 → outcome=partial，相关模式 confidence +1 但标注
- 每轮都不完全对 → outcome=failed，复核 patterns，相关模式 confidence -1

## 4. 双格式存档

- JSON → `data/cases/<YYYYMMDD>-<平台>-<目标频率>.json`（机器索引）
- Markdown → 用户当前工作目录 `<平台>-DDR<目标频率>-降频方案.md`（人类阅读，结构对齐 step-06 报告模板）

两者内容一致。

## 5. 更新 patterns.json（先展示 diff preview 再写入）

success：confidence+1 frequency+1；failed：confidence-1（<0 移除条目）。

## 6. 追加领域知识

已验证经验 → `references/cross-firmware-checklist.md` / `platform-paths.md` 对应小节。

## 7. 闭环总结

一句话结论 + 当前模式库状态（高置信模式数）+ 提示下次可直接从 Step 0 进入。
