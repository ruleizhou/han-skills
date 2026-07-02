# 图文并茂配图指南（多引擎）

> **用途**：`ingest`（收录）与 `save`（对话保存）共用的配图内核。在生成/更新页面后，按本指南判断是否配图、配什么图、**用哪个引擎**，并把图嵌入正文，做到图文并茂。
>
> **核心原则**：图是信息的骨架，文是图的展开。**不加说明的图等于没放**——每张图后必须紧跟 2-5 句解释。配图服务于理解，不为配图而配图。
>
> **引擎总览**（两确定性 + 三 AI，共五引擎）：
> - **确定性引擎**（可编辑、自包含、零 API key，**优先**）：`D2`（han-d2-diagram，技术拓扑/流程/状态/时序等结构图）、`han-svg`（对比表/日程/时间线/更易读架构流程）
> - **AI 生成引擎**（高表达力、依赖 han 作用域 key、产物 PNG）：`han-infographic`（高密度信息总览/知识卡）、`han-hand-write-pic`（暖色手绘学习总结）、`han-disassembly-diagram`（物体内部结构/拆解）
> - `han-imagen` 是三个 AI 引擎的生图底座，被自动复用，不在映射表单列
>
> **格式选型**：确定性引擎默认生成 **SVG**（可缩放无损、单文件内嵌亮/暗双主题、Obsidian/VS Code/GitHub 原生支持、零额外依赖、git diff 友好）。AI 引擎产物是 **PNG**（位图、不可编辑、体积大、无亮/暗双主题），仅在高表达力视觉化场景使用。**技术文档默认走确定性引擎出 SVG**。

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

> 配图方式（用哪个引擎、配什么类型）见**第 2 节**。

---

## 2. 配什么图 + 用哪个引擎（核心映射）

### 2.0 决策优先级（铁律）

**能确定性就不用 AI**。逐级判定：

1. 内容是「模块/分层/依赖/流程/状态/时序/ER/类/网络/甘特」结构 → **D2**（自包含、git diff 友好、亮/暗双主题，技术文档首选）
2. 内容是「对比表/日程/时间线/矩阵/分组卡」或要更易读的架构流程 → **han-svg**（确定性、可编辑、纯标准库）
3. 内容是「高密度信息总览/知识卡片图」且确定性引擎表达不够 → **han-infographic**（委托 han-imagen 出 PNG）
4. 内容是「暖色学习总结/手账风知识卡」→ **han-hand-write-pic**
5. 内容是「物体内部结构/爆炸/剖面/拆解」→ **han-disassembly-diagram**
6. AI 引擎无 key / 失败 → **降级到 1 或 2 的确定性引擎**；再不行 → D2 源码块嵌入（见第 7 节，不中断流程）

> 技术 wiki 默认走确定性引擎（1、2）；AI 引擎（3-5）只在内容明确是"高表达力视觉化"或用户明示要某风格时用，且**先查 patterns.json**（第 8 节）。

### 2.1 内容特征 → 引擎 + 类型 映射表

| 内容特征 | 引擎 | 类型/模式 | 布局/产物 | 适用场景 |
|---------|------|----------|----------|---------|
| 模块/组件/分层/依赖拓扑 | **D2** | `system-architecture` | `elk`→`.svg` | 概念页架构；来源概览；架构选型 |
| 步骤/决策/处理流程 | **D2** | `flowchart` | `dagre`→`.svg` | 处理流程；推理链；主流程 |
| 状态流转/生命周期 | **D2** | `state-machine` | `dagre`→`.svg` | 状态管理 |
| 跨模块交互/调用顺序 | **D2** | `sequence-diagram` | `dagre`→`.svg` | 调用序列、协议握手 |
| 数据表结构/字段关系 | **D2** | `er-diagram` | `elk`→`.svg` | 数据模型（较少用） |
| 接口继承/组合关系 | **D2** | `class-diagram` | `dagre`→`.svg` | OO 设计（较少用） |
| 部署/设备连接 | **D2** | `network-topology` | `elk`→`.svg` | 部署架构 |
| 计划/阶段/里程碑 | **D2** | `gantt-chart` | `elk`→`.svg` | 实施计划（较少用） |
| **对比表/日程/周计划/分组卡** | **han-svg** | `matrix` | JSON spec→`.svg` | 对比、选型、日程、矩阵卡 |
| **时间事件/路线图** | **han-svg** | `timeline` | JSON spec→`.svg` | 时间线、发布节奏 |
| **更易读的系统/数据流/分层** | **han-svg** | `architecture` | JSON spec→`.svg` | 系统/服务/数据流（替代 D2 的"易读"场景） |
| 高密度信息总览/知识卡片图/可视化摘要 | **han-infographic** | layout×style | han-imagen→`.png` | 信息密度高、需视觉化总结 |
| 暖色手账/手绘学习总结/sketchnote | **han-hand-write-pic** | hand-drawn-edu × normal/high | han-imagen→`.png` | 学习总结、知识卡 |
| 物体内部结构/爆炸/剖面/产品解剖 | **han-disassembly-diagram** | hybrid/exploded/cutaway | han-imagen→`.png` | 实物拆解科普 |

