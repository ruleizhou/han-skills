# 反馈闭环

用户已发出"问题解决"信号，现在回顾历史分析、整理完整链路、存档案例、更新模式库。

## 步骤 1：回顾历史分析

从当前对话历史中回顾本次死机问题的所有分析轮次。提取每轮的关键信息：

- 分析时间
- crash 类型
- fault address
- 平台/内核版本
- 死机场景
- 根因分类（竞态/错误路径清理/UAF/初始化顺序/锁顺序/其他）
- 根因简述（1-2 句）
- 修复建议摘要
- 关键词列表
- 使用的反汇编工具
- 质量自查结果

如果对话历史中找不到完整信息，用 `AskUserQuestion` 向用户确认关键细节。

## 步骤 2：呈现分析链路

将所有分析轮次按时间排序，呈现给用户：

```markdown
## 本次死机问题分析链路回顾

| # | 时间 | Crash 类型 | 根因分类 | 根因简述 |
|---|------|-----------|---------|---------|
| 1 | 20260520-1430 | NULL 指针解引用 | 错误路径清理 | xxx_probe() 失败路径未释放 reg |
| 2 | 20260522-0915 | NULL 指针解引用 | 竞态条件 | xxx_isr 与 xxx_probe 并发访问 |
| 3 | 20260524-1030 | NULL 指针解引用 | 初始化顺序 | xxx_init 在依赖模块之前调用 |

**当前最终有效的分析是哪一轮？**
```

## 步骤 3：确认最终根因

```
question: "以上历史分析中，哪一轮最终定位到了正确的根因？"
header: "闭环确认"
options:
  - label: "第 N 轮 — 分析正确，修复生效"
    description: "这一轮的根因定位准确，修复方案有效"
  - label: "多轮共同作用"
    description: "根因涉及多个层面，多轮分析都有贡献"
  - label: "每轮都不完全对"
    description: "实际根因不在上述分析中"
```

## 步骤 4：存档案例（双格式）

同时生成 **JSON**（机器索引）和 **Markdown**（人类阅读）两份案例文件。

### 4.1 JSON 格式（写入 skill 内部）

写入 `data/cases/<crash_type>.json`：

```json
{
  "id": "<crash_type>",
  "timestamp": "<ISO8601>",
  "crash_type": "<类型名>",
  "fault_address": "<地址>",
  "platform": "<平台/芯片型号>",
  "kernel_version": "<内核版本>",
  "scenario": "<死机场景>",
  "root_cause": "<1-2 句描述>",
  "root_cause_category": "<分类>",
  "fix_summary": "<修复建议摘要>",
  "pattern_keywords": ["<关键词1>", "<关键词2>"],
  "tools_used": ["<实际使用的反汇编工具>"],
  "quality_checklist": {
    "objdump_executed": true,
    "fault_address_mapped": true,
    "root_cause_falsifiable": true,
    "init_order_verified": "N/A",
    "scenario_consistent": true
  },
  "adversarial_verification": {
    "root_cause_verdict": "<CONCUR/CONCUR_WITH_CAUTION/DISAGREE/跳过>",
    "root_cause_challenges": ["<质疑摘要>"],
    "fix_verdict": "<APPROVE/APPROVE_WITH_NOTES/REJECT/跳过>",
    "fix_issues": ["<问题摘要>"],
    "challenges_resolved": true
  },
  "outcome": "<success/partial/failed>"
}
```

**outcome 设置规则**：
- 用户选"第 N 轮正确"：该轮 `"success"`，其余 `"partial"`
- "多轮共同作用"：所有相关轮次 `"success"`
- "每轮都不完全对"：所有轮次 `"failed"`

### 4.2 Markdown 格式（输出到用户工作路径）

写入**用户当前工作目录**下 `<crash_type>.md`：

```markdown
# 内核死机问题分析

> **案例 ID**：<crash_type>
> **日期**：<YYYY-MM-DD>
> **结论**：<一句话总结>

---

## 1. 问题描述

<问题详述，包含关键上下文、环境信息>

## 2. 数据/测量结果

| 项目 | 值 |
|------|-----|
| Crash 类型 | ... |
| Fault Address | ... |
| 平台 | ... |
| 内核版本 | ... |

## 3. 过程检查点

| 检查项 | 状态 | 证据 |
|--------|------|------|
| 反汇编执行 | ... | ... |
| Fault address 映射 | ... | ... |
| 根因可证伪性 | ... | ... |
| Init 顺序验证 | ... | ... |
| 场景一致性 | ... | ... |

## 4. 根因分析

<根因详细分析，包含调用链、数据流、时序关系>

## 5. 方案/建议

| 优先级 | 方案 | 操作 | 预期效果 |
|--------|------|------|----------|
| P0 | ... | ... | ... |
| P1 | ... | ... | ... |

## 6. 关键引用

\`\`\`
<crash log 关键片段 + 反汇编关键指令>
\`\`\`
```

