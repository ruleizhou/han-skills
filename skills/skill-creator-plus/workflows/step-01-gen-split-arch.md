# Step 1: 生成文件拆分结构

基于用户需求，从 `templates/split-arch/` 生成拆分架构的 skill 骨架。

## 1.1 创建目录结构

```bash
mkdir -p <skill-path>/{workflows,references,scripts,evals}
```

## 1.2 生成 SKILL.md 路由层

读取 `templates/split-arch/SKILL.md.template`，填充以下变量：

| 占位符 | 填充规则 |
|--------|---------|
| `{{SKILL_NAME}}` | skill 标识符（kebab-case） |
| `{{SKILL_DESCRIPTION}}` | 触发条件 + 功能描述（~100 词），**写法见 `references/skill-writing-guide.md` 第三章**：信息全放 description、主动防 under-trigger、触发短语多样 |
| `{{SKILL_TITLE}}` | 人类可读的 skill 标题 |
| `{{SKILL_BRIEF_INTRO}}` | 1-2 句简介 |
| `{{CORE_PRINCIPLES}}` | 3-5 条最高优先级规则（先做 X 再 Y、某情况必确认等） |
| `{{MODE_TRIGGER_TABLE}}` | 触发信号 → 模式 → 动作 的路由表 |
| `{{STEP_COUNT}}` | 步骤总数 |
| `{{LAST_STEP}}` | 最后一步的编号 |
| `{{WORKFLOW_TABLE}}` | `| N | workflows/step-NN-xxx.md | 做什么 |` 表格 |
| `{{REFERENCES_LIST}}` | 关键文件路径速查 |

## 1.3 生成步骤文件

对每个步骤，从 `templates/split-arch/workflows/step-NN-name.md.template` 生成：

- `{{STEP_NUMBER}}`：步骤编号
- `{{STEP_TITLE}}`：步骤标题
- `{{STEP_INSTRUCTIONS}}`：步骤具体指令
- `{{NEXT_STEP_FILE}}`：下一步文件名

### 步骤划分原则

1. **一问一答一个文件** — 每个步骤文件只做一件事：收集信息、匹配类型、执行分析、输出报告...
2. **首尾固定** — Step 0 永远是交互式收集信息，最后一步永远是收录+报告
3. **中间按业务逻辑切** — 按照实际工作流的阶段切分
4. **链接闭环** — 最后一步末尾指向 "所有步骤完成，如需重新执行从 Step 0 开始"

### 步骤数量建议

- 简单 skill（单一输入→单一输出）：3-5 步
- 中等 skill（多输入→分析→输出）：5-8 步
- 复杂 skill（多模式→多阶段→自学习）：8-12 步

超过 12 步考虑拆分为子模式（类似 kernel-crash-analyzer 的 [分析模式] 和 [反馈闭环模式]）。

## 1.4 创建 references/ 骨架

如果 skill 需要参考文档（领域知识、API 文档、最佳实践等），创建对应的 `.md` 文件骨架。

## 1.5 验证

生成后和用户确认：
- 步骤划分是否合理（有没有可以合并或需要拆分的）
- 路由表是否覆盖了所有触发信号
- 步骤链路的 `完成后，读取 XXX 继续` 是否正确

## 1.6 草稿自检

SKILL.md 和各步骤文件生成后，**按 `references/skill-writing-guide.md` 第二章的四件事自检一遍**：

- 占位含糊（TBD / 按需 / 适当地）→ 说清或删
- 自相矛盾（前后指令、description 与正文打架）→ 统一
- 范围蔓延（混进未确认的功能）→ 砍掉或回去确认
- 歧义（一条要求两种理解）→ 挑一种写明确

发现问题就地改掉，再交给用户。这一步省掉后续 80% 的返工。

**如果用户选择了"自主学习"，完成后读取 `workflows/step-02-gen-self-learning.md`。否则跳过 Step 2，直接读取 `workflows/step-03-eval-iterate.md`。**
