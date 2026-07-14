# Step 0: 交互诊断

在开始写作前，收集必要的输入信息。根据上下文灵活跳过已有信息的询问。

## 0.1 输入来源

如果用户消息中已包含文档内容或明确提供了文件路径/URL，跳过此步。

否则使用 `AskUserQuestion`：

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

## 0.4 输出路径

如果用户已指定输出目录，跳过此步。

```
question: "文档输出到哪个目录？"
header: "输出路径"
options:
  - label: "当前目录（推荐）"
    description: "输出到当前工作目录"
  - label: "自定义目录"
    description: "指定一个本地目录路径"
```

如果用户选择"自定义目录"，让用户输入目录路径（绝对路径或相对于当前目录的路径）。路径不存在时，输出前自动创建。

## 0.5 输出文件名

如果用户未指定文件名，从文档标题或主题推导一个合适的文件名。

```
question: "输出文件名？"
header: "文件名"
options:
  - label: "<自动推导>"
    description: "从文档内容自动生成文件名"
  - label: "自定义"
    description: "让用户输入文件名"
```

## 0.6 确认汇总

汇总所有诊断结果，一句话确认：

> 好的，我会将 [来源] 中的技术内容整理为一份 [文档类型]，面向 [受众]，输出到 `[输出路径]/[文件名].md`。D2 图表展示技术细节，信息图展示概念全景。现在开始。

输出路径默认为当前工作目录（`<cwd>`），如用户选了自定义目录则使用用户指定的路径。

**完成后，读取 `workflows/step-01-source.md` 继续。**