**选择优先级**：优先 `system-architecture`（架构）和 `flowchart`（流程）覆盖绝大多数概念/分析场景；对比/日程/时间线走 han-svg；只有内容明确是状态机/时序/数据表时才用对应 D2 专项图；只有"高表达力视觉化"才上 AI 引擎。

**类型短码**（用于文件命名）：
- D2：`arch` / `flow` / `state` / `seq` / `er` / `class` / `net` / `gantt`
- han-svg：`svg-matrix` / `svg-timeline` / `svg-arch` / `svg-flow`
- AI 三件套：`info` / `hand` / `disasm`

### 2.2 先查 patterns.json（自学习命中）

配图判断前，读 `data/patterns.json`（第 8 节）：识别页面 `content_type`（标题/正文关键词），找 `keywords` 命中且 `confidence >= 3` 的条目 → **强推荐**其 engine + diagram_type；无命中 → 走第 2.1 映射表默认。

---

## 3. 目录与命名

**每页同目录 `_diagrams/`**——图与页面放在一起，自包含：

```
wiki/concepts/DMA 控制器.md              ← 页面
wiki/concepts/_diagrams/                  ← 该目录下所有概念页的图（共享）
├── DMA 控制器-arch.d2                    ← D2 源
├── DMA 控制器-arch.svg                   ← 正文内联（自动适配亮/暗主题）
├── DMA 控制器-svg-arch.svg               ← han-svg 直出
├── DMA 控制器-info.png                   ← AI 引擎产物（已从 ~/Downloads 搬入）
├── DMA 控制器-info-prompt.md             ← AI 引擎 prompt（配图后保留用于复现）
└── DMA 控制器-svg-matrix-spec.json       ← han-svg spec（保留用于复现）
```

**命名规则**：`<页面slug>-<类型短码>.{d2,svg,png,json,md}`
- `slug` = 页面文件名去 `.md`（如 `DMA 控制器`）
- 多张图用不同类型短码区分（如 `DMA 控制器-arch.svg` + `DMA 控制器-flow.svg`）
- han-svg 的 `spec.json` + AI 引擎的 prompt `.md` 也入 `_diagrams/`，用 `-spec` / `-prompt` 后缀与本页绑定
- **禁止在 vault 根目录创建 `svg/` 临时工作目录**——所有工作文件统一放 `_diagrams/`，避免破坏目录架构

**模式感知**：`_diagrams/` 始终建在页面**实际所在目录**下（随 engineering/generic/lyt/para/zettelkasten 模式而变，由 mode 路由表解析的实际路径决定）。例如 lyt 模式页面在 `wiki/notes/`，图就在 `wiki/notes/_diagrams/`。

---

## 4. 各引擎调用方式

配图前先**一次性检测引擎可用性**：
```bash
which d2 && d2 --version                                    # D2
python3 "${CLAUDE_PLUGIN_ROOT}/skills/han-svg/scripts/main.py" --help   # han-svg（纯标准库，几乎必有）
# AI 引擎：检查 .han-skills/.env 是否有 han 作用域 key（OPENAI/GOOGLE/DATAAI_API_KEY）；无 key 则标记 AI 不可用
```

### 4.1 D2（确定性，出 SVG）

写 `.d2` 源（规范见第 6 节）后编译（在**页面所在目录**执行，使 `_diagrams/` 相对路径正确）：

