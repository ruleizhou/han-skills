# 图表放置指南

涵盖 D2 图表与信息图的视觉元素放置规则。

## 核心原则

1. **每个主要概念至少配一张图** — 图是信息的骨架，文是图的展开
2. **D2 图表展示技术细节，信息图展示概念全景** — 互补不重复
3. **文字先定义概念，图展示关系** — 正文引出图，图后紧跟解释
4. **图后紧跟 2-5 句说明** — 不加说明的图等于没放
5. **技术文档正式风格** — D2 使用 `--theme=300`，不加 `--sketch`

## 图表类型选择映射

### 系统架构图 (system-architecture)
- **适用场景**: 系统分层、模块划分、组件关系、依赖拓扑
- **D2 模板**: `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/system-architecture.d2`
- **推荐 shapes**: `rectangle`(模块), `cylinder`(数据库), `cloud`(外部服务), `queue`(消息队列)
- **放置位置**: 概述之后 / 架构章节开头
- **布局引擎**: `elk`

### 流程图 (flowchart)
- **适用场景**: 业务流程、处理步骤、决策分支、算法逻辑
- **D2 模板**: `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/flowchart.d2`
- **推荐 shapes**: `oval`(起止), `rectangle`(处理), `diamond`(决策)
- **放置位置**: 流程章节开头
- **布局引擎**: `dagre`

### 时序图 (sequence-diagram)
- **适用场景**: 跨模块交互、API 调用序列、中断处理顺序、协议握手
- **D2 模板**: `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/sequence-diagram.d2`
- **推荐 shapes**: `sequence_diagram`
- **放置位置**: 接口/流程章节
- **布局引擎**: `dagre`

### 状态机图 (state-machine)
- **适用场景**: 状态转换、生命周期管理、协议状态、订单/任务状态流转
- **D2 模板**: `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/state-machine.d2`
- **推荐 shapes**: `oval`(状态节点), `rectangle`(转换说明)
- **放置位置**: 状态管理章节
- **布局引擎**: `dagre`

### ER 图 (er-diagram)
- **适用场景**: 数据表结构、字段关系、外键依赖
- **D2 模板**: `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/er-diagram.d2`
- **推荐 shapes**: `sql_table`
- **放置位置**: 数据模型章节
- **布局引擎**: `elk`

### 类图 (class-diagram)
- **适用场景**: 面向对象设计、接口继承、组合/聚合关系
- **D2 模板**: `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/class-diagram.d2`
- **推荐 shapes**: `class`（**必须用 class，禁止 rectangle 拼接**）
- **放置位置**: 详细设计章节
- **布局引擎**: `dagre`

### 网络拓扑图 (network-topology)
- **适用场景**: 网络部署、设备连接、集群架构、服务依赖
- **D2 模板**: `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/network-topology.d2`
- **推荐 shapes**: `rectangle`(设备), `cloud`(外部网络), `cylinder`(数据库)
- **放置位置**: 部署章节
- **布局引擎**: `elk`

### 甘特图 (gantt-chart)
- **适用场景**: 项目计划、阶段划分、时间线、里程碑
- **D2 模板**: `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/gantt-chart.d2`
- **推荐 shapes**: `rectangle`(任务条)
- **放置位置**: 实施计划章节
- **布局引擎**: `elk`

## 信息图 vs D2 图表：分工与放置

### 分工原则

|  | D2 图表 | 信息图 |
|--|---------|--------|
| **目的** | 精确展示技术结构/流程/关系 | 概念概览/视觉亮点/快速理解 |
| **详细度** | 高，包含具体节点和连线 | 中，概括性呈现核心概念 |
| **受众** | 技术人员，需要细节 | 所有读者，需要快速建立认知 |
| **编号** | 图 1, 图 2...（正文引用） | 无编号，独立存在 |
| **位置** | 章节正文中（图前有引用） | 醒目位置（开篇/章节首屏） |
| **尺寸** | 适配正文宽度 | 全宽居中，可更大 |

### 信息图放置指南

| 放置位置 | 适用场景 | 内容 |
|---------|---------|------|
| 文档开篇（hero） | 所有文档类型 | 文档核心概念全景，一图看懂文档要讲什么 |
| 章节开篇 | 架构文档/设计文档/知识库 | 该章节涉及模块的能力全景/关系总览 |
| 对比区域 | 设计文档/排障指南 | 方案对比/指标对比矩阵 |
| 结尾总结 | 所有文档类型（可选） | 关键结论/数据亮点摘要 |

### 密度指南（含信息图）

| 文档篇幅 | 推荐信息图数 | 推荐 D2 图数 |
|----------|-------------|-------------|
| < 500 字 | 1 张（hero） | 0-1 张 |
| 500-1500 字 | 1 张（hero） | 1-2 张 |
| 1500-3000 字 | 1-2 张 | 2-4 张 |
| > 3000 字 | 2 张 | 3+ 张 |

## 图号规范

- D2 图编号：图 1、图 2、图 3... 按出现顺序递增
- 信息图**不参与编号**，使用描述性标题
- 正文引用格式：`如图 N 所示，...`
- **D2 SVG 嵌入格式（Obsidian wikilink）**：
  ```markdown
  如图 1 所示，…

  ![[<页面 slug>-arch.svg]]

  *图 1: 标题名称*
  ```
- **信息图 PNG 嵌入格式（Markdown）**：
  ```markdown
  ![文档核心概念全景](_diagrams/<页面 slug>-info.png)

  *文档核心概念全景 — 主题总览*
  ```
- D2 编译首选 SVG（`--theme=300 --dark-theme=200 -l elk`），Obsidian 原生支持亮/暗主题
- **禁止** HTML `<details>` 折叠 SVG；**禁止** `<div align="center">`

## 颜色语义（Material Design）

| 颜色 | 色值 | 语义 |
|------|------|------|
| Orange | `#FF9800` | 核心模块、主要组件 |
| Blue | `#2196F3` | 外部服务、第三方依赖 |
| Green | `#4CAF50` | 数据存储、DB、缓存 |
| Red | `#F44336` | 错误路径、异常、危险操作 |
| Grey | `#9E9E9E` | 辅助组件、已废弃 |
| Purple | `#9C27B0` | 配置、元数据 |
