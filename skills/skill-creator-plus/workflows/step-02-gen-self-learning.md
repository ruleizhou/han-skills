# Step 2: 添加自主学习基础设施

从 `templates/self-learning/` 复制自学习骨架到目标 skill。

## 2.1 初始化 data/ 目录

```bash
mkdir -p <skill-path>/data/cases
```

复制并定制以下文件：

### data/patterns.json

从 `templates/self-learning/data/patterns.json.template` 复制。

保持 `_schema` 和 `_confidence_rules` 不变（通用规则）。如果 skill 领域有额外字段需求，在 `_fields` 注释中补充说明。

### data/cases/.gitkeep

从 `templates/self-learning/data/cases/.gitkeep` 复制。

## 2.2 生成 feedback-loop 步骤

从 `templates/self-learning/workflows/feedback-loop.md.template` 复制并定制：

| 占位符 | 替换规则 |
|--------|---------|
| `{{DOMAIN_SPECIFIC_FIELDS}}` | 领域特有的回顾字段，如 kernel-crash-analyzer 的 crash_type, fault_address, platform |
| `{{CASE_TYPE}}` | 案例分类标识，用 skill 的核心概念命名 |
| `{{DOMAIN_SPECIFIC_CASE_FIELDS}}` | 案例 JSON 中的领域特有字段 |

定制原则：
- **最少定制** — 通用 7 步框架不变，只替换占位符
- **回顾字段**：提取 skill 任务中最关键的 3-5 个信息维度
- **案例字段**：提取存档时需要记录的 2-3 个领域特有字段

## 2.3 生成 learn 步骤

从 `templates/self-learning/workflows/step-XX-learn.md.template` 复制并定制：

| 占位符 | 替换规则 |
|--------|---------|
| `{{STEP_NUMBER}}` | 主流程最后一个步骤的编号 |
| `{{ENTITY_TYPE}}` | 本 skill 的核心实体类型（如"crash 类型"、"性能模式"、"配置模板"） |
| `{{INPUT_TYPE}}` | 用户输入的实体类型（如"死机场景"、"使用场景"、"操作类型"） |

将 learn 步骤作为主流程的最后一步，插入到步骤列表末尾。

## 2.4 更新 SKILL.md

1. **description**：在 frontmatter 中添加反馈闭环触发信号（根据 skill 领域定制），如：
   - 技术 debug skill："问题解决了/修好了/根因确认了"
   - 内容创作 skill："就用这个版本/最终版确认了"
   - 数据分析 skill："结果验证通过了/数据确认无误"

2. **Workflow 表格**：在步骤列表末尾追加 learn 步骤和 feedback-loop 步骤

3. **参考资料速查**：添加 `data/patterns.json`、`data/cases/` 的速查链接

## 2.5 生成 references/domain-knowledge.md（可选）

如果 skill 需要在反馈闭环中积累领域知识，从 `templates/self-learning/references/domain-knowledge.md.template` 生成。

---

**完成后，读取 `workflows/step-03-eval-iterate.md`。**