```bash
d2 --theme=300 --dark-theme=200 -l <engine> _diagrams/<name>.d2 _diagrams/<name>.svg
```

- `--theme=300`：Terminal 蓝灰色系（亮色），**技术文档统一主题**
- `--dark-theme=200`：暗色主题——d2 把亮/暗两套配色嵌入同一 SVG，查看器按系统主题（`prefers-color-scheme`）自动切换
- `-l <engine>`：`elk`（架构/ER/网络/甘特）或 `dagre`（流程/时序/状态/类），按第 2.1 映射表选
- **不加 `--sketch`**（技术文档需正式风格）

> 可选 PNG（仅当需要位图）：`d2 ... .png`。PNG 光栅化依赖 Playwright/Chromium，未安装会失败——用 SVG 即可，**不要因 PNG 失败而中断**。

### 4.2 han-svg（确定性，直出绝对路径到 _diagrams）

先写 `spec.json`（用 `template` 生成起点，再按 `han-svg/references/spec-schema.md` 与类型专属参考填充）。spec 文件直接放 `_diagrams/`，用 `-spec` 后缀：

```bash
# 1. 生成起始 spec，直接写入 _diagrams/
python3 "${CLAUDE_PLUGIN_ROOT}/skills/han-svg/scripts/main.py" template \
  --type matrix --output "<page-dir>/_diagrams/<slug>-svg-<code>-spec.json"
# 2. 编辑 spec.json 填充数据后渲染 —— --svg 给绝对路径，直出 SVG
python3 "${CLAUDE_PLUGIN_ROOT}/skills/han-svg/scripts/main.py" render \
  --spec "<page-dir>/_diagrams/<slug>-svg-<code>-spec.json" \
  --svg "<page-dir>/_diagrams/<slug>-svg-<code>.svg" \
  --theme dark-tech --json
```

- 技术架构用 `dark-tech` 主题；教育/家庭类用 `han-light`
- `architecture` 类型渲染后，按 `han-svg/references/architecture.md` 的折线优化规则手动优化 SVG 边路由（直线→折线、消重叠）
- 纯标准库，无第三方依赖

### 4.3 AI 三件套（委托 workflow + 搬运 PNG 到 _diagrams）

三个 AI 引擎**没有 CLI 入口**（只有 `workflows/`），需**委托**执行其防幻觉两阶段流程，再调 han-imagen 底座出图、搬运产物。**Prompt 文件直接写入 `_diagrams/`，用 `-prompt` 后缀，不额外创建临时目录**：

```bash
# 1. 跑对应 skill 的 workflow（读其 SKILL.md + workflows/）：analysis → structured-content → 套模板生成 prompt 文件
#    prompt 文件直接写入 _diagrams/，首行 # 标题写成 <slug>-<code>（如 DMA 控制器-info），使产物文件名可预测
# 2. 调 han-imagen 底座，--json 拿精确产物路径（不要猜 slug，han-imagen 会给重名加 -2 后缀）
OUT=$(python3 "${CLAUDE_PLUGIN_ROOT}/skills/han-imagen/scripts/main.py" \
  --promptfiles "<page-dir>/_diagrams/<slug>-<code>-prompt.md" \
  --image <slug>-<code>.png --ar 16:9 --quality 2k --json)
SRC=$(echo "$OUT" | python3 -c "import sys,json;print(json.load(sys.stdin)['output_path'])")
# 3. 搬进 wiki 内部 _diagrams/（保持自包含）
cp "$SRC" "<page-dir>/_diagrams/<slug>-<code>.png"
```

- provider 由 han-imagen 自动检测（按可用 key），可 `--provider openai|google|dataeyes` 强制
- 各引擎默认参数：han-infographic（`dense-modules` + `lab-notes` + `landscape`）、han-hand-write-pic（`hand-drawn-edu` + `normal`）、han-disassembly-diagram（`hybrid`）
- **han-disassembly-diagram 铁律**：不确定的内部结构必须标注为「示意图」而非精确工程拆解
- **无 key / 失败 → 降级**到 han-svg 或 D2（见第 7 节），不中断

---

## 5. 嵌入语法

