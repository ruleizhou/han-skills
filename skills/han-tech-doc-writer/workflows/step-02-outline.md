# Step 2: 结构化与大纲

根据 Step 1 提取的内容、领域识别结果和 Step 0 确定的文档类型，生成文档大纲并标记图表与信息图需求。

## 2.0 多领域分拆决策（条件触发）

仅当 Step 1 的 1.5 识别到多个知识领域时执行此节。如果 Step 1 传递了 `single_area: true`，直接跳到 2.1。

### 2.0.1 呈现领域清单

向用户展示 Step 1 的识别结果：

```
源文档包含以下 N 个独立的知识领域:
  1. GPIO 子系统 — 第2-4章, 术语: gpio, pinctrl, tlmm, irq
  2. I2C 总线   — 第5-7章, 术语: i2c, qup, sda, scl
  3. SPI 控制器 — 第8-10章, 术语: spi, qup, dma, transfer
  4. UART 串口  — 第11-12章, 术语: uart, baud, console
```

### 2.0.2 分拆策略选择

```
question: "源文档涉及多个知识领域，如何处理？"
header: "分拆策略"
options:
  - label: "整合为一篇"
    description: "生成一篇综合性文档，按领域分章节组织"
  - label: "按领域拆分为多篇（推荐）"
    description: "每个领域独立输出一篇文档，共 N 篇"
  - label: "只写选定领域"
    description: "从中挑选 1 个或多个领域，忽略其余"
```

### 2.0.3 分支处理

**分支 A — 整合为一篇**:

- 按领域作为一级章节（h2），每个领域内部按 doc-structure-guide.md 的模板组织（概述→架构→流程→总结）
- 图表编号全局递增（图 1、图 2... 跨领域连续编号）
- 信息图同样全局管理（每领域 1 张 hero 信息图）
- 大纲示例：
  ```
  # Qualcomm 外设总线文档

  🎨 信息图: 外设总线全景 (hero, 标题后第一屏)

  ## 1. GPIO 子系统
  ### 1.1 概述
  ### 1.2 GPIO 架构
  📊 图: GPIO 架构图 (system-architecture)
  ### 1.3 关键流程
  📊 图: GPIO 中断处理流程 (flowchart)
  ## 2. I2C 总线
  ### 2.1 概述
  ### 2.2 I2C 架构
  📊 图: I2C QUP 架构图 (system-architecture)
  ...
  ```
- 设置 `multi_doc_mode: false`，`doc_count: 1`

**分支 B — 按领域拆分为多篇**:

- 为每个领域独立生成大纲，各自遵循 doc-structure-guide.md 模板
- 每篇图表独立编号（各自从图 1 开始）
- 每篇各自判定信息图需求
- 询问用户：所有领域用同一种文档类型还是各自选择？

```
question: "各领域的文档类型？"
header: "文档类型"
options:
  - label: "统一类型"
    description: "所有领域使用相同的文档类型（沿用 Step 0 选择的类型）"
  - label: "各自选择"
    description: "每个领域可以选不同的文档类型"
```

- 设置 `multi_doc_mode: true`，`docs` 列表（**Obsidian 命名：filename = title + .md**）：
  ```
  docs: [
    { title: "GPIO 子系统", filename: "GPIO 子系统.md", area: "GPIO", doc_type: "architecture-doc", output_dir: "80-Notes/Drivers/GPIO/" },
    { title: "I2C 总线",   filename: "I2C 总线.md",   area: "I2C",  doc_type: "architecture-doc", output_dir: "80-Notes/Hardware/I2C/" },
    ...
  ]
  ```

**分支 C — 只写选定领域**:

- 使用 `结构化提问` 让用户勾选领域（multiSelect: true）
- 仅选中 1 个领域 → 等同于单文档，正常走 2.1
- 选中多个领域 → 回到分支 A 或 B（在确认领域后再问一次整合/拆分）

### 2.0.4 多文档模式标记

如果选择了分支 B（拆分为多篇），设置以下上下文标记传递给 Step 3-6：

```
multi_doc_mode: true
docs: [{title, filename, area, doc_type}, ...]
```

后续 Step 适配规则：
- **Step 3**: 每篇文档在各自 `output_dir/_diagrams/` 下生成图（或同 Notes 子目录共享 `_diagrams/`，用 slug 前缀区分）
- **Step 4**: 逐篇写作，第 i 篇完成后继续第 i+1 篇
- **Step 5**: 逐篇审核
- **Step 6**: 逐篇输出到各自 `output_dir`（来自 Step 1.6）

