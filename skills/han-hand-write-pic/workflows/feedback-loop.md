# 反馈闭环

用户已发出「这版不错 / 就用这版 / 搞定了」信号,回顾、确认、存档、更新经验库。

## 步骤 1:回顾本次过程

从对话历史与工作目录提取:

- 源内容 / 主题
- 最终选用参数:**内容类型、style、density、aspect、lang**
- 出图后端(han-imagen Python / 运行时工具)与 provider
- 用户满意度
- 最终图片路径与生成文件清单

找不到的用 AskUserQuestion 确认。

## 步骤 2:呈现回顾

```markdown
## 回顾

| # | 内容类型 | style | density | aspect | 满意度 | 产物 |
|---|---------|-------|---------|--------|--------|------|
| 1 | ... | ... | ... | ... | ... | ... |
```

## 步骤 3:确认最终结果

AskUserQuestion:全部满意(confidence +1)/ 部分满意(记录哪些)/ 不满意(confidence -1)。

## 步骤 4:存档案例(双格式)

### 4.1 JSON(写入 skill 内部)

`data/cases/<YYYYMMDD-HHMMSS>-hand-write-pic.json`:

```json
{
  "id": "<YYYYMMDD-HHMMSS>",
  "timestamp": "<ISO8601>",
  "input_summary": "<主题>",
  "content_type": "<内容类型>",
  "style": "<style>",
  "density": "<normal|high>",
  "aspect": "<aspect>",
  "backend": "<han-imagen-python | runtime-tool>",
  "satisfaction": "<satisfied | partial | unsatisfied>",
  "image_path": "<~/Downloads/han-skill-imagen/...>",
  "result_assessment": "<success | partial | failed>"
}
```

### 4.2 Markdown(写入用户当前工作目录)

`<YYYYMMDD-HHMMSS>-hand-write-pic.md`:

```markdown
# <主题> 手绘知识卡

> **案例 ID**:<YYYYMMDD-HHMMSS>
> **结论**:用 <style> + <density> 出图,<满意度>

## 参数
| 项 | 值 |
|----|----|
| 内容类型 | ... |
| style | ... |
| density | ... |
| aspect | ... |

## 经验
<这个组合为什么好/不好,一句话>
```

## 步骤 5:更新 patterns.json

- 满意(success):`(content_type, style, density)` 已有则 `confidence += 1, frequency += 1`;新组合追加 `confidence: 1`。
- 不满意(failed):`confidence -= 1`,`<0` 移除。
- 部分满意:仅 `frequency`。
- 前后展示 diff preview。

## 步骤 6:更新领域知识(如适用)

新搭配经验追加到 [references/prompt-template.md](../references/prompt-template.md) 的风格说明。

## 步骤 7:输出闭环总结

```markdown
## 反馈闭环总结
- **任务**:<主题>
- **参数**:<style> + <density> + <aspect>
- **满意度**:<satisfied/partial/unsatisfied>
- **案例存档**:JSON → skill `data/cases/<id>.json` | Markdown → 当前工程 `<id>.md`
- **经验库更新**:<新增/更新/降权了哪些组合>
```

---

闭环完成。经验已沉淀,下次相似内容类型将获得更准的风格/密度推荐。
