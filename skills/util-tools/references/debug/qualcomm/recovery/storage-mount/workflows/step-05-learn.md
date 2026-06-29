# Step 5: 自主学习与收录

修复完成后，将本次分析过程中的新发现收录到自学习库。

## 目标

沉淀新的根因模式、更新已知问题库、归档案例。

## 指令

### 1. 新根因类型/新模式收录

如果本次遇到了新的根因类型（不在 `references/known-issues.md` 和 `data/patterns.json` 中），用 `AskUserQuestion` 提示用户确认是否收录：

```
question: "本次发现了一个新的根因模式，是否收录到 skill？"
header: "收录新模式"
options:
  - label: "收录（推荐）"
    description: "将新模式加入 patterns.json 和 known-issues.md"
  - label: "仅收录到 patterns.json"
    description: "只更新自学习模式库，不修改参考文档"
  - label: "这次先不收录"
    description: "跳过，后续手动补充"
```

收录时自动提取的关键字段：
- **id**: `ptrn-<自增三位数>`
- **name**: 简短模式名（如"DWC3 DRD 竞态"）
- **category**: 根因类别（init.rc 缺失 / DWC3 竞态 / SELinux / 路径不固定）
- **keywords**: 从日志中提取的关键词
- **platform**: 芯片平台

### 2. 新代码修复模式收录

如果本次修复涉及新的代码模板，收录到 `references/known-issues.md`：
- 添加新的问题条目
- 包含现象描述、根因分析、修复代码模板
- 标注平台和版本适用范围

### 3. 反馈闭环（被动触发）

**本轮不主动询问反馈。** 复杂任务通常需要多轮验证，不应每次都弹出反馈。

当用户后续主动发出完成信号（如"修好了"、"搞定了"、"问题解决了"等），skill 会进入**反馈闭环模式**（参见 `workflows/feedback-loop.md`），届时再回顾历史、确认有效步骤、更新模式置信度。

---

**所有步骤完成。如果用户有新的恢复挂载问题，从 Step 0 重新开始。**