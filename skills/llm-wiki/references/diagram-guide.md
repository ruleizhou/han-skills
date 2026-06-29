# 图文并茂配图指南（D2）

> **用途**：`ingest`（收录）与 `save`（对话保存）共用的配图内核。在生成/更新页面后，按本指南判断是否配图、配什么图，并用 D2 生成图、嵌入正文，做到图文并茂。
>
> **核心原则**：图是信息的骨架，文是图的展开。**不加说明的图等于没放**——每张图后必须紧跟 2-5 句解释。配图服务于理解，不为配图而配图。
>
> **格式选型**：**默认只生成 SVG**。SVG 可缩放无损、单文件内嵌亮/暗双主题（查看器按系统主题自动切换）、Obsidian/VS Code/GitHub 原生支持、零额外依赖。PNG 光栅化依赖 Playwright/Chromium，环境未安装时会失败——**用 SVG 即可**，仅在需要位图（如嵌 PPT）时才尝试 PNG。

---

## 1. 何时配图（智能判断）

按页面类型 + 内容复杂度判断，**不强制每页都配**：

| 页面类型 | 是否配图 | 说明 |
|---------|---------|------|
| 概念页（concept） | 按复杂度 | 见下方概念复杂度规则 |
| 来源页（source） | 配 1 张 | 反映该来源核心结构/主流程的整体概览图 |
| synthesis（多步分析/综合） | 配 1 张 | 推理链/对比结构适合可视化 |
| decision（架构/策略决策） | 配 1 张 | 决策涉及的架构 + 方案对比 |
| 实体页（entity） | **不配** | 人物/项目/产品等事实信息，配图价值低 |
| 知识卡片（card） | **不配** | 卡片是浓缩提炼，配图冗余 |
| session（整段对话摘要） | **不配** | 多主题异构，无单一可可视化主线 |

**概念页复杂度规则**：
- **简单**（核心要素 ≤3 条、且无模块关系/流程/状态）→ **跳过**
- **中等**（有结构要素）→ 配 **1 张**
- **复杂**（多要素 / 关系网 / 有流程 / 有状态）→ 配 **1-2 张**，**单页不超过 2 张**

> 判断依据：概念是否描述了**结构、流程、状态或交互**？纯定义性概念（"X 是一种…"）无需图；带"X 由 A/B/C 组成""X 经过 步骤1→步骤2""X 有 空闲/忙碌 两态"这类结构的概念才配图。

---

## 2. 配什么图（类型映射）

沿用 `d2-diagram` 的 8 类图表，按页面/内容特征选择：

| 内容特征 | 图表类型 | 布局引擎 | 适用场景 |
|---------|---------|---------|---------|
| 模块/组件/分层/依赖拓扑 | `system-architecture` | `elk` | 概念页·架构组成；来源页·整体概览；decision·架构选型 |
| 步骤/决策/处理流程 | `flowchart` | `dagre` | 概念页·处理流程；synthesis·推理链；来源页·主流程 |
| 状态流转/生命周期 | `state-machine` | `dagre` | 概念页·状态管理 |
| 跨模块交互/调用顺序 | `sequence-diagram` | `dagre` | 概念页·调用序列、协议握手 |
| 数据表结构/字段关系 | `er-diagram` | `elk` | 数据模型（较少用） |
| 接口继承/组合关系 | `class-diagram` | `dagre` | 面向对象设计（较少用） |
| 部署/设备连接 | `network-topology` | `elk` | 部署架构 |
| 计划/阶段/里程碑 | `gantt-chart` | `elk` | 实施计划（较少用） |

**选择优先级**：优先 `system-architecture`（架构）和 `flowchart`（流程），覆盖绝大多数概念/分析场景。只有内容明确是状态机/时序/数据表时才用对应专项图。

**类型短码**（用于文件命名）：`arch` / `flow` / `state` / `seq` / `er` / `class` / `net` / `gantt`

---

## 3. 目录与命名

**每页同目录 `_diagrams/`**——图与页面放在一起，自包含：

```
wiki/concepts/DMA 控制器.md              ← 页面
wiki/concepts/_diagrams/                  ← 该目录下所有概念页的图（共享）
├── DMA 控制器-arch.d2                    ← D2 源
└── DMA 控制器-arch.svg                   ← 正文内联（自动适配亮/暗主题）
```

**命名规则**：`<页面slug>-<类型短码>.{d2,svg}`
- `slug` = 页面文件名去 `.md`（如 `DMA 控制器`）
- 多张图用不同类型短码区分（如 `DMA 控制器-arch.svg` + `DMA 控制器-flow.svg`）

**模式感知**：`_diagrams/` 始终建在页面**实际所在目录**下（随 engineering/generic/lyt/para/zettelkasten 模式而变，由 mode 路由表解析的实际路径决定）。例如 lyt 模式页面在 `wiki/notes/`，图就在 `wiki/notes/_diagrams/`。

---

## 4. 编译命令

**默认只生成 SVG**（一条命令，亮/暗双主题内嵌同一文件）：

```bash
d2 --theme=300 --dark-theme=200 -l <engine> _diagrams/<name>.d2 _diagrams/<name>.svg
```

