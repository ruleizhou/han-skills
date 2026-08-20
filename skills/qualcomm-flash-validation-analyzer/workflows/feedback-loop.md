# 反馈闭环

用户已发出"修好了/验证通过了/根因确认了"信号，现在回顾历史、存档案例、更新模式库。

## 步骤 1：回顾本次过程

从对话历史提取：
- 失败项与器件信息（platform、flash_device、fail_tests）
- 执行的实验序列与关键判读
- 根因结论与修复内容（root_cause_categories、fix）
- 修复验证结果（重跑 flashval 的各项数值）

信息不全时用 `AskUserQuestion` 补关键细节（重点问：patch 刷入后哪些项过了、有没有新的副作用）。

## 步骤 2：呈现回顾

```markdown
| # | 阶段 | 关键决策 | 结果 |
|---|------|---------|------|
| 1 | CSV 对比 | ... | 失败面=clkscale 计数 |
| 2 | 静态确认 | ... | msm 树/quirk miss |
| 3 | 设备实验 | ... | 死区+挂起双层根因 |
| 4 | 修复输出 | ... | patch 双 hunk |
| 5 | 验证 | ... | test2/10 全 PASS？ |
```

## 步骤 3：确认最终结果

`AskUserQuestion`：全部正确 / 部分正确（有些根因不对）/ 都不对。

## 步骤 4：存档案例（双格式）

- JSON → `data/cases/<id>-<类别>.json`（字段见 step-05），**result_assessment 按 §3 答案与验证结果定 success/partial/failed**
- Markdown 报告已在工作目录，核对存在并补"验证结果"章节；若无则按模板补写一份

## 步骤 5：更新模式库

- 验证通过的根因模式：confidence +1（如 ptrn-001/002 修复见效）
- 部分正确：有效部分 +1，无效部分 -1（confidence<0 移除）
- **修复副作用若构成新模式**（如某参数调整引发别的问题）→ 新增条目
- diff preview 给用户 review 后写入

## 步骤 6：更新领域知识

新确认的机制细节追加到 `references/ufs-clkscale-mechanism.md`（如：修复后的实测 load 序列、新料的 quirk 生效证据）。

## 步骤 7：输出闭环总结

```markdown
## 反馈闭环总结
- 任务：<描述>
- 关键发现：<要点>
- 案例存档：JSON → data/cases/<id>.json | 报告 → <路径>
- 模式库更新：<模式 confidence 变化>
```

闭环完成。后续相似失败将命中更高置信度的模式。