**JSON 写入 skill 内部 `data/cases/` 供模式库自动索引和匹配；Markdown 写入用户当前工作路径供阅读和团队分享。两者必须同时生成，内容一致。**

## 步骤 5：更新模式库

更新 `data/patterns.json`：

- **success 的轮次**：提取根因模式，如果已有匹配模式 → `confidence += 1`；如果是新模式 → 追加 `confidence: 1`
- **failed 的轮次**：对应模式 `confidence -= 1`；如果 confidence 降到 < 0 → 从 patterns.json 中移除

模式条目格式：
```json
{
  "id": "ptrn-<自增编号>",
  "name": "<模式简短名称>",
  "crash_type": "<类型>",
  "category": "<分类>",
  "description": "<模式描述>",
  "confidence": 1,
  "frequency": 1,
  "fix_template": "<修复模板>",
  "keywords": ["<kw1>", "<kw2>"],
  "first_seen": "<日期>",
  "last_seen": "<日期>",
  "adversarial_verifications": [
    {
      "case_id": "<case_id>",
      "root_cause_verdict": "CONCUR",
      "root_cause_challenges": ["<质疑摘要>"],
      "fix_verdict": "APPROVE",
      "fix_issues": [],
      "timestamp": "<ISO8601>"
    }
  ]
}
```

如果本次分析经过了对抗验证（案例中有对抗验证结果），将验证结果追加到对应模式的 `adversarial_verifications` 数组中。

更新前后展示 diff preview 让用户 review。

## 步骤 6：平台怪癖更新（如适用）

如果整个分析链路揭示了平台/内核版本的新特性，追加到 `references/platform_quirks.md`。

## 步骤 7：输出闭环总结

```markdown
## 反馈闭环总结

- **问题**：<crash 类型 + 场景>
- **分析轮次**：N 轮
- **最终根因**：<明确的根因描述>
- **案例存档**：JSON → skill `data/cases/<case_id>.json` | Markdown → 当前工程 `<case_id>.md`
- **模式库更新**：<新增/更新了哪些模式，confidence 变化>
```

## 步骤 8：补漏检查 — Step 10 新类型收录（MANDATORY）

**feedback-loop 由用户信号（"搞定"/"修复生效"）触发，可能跳过了正常流程中的 Step 10。闭环结束前必须检查：**

1. 回顾本次分析的 Step 3 结果 — crash 类型是否为 `[未知类型]`？
2. 如果是 `[未知类型]` 且尚未收录：按照 `workflows/step-10-learn.md` 的 10.1 节，弹出 `AskUserQuestion` 让用户确认是否收录新类型到 `data/signatures.json` 和 `references/signature_table.md`
3. 如果是已知类型或已收录：跳过

```
弹出:
question: "本次分析的 crash 类型在 signature 表中尚未收录，是否现在收录？"
header: "补漏"
options:
  - label: "收录并更新签名表"
  - label: "仅收录到签名库"
  - label: "跳过"
```

**此步骤确保：即使正常流程被 feedback-loop 打断，新 crash 类型的知识也不会丢失。**

## 步骤 9：分析手册生成（条件触发）

**触发条件**：满足以下任一条件时，弹出 `AskUserQuestion` 询问是否生成分析手册：

1. 当前模式的 `confidence >= 3`（已验证有效的成熟模式，值得沉淀为操作手册）
2. 用户在此次闭环中主动要求（"生成手册"、"写个分析指导"）
3. crash 类型为 `[未知类型]` 且用户已确认收录

**不满足条件时跳过本步骤**，直接输出闭环总结。

```
question: "当前 crash 模式已成熟（confidence=N），是否生成分析手册供团队复用？"
header: "分析手册"
options:
  - label: "生成分析手册"
    description: "生成面向工程师的操作手册，包含现象识别→反汇编→源码追踪→修复的完整步骤，每步附带可执行命令"
  - label: "暂时跳过"
    description: "后续可手动要求生成"
```

**用户选择生成时**：

1. 读取 `references/analysis-manual-template.md` 了解手册结构要求
2. 从本次分析过程中提取：
   - crash 签名和 grep 命令
   - DebugImage 栈帧和分割方式
   - System.map 符号地址
   - objdump 反汇编关键指令
   - 相关源文件路径和函数
   - 修复 diff
3. 按模板生成手册，写入用户当前工作目录：`<CrashType>-分析手册.md`
4. 在闭环总结中注明手册路径

---

**闭环完成。该问题的知识已沉淀到 `data/cases/`（JSON 机读索引），当前工作路径（Markdown 阅读文档 + 分析手册），`data/patterns.json` 已更新，后续相似 crash 将获得更精准的分析线索。**
