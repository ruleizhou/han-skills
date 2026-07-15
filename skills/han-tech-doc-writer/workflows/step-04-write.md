# Step 4: 文档写作

将 Step 2 的大纲、wikilink 规划、Step 3 的 D2 SVG 和信息图组装成 Obsidian 原生中文技术文档。

## 4.1 准备工作

读取以下文件：
- `references/obsidian-guide.md` — frontmatter、wikilink、配图嵌入
- `references/writing-style-guide.md` — 中文技术写作规范

## 4.2 写作流程

按大纲逐章写作。对每一章：

### a. YAML frontmatter（文档最顶部）

```yaml
---
title: Qualcomm DMA 架构          # 必须与文件名（去 .md）完全一致
type: analysis                    # 见 obsidian-guide.md 映射表
tags: [架构, DMA, Qualcomm]
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: [[原始来源]]              # 或 URL 描述
doc_type: architecture-doc
source_type: url | file | paste
---
```

### b. 嵌入信息图（Hero/章节开篇）

信息图放在**醒目位置**，使用 Markdown 图片语法（PNG 位图）：

#### Hero 信息图（文档开篇）

放在 frontmatter 之后、`# 标题` 与引言之后、第一章之前：

```markdown
---
title: Qualcomm DMA 架构
...
---

# Qualcomm DMA 架构

> 一句话概括文档核心内容

![文档核心概念全景](_diagrams/Qualcomm DMA 架构-info.png)

*文档核心概念全景 — 一图看懂 [主题]*

---

## 1. 概述
```

#### 章节开篇信息图

放在章节标题之后、正文之前：

```markdown
## 2. 核心模块设计

![模块能力全景](_diagrams/Qualcomm DMA 架构-info-2.png)

*模块能力全景 — [模块数量] 大模块协作关系一览*

### 2.1 模块A

正文内容…
```

#### 信息图嵌入规则

- 信息图**不编 D2 式的图号**，与 D2 编号体系独立
- **禁止** `<div align="center">` 等 HTML 包裹
- 信息图下方用斜体说明，句式为"X 全景/一图看懂 Y"
- 信息图后可选 1-2 句引导文字，然后进入正文

### c. 写正文 + wikilink

- 正文全中文，技术术语保留英文原词
- **核心概念/模块首次出现时用 `[[页面名]]`**（见 Step 2 wikilink 清单）
- 来源标注：`> 来源：[[来源页面]]`
- 函数/变量名用反引号：`class_create()`、`dwc3_remove`
- 段落长度 3-7 句

### d. 嵌入 D2 图表（SVG + Obsidian wikilink）

如果该章有对应的 D2 图表：

```markdown
如图 1 所示，系统分为三层架构。

![[Qualcomm DMA 架构-arch.svg]]

*图 1: 系统整体架构*

上图展示了 [核心内容]，关键点在于：
- 要点一
- 要点二
```

规则：
- 图编号从 1 开始，D2 图表独立编号（不包含信息图）
- 正文必须先引用再放图："如图 N 所示，..."
- **正文嵌入用 Obsidian wikilink 语法 `![[...svg]]`**
- 图后紧跟 2-5 句解释
- SVG 路径相对于 .md 文件：`_diagrams/<slug>-<短码>.svg`

### e. 代码块

源内容中的代码使用 fenced code block：
````markdown
```c
static int dwc3_remove(struct platform_device *pdev)
{
    ...
}
```
````

### f. 文档尾部

```markdown
## 相关链接

- [[相关概念 A]]
- [[相关模块 B]]

## 参考资料

- [外部标题](https://example.com)
```

## 4.3 特殊情况处理

### 图片目录不存在或编译失败

如果 Step 3 未成功生成 SVG（d2 未安装或编译失败），将 D2 源代码作为代码块嵌入：

```markdown
**图 N: 标题名称** (D2 源代码，安装 d2 后编译为 SVG)

```d2
... D2 源码 ...
```
```

### 信息图缺失

如果某章有信息图需求但未能生成，在原位置标注:
> 🎨 *信息图: [主题] — 未能生成，可后续通过"加个信息图"命令补充*

### 源内容不足

如果源内容对某章的信息不够，不要编造。标注 `[待补充]` 或从常识补充后用注释标注"本节内容基于通用知识，非源文档直接提供"。

## 4.4 多文档模式

`multi_doc_mode: true` 时，逐篇重复 4.1–4.3，每篇独立 frontmatter、wikilink、`_diagrams/<slug>-*` 命名。

**完成后，读取 `workflows/step-05-review.md` 继续。**
