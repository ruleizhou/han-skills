# Step 0: 交互诊断

在开始写作前，收集必要的输入信息。根据上下文灵活跳过已有信息的询问。

**开始前读取** `references/obsidian-guide.md`，后续所有输出按 Obsidian 原生规范执行。

## 0.1 输入来源

如果用户消息中已包含文档内容或明确提供了文件路径/URL，跳过此步。

否则使用 `结构化提问`：

```
question: "文档内容从哪来？"
header: "输入来源"
options:
  - label: "对话中已粘贴"
    description: "直接把技术文档内容粘贴到对话中"
  - label: "提供 URL 链接"
    description: "从网页 URL 抓取技术文章"
  - label: "本地文件"
    description: "读取本地 .md/.txt/.pdf 等文件"
```

## 0.2 文档类型

如果用户已明确文档类型（如"写个架构文档"），跳过此步。

先读 `references/doc-structure-guide.md` 了解 5 种文档类型的差异，然后：

```
question: "需要生成哪种类型的文档？"
header: "文档类型"
options:
  - label: "架构文档"
    description: "系统架构、模块设计、组件关系"
  - label: "API/接口文档"
    description: "接口定义、参数说明、调用流程"
  - label: "排障指南"
    description: "问题现象、排查步骤、根因分析"
  - label: "设计文档"
    description: "方案背景、设计决策、实现细节"
  - label: "知识库文章"
    description: "概念解释、最佳实践、操作指南"
```

## 0.3 受众与深度

```
question: "目标受众和深度？"
header: "受众深度"
options:
  - label: "入门概览"
    description: "面向新手的概述，篇幅较短 (500-1500 字)"
  - label: "标准详解（推荐）"
    description: "面向有基础的技术人员，详细阐述 (1500-3000 字)"
  - label: "专家深度"
    description: "面向专家，包括实现细节和源码分析 (3000+ 字)"
```

## 0.4 Notes 根目录（固定策略，不选 wiki/）

**默认输出到 Notes 区**（首选 `80-Notes/`），**不**输出到 `wiki/analyses|concepts|sources/`。

### 解析 Notes 根

按顺序检测（cwd / vault 根）：

1. 存在 `80-Notes/` → 使用，记为 `notes_root=80-Notes`
2. 否则存在任一 `NN-Notes/`（如 `08-Notes/`、`10-Notes/`）→ **复用**，告知「检测到已有 Notes 根 `08-Notes/`，将写入其下」
3. 都不存在 → 必须交互：

```
question: "未找到 Notes 目录，如何处理？"
header: "Notes 根目录"
options:
  - label: "创建 80-Notes/（推荐）"
    description: "在 vault 根新建 80-Notes 作为笔记输出区"
  - label: "自定义路径"
    description: "用户指定 Notes 根目录"
  - label: "当前目录"
    description: "不建 Notes，直接写到 cwd（仍为 Obsidian 格式）"
```

若用户已显式指定完整输出目录，跳过本步。

### 子路径延后

具体子目录（如 `80-Notes/Kernel/MMU/`）在 **Step 1.6** 读完源内容后按主题匹配；目录缺失时再交互确认是否创建。Step 0 只锁定 `notes_root`。

frontmatter `type` 仍按文档类型映射（见 obsidian-guide.md），与物理路径解耦。
## 0.5 Obsidian 页面标题与文件名

**铁律：文件名 = 链接名 = frontmatter `title`**（见 obsidian-guide.md）

如果用户未指定标题，从文档主题推导**中文或英文可读标题**（禁止 kebab-case slug 作文件名）。

```
question: "Obsidian 页面标题（= 文件名）？"
header: "页面标题"
options:
  - label: "<自动推导，如「Qualcomm DMA 架构」>"
    description: "从文档内容生成可读标题，文件名与之完全一致"
  - label: "自定义"
    description: "用户输入标题，文件名 = 标题 + .md"
```

多文档模式（Step 2 拆分）时，每篇文档独立标题，各自 `filename: "<标题>.md"`。

## 0.6 确认汇总

汇总所有诊断结果，一句话确认：

> 好的，我会将 [来源] 中的技术内容整理为一份 [文档类型] Obsidian 页面，面向 [受众]，Notes 根为 `[notes_root]/`，子路径将根据内容在读取源后确认（缺失目录会先问你是否创建）。输出为 `[notes_root]/[主题子路径]/[标题].md`。D2→SVG，信息图→PNG，正文使用 `[[wikilink]]`。现在开始。

**完成后，读取 `workflows/step-01-source.md` 继续。**