图嵌入正文相应章节，**图号 + 图后说明**（SVG 内联自适配主题；PNG 同语法）：

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
- 嵌入路径用相对当前页面的 `_diagrams/xxx.svg|png`

---

## 6. D2 编写规范

1. **读模板作骨架**：若已安装 `han-d2-diagram` skill，读取其 `assets/templates/<type>.d2` 作为起点；未安装则跳过本步，直接手写 D2 或用第 4.2 节 han-svg 降级
   - 例：`han-d2-diagram/assets/templates/system-architecture.d2`（路径相对该 skill 根目录）
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

5. **语法参考**（按需读取，需已安装 `han-d2-diagram` skill）：`references/d2-shapes-guide.md`、`references/d2-cheatsheet.md`、`references/d2-themes.md`

**编译失败处理**：
- 语法错误 → 对照 `d2-cheatsheet.md` 修正后重试
- 中文显示异常 → 确认系统字体支持中文，必要时英文标签兜底
- 布局重叠 → 尝试换布局引擎（`elk` ↔ `dagre`），或调整 direction
- PNG 的 `failed to install Playwright` → 改用 SVG，不算失败

---

## 7. 降级链（不中断流程）

按引擎可用性与出图结果**逐级降级**：

```
首选引擎（按第 2 节映射）
  ├─ 确定性引擎（D2/han-svg）失败
  │     → 换另一个确定性引擎（D2 ↔ han-svg）
  │     → 仍失败 → D2 源码块嵌入（见下方）
  └─ AI 引擎（info/hand/disasm）无 key 或出图失败
        → 降级到确定性引擎（结构→D2，对比/时间线→han-svg）
        → 仍失败 → D2 源码块嵌入
```

**D2 源码块降级**（最后兜底）：把 D2 源作为代码块嵌入文档，并附手动编译提示：

````markdown
> ⚠️ 图表引擎暂不可用，下图暂以源码形式呈现。安装 D2 后可编译：
> `d2 --theme=300 --dark-theme=200 -l elk <name>.d2 <name>.svg`

```d2
direction: down
...（D2 源码）...
```
````

> **任何降级都要在汇报里注明**："本次 N 张图中 a 张因 <原因> 降级为 <引擎/源码>"，并回写 patterns.json（第 8 节，`outcome: degraded`）。

---

## 8. 自学习闭环（patterns.json）

配图经验沉淀在 `data/patterns.json`（schema 四段：`_schema` / `_confidence_rules` / `_fields` / `patterns`），让配图越用越准。

**读时机**（配图判断前，第 2.2 节）：
- 识别页面 `content_type`（标题/正文关键词）→ 在 `patterns` 找 `keywords` 命中且 `confidence >= 3` 的条目 → 强推荐其 `engine` + `diagram_type`
- 无命中 → 走第 2.1 映射表默认

**写时机**（配图完成后）：
- **成功**：命中已有条目 → `frequency += 1`、`last_seen` 更新（**不自动 +confidence**，避免自吹捧，留给用户反馈）；新组合 → 追加一条 `confidence: 1`
- **降级**（AI 无 key/失败 → 改用确定性）：原 AI 条目 `confidence -= 1`、`outcome: degraded`；降级用的确定性兜底条目 `frequency += 1`
- **彻底失败**（产物为空/嵌入死链）：`outcome: failed`、`confidence -= 1`
- `confidence < 0` → 从 `patterns` 移除

> 哲学对齐 han-infographic「学习自动、反馈延迟」：成功不自动吹 confidence，质量判定留给用户主动反馈（用户说"这版不错"→ `confidence += 1`，列为后续增强）。

---

## 9. 完整最小示例

以概念页 `wiki/concepts/DMA 控制器.md` 为例（描述了控制器→通道→内存的三层结构）：

**判定**：有模块结构 → 按映射表选 **D2** `system-architecture`（结构内容优先确定性引擎），中等复杂度 → 1 张。先查 patterns.json：`技术架构` 命中 `wptrn-001`（confidence 5）→ 强推荐 D2 system-architecture，确认。

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

**d. 验证**：`ls -lh _diagrams/DMA 控制器-arch.svg` 确认非空。

**e. 回写**：patterns.json 中 `wptrn-001` 的 `frequency += 1`、`last_seen` 更新。
