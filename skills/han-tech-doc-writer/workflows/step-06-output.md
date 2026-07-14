# Step 6: 输出与学习

将文档写入本地文件，可选归档案例，自动学习模式。

## 6.1 写文件

使用 `Write` 工具将完整文档写入 Step 0 确定的输出路径：

```
Write: <输出路径>/<文件名>.md
```

- **输出路径**：来自 Step 0.4 的选择（当前工作目录或用户自定义目录）
- **文件名**：来自 Step 0.5 的选择（自动推导或用户指定）
- `_diagrams/` 图片目录同样在输出路径下创建
- 如果输出路径不存在，先 `mkdir -p` 创建

### 多文档模式

如果 Step 2 设置了 `multi_doc_mode: true`，按 `docs` 列表循环输出：

```
对 docs 中的每篇文档:
  1. Write: <输出路径>/<doc.filename>.md
  2. 告知用户: "[i/N] <doc.title> → <输出路径>/<doc.filename>.md"
```

每篇文档的 `_diagrams/` 放在各自子目录 `<输出路径>/_diagrams/<doc-slug>/`，避免图片冲突。

## 6.2 确认输出

输出完成后，告知用户：

```
文档已输出到: <cwd>/<文件名>.md
共 N 章, ~M 字, K 张 D2 图表, I 张信息图。

图表源文件在 _diagrams/ 目录:
- _diagrams/*.d2  (D2 源代码, 可二次编辑)
- _diagrams/*.png (位图, D2 图表 + 信息图)
- _diagrams/*.svg (矢量图, 仅 D2, 支持暗色主题)
```

## 6.3 案例归档（可选）

询问用户是否归档：

```
question: "是否将此文档归档为案例，供未来参考？"
header: "案例归档"
options:
  - label: "归档"
    description: "保存文档类型、结构模板、图表和信息图使用模式到模式库"
  - label: "跳过"
    description: "不归档，仅输出文档"
```

如果用户选择归档，生成案例文件写入 `data/cases/<YYYYMMDD-HHMMSS>-<short-name>.json`：

```json
{
  "id": "<YYYYMMDD-HHMMSS>-<short-name>",
  "date": "YYYY-MM-DD",
  "title": "文档标题",
  "doc_type": "architecture-doc|api-doc|troubleshooting-guide|design-doc|kb-article",
  "source_type": "paste|url|file",
  "total_sections": 6,
  "total_d2_diagrams": 3,
  "total_infographics": 2,
  "diagram_types": ["system-architecture", "flowchart"],
  "infographic_placements": [
    {"position": "hero", "layout": "dense-modules", "style": "journal"},
    {"position": "section-3", "layout": "technical-map", "style": "lab-notes"}
  ],
  "patterns_matched": ["ptrn-001", "ptrn-003"],
  "outcome": "success"
}
```

## 6.4 模式学习（自动，静默）

归档后自动更新 `data/patterns.json`：

### D2 图表模式

- 匹配到的模式（在 Step 2/3 中使用了其 diagram_type 或 doc_type 建议）如果最终结果良好：`confidence += 1, frequency += 1`
- 如果本次使用的新模式不在 patterns.json 中，追加新条目，初始 `confidence = 1, frequency = 1`

### 信息图模式

- 对本次使用的信息图布局/风格组合：
  - 如果该 content_type + layout + style 组合已存在 → `confidence += 1, frequency += 1`
  - 如果不存在 → 追加新条目（初始 `confidence = 1, frequency = 1`），`category: "infographic-layout-style"`

- 更新 `first_seen` / `last_seen` 时间戳

不弹出确认 — 这是静默的学习过程。

## 6.5 反馈闭环提示

简要告知用户反馈闭环的存在：

> 如果后续对文档有修改或想反馈文档质量，随时说"搞定了"，我会启动反馈闭环记录改进建议。

不主动触发反馈闭环。

**所有步骤完成。如果用户需要对另一份文档进行整理，从 Step 0 重新开始。**
