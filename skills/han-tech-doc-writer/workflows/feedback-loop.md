# 反馈闭环

由用户主动触发（"搞定了"、"写好了"、"完成了"等信号词），7 步走。

## Step 1: 回顾本次过程

从对话历史提取以下信息：

| 字段 | 来源 |
|------|------|
| 输入来源 | Step 0 诊断结果 |
| 文档类型 | Step 0 诊断结果 |
| 源内容概要 | Step 1 提取结果 |
| 大纲结构 | Step 2 大纲 |
| D2 图表类型与数量 | Step 2 图表清单 |
| 信息图数量与参数 | Step 2 信息图清单 + 布局/风格选择 |
| 编译是否成功 | Step 3 编译结果 |
| 信息图生成效果 | Step 3.5 生成结果 |
| 审核通过项 | Step 5 检查清单结果 |
| 输出文件路径 | Step 6 输出路径 |

如果历史信息不完整，用 `结构化提问` 向用户确认。

## Step 2: 呈现回顾

展示本次文档输出的关键信息：

```markdown
## 本次文档输出回顾
- **文档标题**: <标题>
- **文档类型**: <类型>
- **篇幅**: N 章, ~M 字
- **D2 图表数**: K 张（类型分布: ...）
- **信息图数**: I 张（布局/风格: ...）
- **来源**: <粘贴/URL/文件>
- **输出文件**: <路径>
```

## Step 3: 确认最终效果

```
question: "文档输出效果如何？"
header: "质量确认"
options:
  - label: "质量很好，可直接使用"
    description: "结构合理、图表准确、信息图醒目、内容完整，无需修改"
  - label: "基本可用，需小幅调整"
    description: "整体框架正确，部分内容、图表或信息图需要手动调整"
  - label: "质量不佳，需要重写"
    description: "结构/图表/信息图/内容存在较大问题"
```

## Step 4: 存档案例

更新案例文件（如果 Step 6 已归档）：

- **成功**（质量很好）→ `outcome: "success"`，保持案例
- **部分成功**（基本可用）→ `outcome: "partial"`，案例保留但降低权重
- **失败**（需要重写）→ `outcome: "failed"`，案例保留供避坑参考

如果 Step 6 选择了跳过归档，现在不补归档。

## Step 5: 更新模式库

更新 `data/patterns.json`：

- **用户确认效果好**:
  - D2 图模式：匹配到的模式 `confidence += 1, frequency += 1`
  - 信息图模式：匹配 `category="infographic-layout-style"` 的条目 `confidence += 1, frequency += 1`
  - 新模式（本次新创建的）：追加到 patterns 数组
- **用户确认效果差**:
  - 对应模式：`confidence -= 1`
  - `confidence < 0` → 从 patterns 数组中移除
- 更新前后展示 diff preview 让用户审查

## Step 6: 更新知识库

如果本次发现了新的规律，追加到对应 reference 文件：

- 新的文档类型模板 → 追加到 `references/doc-structure-guide.md`
- 新的图表/信息图类型使用场景 → 追加到 `references/diagram-placement-guide.md`
- 新的信息图放置经验 → 追加到 `references/infographic-placement-guide.md`
- 新的写作惯例 → 追加到 `references/writing-style-guide.md`

用户确认有价值的才追加，不自动写入。

## Step 7: 输出闭环总结

```markdown
## 反馈闭环总结
- **文档**: <标题>
- **效果评价**: <质量很好/基本可用/质量不佳>
- **案例存档**: <路径> (outcome: <success/partial/failed>)
- **模式库更新**: D2 +N/-N, 信息图 +N/-N 置信度调整
- **知识库更新**: <有/无>
```

闭环完成。如需整理新的文档，从 Step 0 重新开始。
