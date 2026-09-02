# Obsidian 原生输出规范

> **与 `han-llm-wiki` 对齐**：本 skill 输出的 `.md` 可直接放入 Obsidian vault，也可由 `/han-llm-wiki ingest` 收录。规范以 `han-llm-wiki` 的 `SKILL.md`、`page-templates.md`、`diagram-guide.md` 为单一真源。

---

## 1. 文件命名（铁律）

**文件名 = 链接名 = frontmatter `title`**（无例外）

| 正确 | 错误 |
| ------ | ------ |
| `Qualcomm DMA 架构.md` → `[[Qualcomm DMA 架构]]` | `qualcomm-dma-architecture.md` → 死链 |
| `GPIO 子系统.md` | `gpio-subsystem.md` |
| `API 接口说明.md` | `api-doc.md` |

- 英文标题含空格时，文件名也含空格：`Qualcomm IPC Logging.md`
- 禁止链接带 `.md`：`[[overview.md]]` → 死链，正确 `[[overview]]`
- **kebab-case 仅限**非 wiki 页面的代码路径/URL，且**不用** `[[]]` 包裹

---

## 2. YAML frontmatter（必填）

每个输出页面必须包含：

```yaml
---
title: 页面标题          # 必须与文件名（去 .md）完全一致
type: analysis           # 见下方文档类型映射
tags: [架构, DMA, Qualcomm]
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: [[来源页或 URL 描述]]   # 可选；有原始来源时填写
doc_type: architecture-doc       # han-tech-doc-writer 内部类型，便于检索
source_type: url | file | paste   # 输入来源
---
```

### 文档类型 → frontmatter `type` 映射

| han-tech-doc-writer 类型 | frontmatter `type` | 物理输出位置 |
| -------------------------- | ------------------- | ------------- |
| 架构文档 | `analysis` | `80-Notes/<按内容分类>/` |
| 设计文档 | `analysis` | `80-Notes/<按内容分类>/` |
| 排障指南 | `analysis` | `80-Notes/<按内容分类>/` |
| API/接口文档 | `source` | `80-Notes/<按内容分类>/` |
| 知识库文章 | `concept` | `80-Notes/<按内容分类>/` |

**所有文档类型统一写入 Notes 区**（默认 `80-Notes/`），按内容落到合适子目录；**不写入** `wiki/analyses|concepts|sources/`（那是 llm-wiki 知识层）。frontmatter 与命名规范不变。

---

## 3. 双向链接

- 正文使用 `[[页面名]]` 连接相关概念、模块、来源
- 首次提及的核心概念/模块名，优先用 wikilink（若 vault 中尚无对应页，链接为「待建页」，Obsidian 可后续补全）
- 来源标注：`> 来源：[[来源页面]]` 或 frontmatter `sources`
- 矛盾标记：`⚠️ 与 [[另一页面]] 中的描述存在矛盾`
- **禁止**在 wikilink 中使用 kebab-case 英文名（除非文件名本身就是该英文名）

### 大纲阶段链接规划（Step 2）

生成大纲时同步列出「预期 wikilink」清单：

| 链接目标 | 首次出现章节 | 说明 |
| --------- | ------------- | ------ |
| `[[DMA 控制器]]` | 2. 整体架构 | 核心模块 |
| `[[Qualcomm 平台]]` | 1. 概述 | 背景 |

---

## 4. 图片与 `attachment/`

与 `han-llm-wiki/references/diagram-guide.md` 一致：

```
<输出目录>/
├── Qualcomm DMA 架构.md
└── attachment/                          ← 与 .md 同目录，共享
    ├── Qualcomm DMA 架构-arch.d2
    ├── Qualcomm DMA 架构-arch.svg      ← D2 正文内联（首选）
    ├── Qualcomm DMA 架构-flow.svg
    ├── Qualcomm DMA 架构-info.png      ← 信息图（AI 引擎）
    └── Qualcomm DMA 架构-info-prompt.md
```

**命名**：`<页面 slug>-<类型短码>.{d2,svg,png,md}`

- slug = 页面文件名去 `.md`
- D2 短码：`arch` / `flow` / `state` / `seq` / `er` / `class` / `net` / `gantt`
- 信息图短码：`info`

### 嵌入语法

**D2 图（首选 SVG）**：

```markdown
如图 1 所示，系统分为三层。

![[Qualcomm DMA 架构-arch.svg]]

*图 1: 系统整体架构*

上图展示了 …（2-5 句说明）
```