> 若 Step 1.6 尚未为某领域确认子路径，分拆确认后须补跑缺失目录的交互确认。
## 2.1 读取结构模板

先读取 `references/doc-structure-guide.md` 与 `references/obsidian-guide.md`，找到对应文档类型的推荐结构模板，了解该类型的**信息图机会**与 **wikilink 规划**。

## 2.2 生成大纲

按模板结构 + 源内容的章节组织，生成文档大纲。大纲需包含：

- 每章标题（h2）
- 子章节标题（h3，如有）
- 每章预期篇幅（简短/标准/详细）
- **每章图表需求标记**（📊 = D2 图, 🎨 = 信息图）

### 大纲示例（架构文档，含信息图）

```
# [系统名称] 架构文档

> 🎨 信息图: 文档概念全景图 (hero, 标题后第一屏)

## 1. 概述                                   [~200 字]
## 2. 整体架构                               [~500 字]
   - 架构分层说明
   📊 图: 系统架构图 (system-architecture)
## 3. 核心模块设计                           [~800 字]
   - 3.1 模块A
   - 3.2 模块B
   🎨 信息图: 模块能力全景 (章节开篇)
   📊 图: 模块关系图 (system-architecture)
## 4. 关键流程                               [~500 字]
   - 4.1 数据流
   - 4.2 控制流
   📊 图: 核心流程图 (flowchart)
## 5. 部署方案                               [~300 字]
   📊 图: 部署架构图 (network-topology)
## 6. 总结                                   [~150 字]
```

### 2.2.5 信息图候选判定

在生成大纲时，同时判定哪些内容适合用信息图呈现。判定规则：

| 内容特征 | 视觉元素 | 标记 |
|---------|---------|------|
| 概念全景/总览摘要 | 信息图 | 🎨 |
| 模块关系/架构分层 | D2 图表 | 📊 |
| 数据对比/指标展示 | 信息图 | 🎨 |
| 流程/决策分支 | D2 图表 | 📊 |
| 时序/调用序列 | D2 图表 | 📊 |
| 关键概念"一图看懂" | 信息图 | 🎨 |
| ER/类图/状态机 | D2 图表 | 📊 |

信息图候选限制：每个文档 1-3 张（Hero 1 张 + 关键章节 0-2 张）。

## 2.3 wikilink 规划

列出正文中将出现的关键 `[[链接]]`（见 obsidian-guide.md §3）：

| 链接目标 | 首次出现章节 | 角色 |
|---------|-------------|------|
| [[核心模块 A]] | 2. 整体架构 | 模块 |
| [[相关概念 B]] | 1. 概述 | 背景概念 |

- 链接名必须与预期 Obsidian 页面标题一致（= 文件名去 `.md`）
- 文末「相关链接」章节汇总全部 wikilink

## 2.4 图表与信息图需求统计

汇总所有标记了 📊 和 🎨 的视觉需求。

### D2 图表清单

| 编号 | 所在章节 | 图表类型 | 内容说明 |
|------|---------|---------|---------|
| 图 1 | 2. 整体架构 | system-architecture | 三层架构分层 |
| 图 2 | 3. 核心模块 | system-architecture | 模块间依赖关系 |
| 图 3 | 4. 关键流程 | flowchart | 数据写入主流程 |
| 图 4 | 5. 部署方案 | network-topology | 集群部署拓扑 |

### 信息图清单

| 编号 | 位置 | 内容主题 | 建议布局 | 建议风格 |
|------|------|---------|---------|---------|
| info-1 | 文档开头(Hero) | 系统全景一览 | dense-modules | journal |
| info-2 | 3. 核心模块开头 | 模块能力全景 | technical-map | lab-notes |

信息图布局/风格建议可参考 `data/patterns.json` 中 `category: "infographic-layout-style"` 的经验条目。

## 2.5 展示确认

将大纲简要展示给用户（标题 + wikilink 清单 + 图表清单 + 信息图清单），询问：

> 大纲如上，Obsidian 页面标题 `[标题].md`，预计 N 个 wikilink、N 张 D2 SVG + M 张信息图。是否 OK？需要调整章节、链接或图表吗？

如果用户要求调整，修改后重新确认。如果不需调整，直接进入 Step 3。

**完成后，读取 `workflows/step-03-diagram.md` 继续。**