- `--theme=300`：Terminal 蓝灰色系（亮色），**技术文档统一主题**
- `--dark-theme=200`：暗色主题——d2 把亮/暗两套配色嵌入同一 SVG，查看器按系统主题（`prefers-color-scheme`）自动切换
- `-l <engine>`：`elk`（架构/ER/网络/甘特）或 `dagre`（流程/时序/状态/类），按类型映射表选
- **不加 `--sketch`**（技术文档需正式风格）

**可选 PNG**（仅当需要位图）：`d2 --theme=300 -l <engine> ... .png`。注意 PNG 光栅化依赖 Playwright/Chromium，未安装时会报 `failed to install Playwright` 而失败——此时用 SVG 即可，**不要因 PNG 失败而中断配图流程**。

> 编译须在**页面所在目录**执行（这样 `_diagrams/` 相对路径正确），或在命令里用正确的相对/绝对路径。

---

## 5. 嵌入语法

图嵌入正文相应章节，**SVG 内联 + 图号 + 图后说明**（SVG 自适配主题，无需折叠双版本）：

```markdown
![图 1: DMA 控制器架构](_diagrams/DMA 控制器-arch.svg)

*图 1: DMA 控制器架构*

上图展示了 DMA 控制器的三层结构，关键点：
- 通道控制器负责调度多个传输通道
- ...
```

**规范**：
- 图号按页面内出现顺序递增（图 1、图 2…）
- 正文引用：`如图 1 所示，...`
- 图后必须紧跟 **2-5 句说明**，解释图的关键点（不解释 = 没放）
- 嵌入路径用相对当前页面的 `_diagrams/xxx.svg`

---

## 6. D2 编写规范

1. **读模板作骨架**：若已安装 `d2-diagram` skill，读取其 `assets/templates/<type>.d2` 作为起点；未安装则跳过本步，直接手写 D2（见第 5 点语法）或用第 4 节 SVG 降级
   - 例：`d2-diagram/assets/templates/system-architecture.d2`（路径相对该 skill 根目录）
2. **节点标签用中文，技术术语保留英文**（如 `DMA 控制器`、`scatter-gather`）
3. **连接线标注关键操作/数据**（如 `控制器 -> 内存: 发起传输`）
4. **语义颜色**（Material Design）：

   | 颜色 | 色值 | 语义 |
   |------|------|------|
   | Orange | `#FF9800` | 核心模块、主要组件 |
   | Blue | `#2196F3` | 外部服务、第三方依赖 |
   | Green | `#4CAF50` | 数据存储、DB、缓存 |
   | Red | `#F44336` | 错误路径、异常、危险操作 |
   | Grey | `#9E9E9E` | 辅助组件、已废弃 |
   | Purple | `#9C27B0` | 配置、元数据 |

5. **语法参考**（按需读取，需已安装 `d2-diagram` skill）：`references/d2-shapes-guide.md`、`references/d2-cheatsheet.md`、`references/d2-themes.md`

**编译失败处理**：
- 语法错误 → 对照 `d2-cheatsheet.md` 修正后重试
- 中文显示异常 → 确认系统字体支持中文，必要时英文标签兜底
- 布局重叠 → 尝试换布局引擎（`elk` ↔ `dagre`），或调整 direction
- PNG 的 `failed to install Playwright` → 改用 SVG（见第 4 节），不算失败

---

## 7. d2 未安装时的降级

先检测：`which d2 && d2 --version`

若 `d2` 不可用，**不要中断流程**——把 D2 源作为代码块嵌入文档，并附手动编译提示：

````markdown
> ⚠️ D2 CLI 未安装，下图暂以源码形式呈现。安装 D2 后可编译：
> `d2 --theme=300 --dark-theme=200 -l elk <name>.d2 <name>.svg`

```d2
direction: down
...（D2 源码）...
```
````

---

## 8. 完整最小示例

以概念页 `wiki/concepts/DMA 控制器.md` 为例（描述了控制器→通道→内存的三层结构）：

**判定**：有模块结构 → `system-architecture`，中等复杂度 → 1 张。

**a. 写源码** `wiki/concepts/_diagrams/DMA 控制器-arch.d2`：
```d2
direction: down

controller: DMA 控制器 {
  style.fill: "#FF9800"
  scheduler: 通道调度器
  regs: 寄存器组
}

channels: 传输通道 {
  style.fill: "#2196F3"
  ch0: 通道 0
  ch1: 通道 1
}

memory: 内存 {
  shape: cylinder
  style.fill: "#4CAF50"
}

controller.scheduler -> channels.ch0: 分配
controller.scheduler -> channels.ch1: 分配
channels.ch0 -> memory: scatter-gather
channels.ch1 -> memory: scatter-gather
```

**b. 编译**（在 `wiki/concepts/` 下）：
```bash
d2 --theme=300 --dark-theme=200 -l elk _diagrams/DMA 控制器-arch.d2 _diagrams/DMA 控制器-arch.svg
```

**c. 嵌入正文**（在概念页"核心要素"章节后）：见第 5 节嵌入语法示例。

**d. 验证**：`ls -lh _diagrams/DMA 控制器-arch.svg` 确认非空，即可。