Obsidian 原生 wikilink 图片语法 `![[path]]` 与标准 Markdown `![](path)` **均可**；本 skill **默认 D2 用 wikilink 嵌入 SVG**，信息图用 Markdown 嵌入 PNG：

```markdown
![文档核心概念全景](attachment/Qualcomm DMA 架构-info.png)

*文档核心概念全景 — DMA 子系统模块关系与数据流总览*
```

- **禁止** `<div align="center">`（Obsidian 渲染不一致）
- **禁止** HTML `<details>` 折叠 SVG（Obsidian 用 SVG 内嵌亮/暗主题即可）
- D2 编译命令：`d2 --theme=300 --dark-theme=200 -l elk attachment/<name>.d2 attachment/<name>.svg`
- PNG 为可选产物，**不因 PNG 失败而中断**

---

## 5. 页面结构模板

```markdown
---
title: Qualcomm DMA 架构
type: analysis
tags: [架构, DMA, Qualcomm]
created: 2026-07-15
updated: 2026-07-15
sources: [[原始技术文档 URL 或文件名]]
doc_type: architecture-doc
source_type: url
---

# Qualcomm DMA 架构

> 一句话概括文档核心内容

![文档核心概念全景](attachment/Qualcomm DMA 架构-info.png)

*文档核心概念全景 — 一图看懂 DMA 子系统*

## 1. 概述

正文…首次提及 [[DMA 控制器]] 时建立链接。

## 2. 整体架构

如图 1 所示…

![[Qualcomm DMA 架构-arch.svg]]

*图 1: 系统整体架构*

…

## 相关链接

- [[相关概念 A]]
- [[相关模块 B]]

## 参考资料

- [外部标题](https://example.com)
```

---

## 6. 输出路径：`80-Notes/` + 按内容分子目录

### 6.1 Notes 根目录解析

| 优先级 | 条件 | 动作 |
| -------- | ------ | ------ |
| 1 | 存在 `80-Notes/` | 使用它 |
| 2 | 存在其他 `NN-Notes/`（如 `08-Notes/`、`10-Notes/`） | 复用已有 Notes 根，并告知用户 |
| 3 | 都不存在 | `结构化提问`：是否创建 `80-Notes/`？或自定义路径 |

**禁止**默认写到 `wiki/analyses/`、`wiki/concepts/`、`wiki/sources/`。

### 6.2 按内容选择子目录（Step 1.6，读完源后执行）

在 Notes 根下，按主题/领域选子路径，例如：

```
80-Notes/
├── Kernel/
│   ├── MMU/          ← MMU / 页表 / TLB 类文档
│   └── DMA/          ← DMA / IOMMU 类文档
├── Debug/            ← 排障 / crash / KASAN 类
├── Drivers/          ← 驱动子系统类
└── Hardware/         ← I2C / SPI / UART 等接口类
```

**匹配顺序**：

1. 扫描 Notes 根下已有子目录树
2. 用源内容领域关键词（标题、术语聚类、Step 1.5 领域名）与已有目录名做语义匹配
3. 可参考 vault 顶层领域目录（如 `03-Kernel/`、`06-Debug/`）作为子路径命名提示
4. 提出推荐路径，如 `80-Notes/Kernel/MMU/`

### 6.3 目录缺失时必须交互确认

目标子目录**不存在**时，**禁止静默 `mkdir -p`**，必须 `结构化提问`：

```
question: "目录「80-Notes/Kernel/DMA/」不存在，如何处理？"
header: "创建目录"
options:
  - label: "创建该目录"
    description: "mkdir -p 后写入此路径"
  - label: "改用已有目录"
    description: "从 Notes 下已有子目录中选择"
  - label: "自定义路径"
    description: "用户指定相对 Notes 根的子路径"
```

仅用户确认「创建」或选定已有/自定义路径后，才进入后续写作与输出。

多文档拆分时，每篇文档各自走一遍子路径匹配 + 缺失确认。

输出后可选提示：「可用 `/han-llm-wiki ingest` 将 Notes 页收录进 wiki 知识层」。

---

## 7. 输出前自检（Obsidian）

- [ ] 文件名 = frontmatter `title` = 所有 `[[]]` 链接名
- [ ] frontmatter 含 `title` / `type` / `created` / `updated`
- [ ] 无 `[[]]` 带 `.md` 后缀
- [ ] D2 图嵌入 `.svg`，路径在 `attachment/` 且文件存在
- [ ] 每张图后有 2-5 句说明
- [ ] 无 `<div>` / HTML 折叠块
- [ ] 核心概念在正文中有 `[[wikilink]]`
