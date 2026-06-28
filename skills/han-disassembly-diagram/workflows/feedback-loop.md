# 反馈闭环

用户已发出「这版不错 / 就用这版 / 搞定了」信号,回顾、确认、存档、更新经验库。

## 步骤 1:回顾本次过程

从对话历史与工作目录提取:

- 目标对象
- 最终选用参数:**对象类型、mode、aspect**
- 出图后端(han-imagen Python / 运行时工具)与 provider
- 用户满意度
- 最终图片路径与生成文件清单

## 步骤 2:呈现回顾

```markdown
## 回顾

| # | 对象类型 | mode | aspect | 满意度 | 产物 |
|---|---------|------|--------|--------|------|
| 1 | ... | ... | ... | ... | ... |
```

## 步骤 3:确认最终结果

AskUserQuestion:全部满意(confidence +1)/ 部分满意 / 不满意(confidence -1)。

## 步骤 4:存档案例(双格式)

### 4.1 JSON(写入 skill 内部)

`data/cases/<YYYYMMDD-HHMMSS>-disassembly-diagram.json`:

```json
{
  "id": "<YYYYMMDD-HHMMSS>",
  "timestamp": "<ISO8601>",
  "input_summary": "<对象>",
  "object_type": "<对象类型>",
  "mode": "<hybrid|exploded|cutaway|auto>",
  "aspect": "<aspect>",
  "backend": "<han-imagen-python | runtime-tool>",
  "satisfaction": "<satisfied | partial | unsatisfied>",
  "image_path": "<~/Downloads/han-skill-imagen/...>",
  "result_assessment": "<success | partial | failed>"
}
```

### 4.2 Markdown(写入用户当前工作目录)

`<YYYYMMDD-HHMMSS>-disassembly-diagram.md`:

```markdown
# <对象> 拆解图

> **案例 ID**:<YYYYMMDD-HHMMSS>
> **结论**:用 <mode> 出图,<满意度>

## 参数
| 项 | 值 |
|----|----|
| 对象类型 | ... |
| mode | ... |
| aspect | ... |

## 经验
<这个模式为什么好/不好,一句话>
```

## 步骤 5:更新 patterns.json

- 满意:`(object_type, mode)` 已有则 `confidence += 1, frequency += 1`;新组合追加 `confidence: 1`。
- 不满意:`confidence -= 1`,`<0` 移除。
- 部分满意:仅 `frequency`。
- 前后展示 diff preview。

## 步骤 6:更新领域知识(如适用)

新搭配经验追加到 [references/prompt-template.md](../references/prompt-template.md)。

## 步骤 7:输出闭环总结

```markdown
## 反馈闭环总结
- **对象**:<对象>
- **参数**:<mode> + <aspect>
- **满意度**:<satisfied/partial/unsatisfied>
- **案例存档**:JSON → skill `data/cases/<id>.json` | Markdown → 当前工程 `<id>.md`
- **经验库更新**:<新增/更新/降权了哪些组合>
```

---

闭环完成。经验已沉淀,下次相似对象类型将获得更准的模式推荐。
