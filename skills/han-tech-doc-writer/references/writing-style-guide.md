# 中文技术写作风格指南

## 语言规范

### 正文

- 全中文撰写，使用简体中文
- 使用陈述句，客观描述
- 段落长度控制在 3-7 句，过长的段落拆开
- 禁止使用的词：显然、众所周知、很简单、不言而喻
- 推荐使用的词：如图所示、可见、需要注意、关键点在于

### 技术术语

- **保留英文原词**：IRQ, DMA, CPU, GPU, API, socket, buffer, handler, thread, mutex
- **函数/变量名用反引号**：`class_create()`、`dwc3_remove`、`pm_runtime_get_sync()`
- **首次出现可加中文标注**：Direct Memory Access (DMA)
- **协议/标准保留英文**：TCP/IP, USB 3.0, I2C, PCIe, HDMI
- **芯片/平台名保留英文**：Qualcomm SM6115, ARM Cortex-A55, Linux 5.15

### 代码块

````markdown
```c
static int dwc3_remove(struct platform_device *pdev)
{
    pm_runtime_put_sync(&pdev->dev);
    return 0;
}
```
````

- 使用 fenced code block，标注语言类型
- 行内代码用单个反引号：`struct device`
- 长命令太宽时用 `\` 换行

### 列表

- **无序列表**：枚举并列项
- **有序列表**：描述步骤/顺序
- 列表项保持语法一致（全名词短语或全动词短语）
- 列表项末尾不加句号（除非是完整句子）

## 结构规范

### 标题层级

- h1 → h2 → h3，不跳级
- 标题简短有力，5-12 字
- 同一层级标题保持语法平行

正确：

```markdown
## 2. 整体架构
### 2.1 应用层
### 2.2 内核层
```

错误：

```markdown
## 2. 整体架构
### 2.1 应用层是怎么设计的呢（太长）
#### 2.1.1 细节（h2 直接跳到 h4，跳级）
```

### 表格

```markdown
| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | `uint32_t` | 唯一标识符 |
| `name` | `char[32]` | 设备名称 |
```

- 表头加粗/语义化
- 列对齐整齐
- 字段/类型用反引号包裹

### D2 图表标注（Obsidian 原生，SVG 首选）

```markdown
如图 1 所示，系统分为三层。

![[Qualcomm DMA 架构-arch.svg]]

*图 1: 系统整体架构*
```

- 图编号从 1 开始递增
- 图标题带冒号：`图 N: 标题描述`
- 图标题在图片下方，用斜体
- 正文先引用再放图："如图 1 所示，系统分为三层..."
- 图后紧跟 2-5 句说明
- **正文嵌入 D2 图用 Obsidian wikilink 语法 `![[...svg]]`**
- SVG 内嵌亮/暗双主题，Obsidian 自动适配，无需 HTML 折叠

### 信息图标注（区别于 D2 图表）

信息图不使用图号，使用描述性标题：

```markdown
![文档核心概念全景](attachment/Qualcomm DMA 架构-info.png)

*文档核心概念全景 — [主题] 模块关系与数据流总览*
```

规则：

- 信息图标题不编号，用"X 全景"或"一图看懂 Y"等语句
- **禁止** `<div align="center">` 等 HTML 包裹（Obsidian 渲染不一致）
- 信息图后可选 1-2 句引导文字，然后进入正文
- D2 图表和信息图在文档中交替出现时，D2 图表编号独立（图 1, 图 2...），不包含信息图

### 强调

- **加粗** 用于关键术语首次出现
- *斜体* 用于图表标题
- `反引号` 用于代码/命令/文件名
- 不使用下划线（markdown 中容易和链接混淆）

## 文档元信息（Obsidian frontmatter）

### 头部（必填 YAML）

详见 `references/obsidian-guide.md`。示例：

```yaml
---
title: Qualcomm DMA 架构
type: analysis
tags: [架构, DMA]
created: 2026-07-15
updated: 2026-07-15
sources: [[原始来源]]
doc_type: architecture-doc
source_type: url
---

# Qualcomm DMA 架构

> 一句话概括
```

- **禁止**用 blockquote 代替 frontmatter 存元信息
- `title` 必须与文件名（去 `.md`）完全一致

### 双向链接

- 核心概念/模块首次出现：`[[页面名]]`
- 来源：`> 来源：[[来源页面]]`
- 文末汇总：`## 相关链接`

### 尾部

```markdown
## 相关链接

- [[相关概念 A]]

## 参考资料

- [标题](URL)
```

## 常见反模式

| 反模式 | 正确做法 |
| -------- | --------- |
| "我们可以通过 xxx 来实现" | "通过 xxx 实现" |
| "这个东西很简单" | 删掉，客观陈述 |
| 连续 10+ 行没有段落分隔 | 3-7 句拆一段 |
| 图表后面没有说明文字 | 加 2-5 句解释 |
| 中英文之间没有空格 | `通过 DMA 传输`（中文与英文间加半角空格） |
