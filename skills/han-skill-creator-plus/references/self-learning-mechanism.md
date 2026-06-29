# 自主学习机制

## 三层架构

```
反馈层  → workflows/feedback-loop.md    （用户主动触发闭环）
学习层  → workflows/step-XX-learn.md    （任务结束后收录新发现）
数据层  → data/patterns.json + cases/  （持久化积累）
```

## 数据层：data/ 目录

### patterns.json — 模式/经验库

每次成功处理任务后，将验证有效的模式沉淀到 `patterns.json`：

```json
{
  "patterns": [{
    "id": "ptrn-001",
    "name": "模式简短名称",
    "category": "分类",
    "description": "模式详细描述，包含关键特征和判断依据",
    "confidence": 1,
    "frequency": 1,
    "keywords": ["kw1", "kw2"],
    "first_seen": "YYYY-MM-DD",
    "last_seen": "YYYY-MM-DD",
    "outcome": "success"
  }]
}
```

**置信度机制**：
- 初始值：1
- 反馈闭环 success：+1
- 反馈闭环 failed：-1
- confidence < 0：从 patterns 中移除
- confidence ≥ 3：高置信度模式，可作为强推荐线索

**使用时机**：
- 任务开始时，查询 patterns.json 中匹配当前输入的模式
- 高置信度模式作为处理线索（不是结论，仍需验证）

### cases/ — 历史案例存档

每次反馈闭环确认后，归档完整案例到 `data/cases/<YYYYMMDD-HHMMSS>-<type>.json`。

### 其他可选数据文件

| 文件 | 用途 | 示例 |
|------|------|------|
| `signatures.json` | 特征签名库，自动匹配输入类型 | kernel-crash-analyzer 的 crash 签名 |
| `tool_cache.json` | 工具可用性缓存，避免重复检测 | 反汇编工具路径缓存 |

## 学习层：workflows/step-XX-learn.md

安排在任务主流程的最后一步（如 Step 10），负责：

1. **收录新类型** — 如果遇到了知识库中没有的新类型/新模式，提示用户是否收录
2. **收录新场景** — 如果用户输入了新的场景/选项，提示是否加入预设列表
3. **不主动弹出反馈** — 学习是自动的，反馈是延迟的

## 反馈层：workflows/feedback-loop.md

由用户主动发出"搞定/完成/解决"信号后触发，7 步走：

1. 回顾 — 从对话历史提取完整过程
2. 呈现 — 向用户展示分析链路
3. 确认 — 用户选择哪些部分有效
4. 存档 — 写入 data/cases/
5. 更新 — 调整 data/patterns.json 置信度
6. 知识 — 追加领域知识到 references/
7. 总结 — 输出闭环报告

### 设计原则

- **被动触发**：用户不主动发信号，绝不弹出反馈
- **用户主导**：用户确认哪些有效，不是 AI 自己判断
- **diff preview**：更新 patterns.json 前展示变化
- **可逆**：用户拒绝收录就跳过，不强制

## 与官方 eval 系统的关系

| 维度 | Evals | Self-Learning |
|------|-------|---------------|
| 数据来源 | 人工构造的测试集 | 真实使用中的案例 |
| 目的 | 衡量 skill 质量基线 | 提升实际使用效率 |
| 触发方式 | 开发阶段手动运行 | 使用时自动积累 |
| 更新频率 | skill 版本迭代时 | 每次任务完成后 |

两者互补：evals 保证不退化，self-learning 保证持续进步。
