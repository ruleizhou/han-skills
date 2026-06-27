# Step 4: 已有 Skill 迁移

为已有的传统单文件 skill 追加文件拆分架构和/或自主学习。

## 4.1 检测现有结构

先 `ls -la <skill-path>/` 了解当前 skill 的文件结构：

```
情况 A：仅有 SKILL.md（纯单体）
情况 B：SKILL.md + references/（有参考文档但没拆分）
情况 C：SKILL.md + references/ + scripts/（功能齐全但是单体）
```

## 4.2 提取步骤切分点

读取现有 `SKILL.md`，分析工作流中的自然切分点：

- 以 `##` 或 `###` 标题为切分线索
- 以 "接下来"、"然后"、"Now"、"Then" 等过渡词为切分线索
- 以明显的阶段转换点为切分线索（收集信息 → 执行 → 输出）

将提取的步骤列表呈现给用户确认。

## 4.3 生成拆分架构

按照 Step 1 的流程：
1. 创建 `workflows/` 目录
2. 为每个步骤生成独立的 `workflows/step-NN-xxx.md`
3. 将原有内容按步骤拆分迁移
4. 每个步骤末尾添加 `完成后，读取 workflows/step-NN-xxx.md 继续`
5. 重写 `SKILL.md` 为路由层（≤100 行）

**迁移原则**：
- 原有内容的实质不改动，只做文件拆分
- 如果原有步骤不清晰，和用户确认后再拆
- 保留原有 `references/`、`scripts/`、`evals/` 不动

## 4.4 添加自学习（可选）

如果用户还想要自主学习能力，按照 Step 2 的流程：
1. 创建 `data/` 目录
2. 生成 feedback-loop.md + learn 步骤
3. 更新 SKILL.md 的 description 和 Workflow 表格

## 4.5 验证

迁移完成后，和用户确认：
- 步骤链路完整（每个步骤末尾的 "下一步" 链接正确）
- 路由表覆盖了原有所有触发信号
- 原有功能没有丢失

---

**迁移完成后，读取 `workflows/step-03-eval-iterate.md` 评估迁移效果。**
