# 反馈闭环

用户已发出「这版不错 / 就用这版 / 搞定了」信号,现在回顾历史、确认结果、存档案例、更新经验库。

## 步骤 1:回顾本次过程

从当前对话历史与工作目录中提取:

- 源内容 / 主题
- 最终选用的参数:**内容类型、layout、style、aspect、lang**
- 出图用的后端(han-imagen Python / 运行时工具)与 provider
- 用户的满意度反馈
- 最终图片路径与生成文件清单

对话历史或文件里找不到的,用 AskUserQuestion 向用户确认关键细节。

## 步骤 2:呈现回顾

把生成轮次按时间排序呈现给用户:

```markdown
## 回顾

| # | 内容类型 | layout | style | aspect | 满意度 | 产物 |
|---|---------|--------|-------|--------|--------|------|
| 1 | ... | ... | ... | ... | ... | ... |
```

## 步骤 3:确认最终结果

用 AskUserQuestion 让用户确认:

- **全部满意**:参数组合有效,confidence +1
- **部分满意**:有些参数可用,有些要调整(记录哪些)
- **不满意**:组合无效,confidence -1

## 步骤 4:存档案例(双格式)

### 4.1 JSON(写入 skill 内部,供 patterns 匹配)

写入 `data/cases/<YYYYMMDD-HHMMSS>-infographic.json`:

```json
{
  "id": "<YYYYMMDD-HHMMSS>",
  "timestamp": "<ISO8601>",
  "input_summary": "<主题>",
  "content_type": "<内容类型>",
  "layout": "<layout>",
  "style": "<style>",
  "aspect": "<aspect>",
  "backend": "<han-imagen-python | runtime-tool>",
  "provider": "<openai | google | runtime>",
  "satisfaction": "<satisfied | partial | unsatisfied>",
  "image_path": "<~/Downloads/han-skill-imagen/...>",
  "result_assessment": "<success | partial | failed>"
}
```

### 4.2 Markdown(写入用户当前工作目录,供阅读/分享)

写入当前工程路径下 `<YYYYMMDD-HHMMSS>-infographic.md`:

```markdown
# <主题> 信息图

> **案例 ID**:<YYYYMMDD-HHMMSS>
> **结论**:用 <layout> + <style> 出图,<满意度>

## 参数
| 项 | 值 |
|----|----|
| 内容类型 | ... |
| layout | ... |
| style | ... |
| aspect | ... |

## 视觉模块(摘要)
- 模块1:...
- 模块2:...

## 经验
<这个组合为什么好/不好,一句话>
```

JSON 进 skill 内部供自动索引,Markdown 进用户工程供阅读。两者内容一致。

## 步骤 5:更新 patterns.json

更新 [data/patterns.json](../data/patterns.json):

- **满意(success)**:对应 `(content_type, layout, style)` 组合 → 已有则 `confidence += 1, frequency += 1`;新组合则追加 `confidence: 1`。
- **不满意(failed)**:对应组合 `confidence -= 1`;`confidence < 0` 时从 patterns 中移除。
- **部分满意(partial)**:仅更新 `frequency`,不动 confidence。
- 更新前后展示 diff preview 让用户 review。

## 步骤 6:更新领域知识(如适用)

若本次揭示了新的搭配经验(如「某风格在深色背景中文易糊,换浅色」),追加到 [references/layouts-and-styles.md](../references/layouts-and-styles.md) 的「组合推荐」段落。

## 步骤 7:输出闭环总结

```markdown
## 反馈闭环总结

- **任务**:<主题>
- **参数**:<layout> + <style> + <aspect>
- **满意度**:<satisfied/partial/unsatisfied>
- **案例存档**:JSON → skill `data/cases/<id>.json` | Markdown → 当前工程 `<id>.md`
- **经验库更新**:<新增/更新/降权了哪些组合,confidence 变化>
```

---

闭环完成。本次经验已沉淀到 `data/cases/`(机读)与当前工作路径(可读),`patterns.json` 已更新,下次相似内容类型将获得更准的参数推荐。
