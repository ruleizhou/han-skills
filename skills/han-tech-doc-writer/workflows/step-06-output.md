# Step 6: 输出与学习

将 Obsidian 页面写入 vault，可选归档案例，自动学习模式。

## 6.1 写文件

使用 `Write` 工具将完整文档写入 **Step 1.6 确认的** `output_dir`：

```
Write: <notes_root>/<子路径>/<标题>.md
```

例如：`80-Notes/Kernel/MMU/Qualcomm MMU 架构.md`

- **output_dir**：来自 Step 1.6（Notes 根 + 按内容匹配的子目录，用户已确认）
- **文件名**：`<标题>.md`，**标题 = frontmatter title = wikilink 名**（禁止 kebab-case slug）
- `attachment/` 与 `.md` **同目录**
- 目录须已在 Step 1.6 经用户确认创建；**禁止**在本步对未确认路径静默 `mkdir -p`

### 多文档模式

如果 Step 2 设置了 `multi_doc_mode: true`，按 `docs` 列表循环输出：

```
对 docs 中的每篇文档:
  1. Write: <doc.output_dir>/<doc.filename>     # 如 "80-Notes/Drivers/GPIO/GPIO 子系统.md"
  2. attachment/ 使用 <doc.title> 作为 slug 前缀（与 .md 同目录）
  3. 告知用户: "[i/N] [[doc.title]] → <doc.output_dir>/<doc.filename>"
```

每篇可有不同 `output_dir`（不同主题子目录）。

## 6.2 确认输出

输出完成后，告知用户：

```
Obsidian 页面已输出到: <notes_root>/<子路径>/<标题>.md
frontmatter type: analysis | concept | source
共 N 章, ~M 字, K 张 D2 SVG, I 张信息图, L 个 wikilink。

图表源文件在同目录 attachment/:
- attachment/<slug>-*.d2   (D2 源代码, 可二次编辑)
- attachment/<slug>-*.svg  (矢量图, Obsidian 内联, 亮/暗双主题)
- attachment/<slug>-info.png (信息图)
```

提示：

> Notes 页可用 `/han-llm-wiki ingest` 收录进 `wiki/` 知识层并更新索引。

## 6.3 案例归档（可选）

询问用户是否归档：

```
question: "是否将此文档归档为案例，供未来参考？"
header: "案例归档"
options:
  - label: "归档"
    description: "保存文档类型、Obsidian 结构、图表和信息图使用模式到模式库"
  - label: "跳过"
    description: "不归档，仅输出文档"
```

如果用户选择归档，生成案例文件写入 `data/cases/<YYYYMMDD-HHMMSS>-<short-name>.json`：

```json
{
  "id": "<YYYYMMDD-HHMMSS>-<short-name>",
  "date": "YYYY-MM-DD",
  "title": "Obsidian 页面标题",
  "filename": "Qualcomm DMA 架构.md",
  "vault_path": "80-Notes/Kernel/MMU/",
  "frontmatter_type": "analysis",
  "doc_type": "architecture-doc|api-doc|troubleshooting-guide|design-doc|kb-article",
  "source_type": "paste|url|file",
  "wikilink_count": 5,
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
