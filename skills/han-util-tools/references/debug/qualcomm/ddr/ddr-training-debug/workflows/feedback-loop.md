# 反馈闭环：修复验证与案例归档

用户报告"问题解决/修复生效/不再复现"时触发。回顾历史案例 → 确认根因 → 更新模式库。

## 1. 回顾历史

询问用户确认：
- 哪个问题解决了？
- 最终的根因和修复方案是什么？

如果本次会话已有完整的分析历史，直接引用。如果用户提供的是新的"解决"信号（未在本会话中分析过），从 `data/cases/` 查找相关案例。

## 2. 确认修复方案

用 `AskUserQuestion` 确认：

```
question: "请确认最终有效的修复方案？"
header: "修复确认"
options:
  - label: "调整参数阈值"
    description: "修改了 ddr_training_params.c 中的 abort 阈值"
  - label: "硬件修改"
    description: "调整了 PCB 走线/阻抗/去耦等硬件设计"
  - label: "其他方案"
    description: "用户自定义描述"
```

## 3. 验证效果

确认：
- 修复后是否通过测试？（如 QDUTT DDI 通过）
- 高低温/电压拉偏是否验证？
- 是否有其他副作用？

## 4. 更新案例归档

如果修复方案与已知案例匹配：
1. 更新 `data/cases/{case}.json`：追加验证结果、更新 `fix_verified` 状态
2. 更新 `data/patterns.json`：提高对应 pattern 的 `confidence`

如果是新模式：
1. 创建新案例 JSON（见 Step 7 模板）
2. 在 `patterns.json` 中添加新条目（`confidence: "LOW"`）

## 5. 输出总结

```markdown
## 反馈闭环完成

**问题**：[原始错误现象]
**根因**：[确认的根因]
**修复**：[最终修复方案]
**案例路径**：`data/cases/{filename}.json`
**模式库更新**：patterns.json {phase} → confidence {new_level}

### 经验积累

- 本次新增/确认的经验：[N] 条
- 当前模式库条目数：[N]
- 下次类似问题可从 Step [N] 快速定位
```

## 6. 检查遗漏

最后检查是否遗漏了以下类型的沉淀：
- 是否有新的错误模式未记录？
- 是否有新的平台特定信息应加入 `references/platform-mapping.md`？
- 是否有阈值范围判断经验应加入 `references/threshold-guide.md`？

## 7. 完成

反馈闭环结束。所有步骤完成。
