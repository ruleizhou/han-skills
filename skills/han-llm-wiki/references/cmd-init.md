# /han-llm-wiki init —— 初始化

扫描工作区内容，**动态生成**与项目结构对齐的 Wiki 目录骨架。不做预制模板——结构由你通过分析工作区后智能提案，用户确认后创建。

**触发条件：**
- `/han-llm-wiki init` — 扫描工作区，生成 scaffold 提案
- 用户说「初始化 wiki」「创建知识库」「搭建 wiki」等

**核心哲学：** 结构来自内容，不是来自模板。如果你是内核工程师，Wiki 里有 `03-Drivers/DMA.md`；如果你是前端工程师，Wiki 里有 `Components/`, `Hooks/`。永远不要塞给用户一个与工作区无关的固定目录。

---

## 步骤 0：深度工作区扫描

**目标**：理解工作区里有什么，作为生成 scaffold 的依据。扫描越深，提案越准。

### 第 1 层 — 项目类型判断

```bash
ls -1
```

| 检测特征 | 项目类型 |
|---------|---------|
| `arch/` + `drivers/` + `kernel/` + `Makefile` | Linux Kernel |
| `arch/` + `board/` + `Makefile`（无 `kernel/`） | Bootloader / Firmware |
| `device/` + `vendor/` + (`Android.mk` 或 `Android.bp`) | Android BSP |
| `src/` + (`package.json` 或 `Cargo.toml` 或 `CMakeLists.txt`) | 软件项目 |
| 大量 `.md` 文件 + `.obsidian/` | 知识库/笔记 |
| 少量文件或空目录 | 空白起点 |

### 第 2 层 — 子系统扫描（仅 Kernel/Android/Bootloader 项目）

```bash
# 驱动子系统
ls -1 drivers/ 2>/dev/null | head -30

# 内核子系统
ls -1 kernel/ 2>/dev/null && ls -1 fs/ 2>/dev/null && ls -1 net/ 2>/dev/null && ls -1 mm/ 2>/dev/null

# 架构
ls -1 arch/ 2>/dev/null

# SoC 平台（从 defconfig 提取 SoC 代号）
ls -1 arch/*/configs/*defconfig 2>/dev/null | sed 's/.*\/\(.*\)_defconfig/\1/'

# 平台检测
grep -rl "QUALCOMM\|qcom\|CONFIG_ARCH_QCOM" arch/*/configs/ 2>/dev/null | head -3 && echo "QUALCOMM_DETECTED"
grep -rl "MEDIATEK\|mtk\|CONFIG_ARCH_MEDIATEK" arch/*/configs/ 2>/dev/null | head -3 && echo "MEDIATEK_DETECTED"
```

### 第 3 层 — 特殊检测

```bash
# 设备树
ls -1 arch/*/boot/dts/ 2>/dev/null | head -5 && echo "DT_DETECTED"

# 音频
ls -1 sound/ 2>/dev/null | head -5 && echo "SOUND_DETECTED"

# 构建系统细节
ls -1 build/ 2>/dev/null && ls -1 scripts/ 2>/dev/null | head -5
```

### 输出扫描摘要（内部使用，不必全部展示给用户）

```
📊 扫描完成：Linux Kernel 源码 (arm64)
   子系统: sched, locking, irq, mm, fs, net, crypto, security, power
   驱动: usb, gpu, dma, i2c, spi, pci, nvme, display, audio, thermal, gpio, pinctrl, clk, regulator
   平台: Qualcomm
   SoC: kalama, kona, waipio, bengal, monaco
   设备树: 检测到
```

---

## 步骤 A：AI 生成 Scaffold 提案

**这是最关键的一步。** 基于步骤 0 的扫描结果，由你（AI）生成一个**与工作区内容对齐的 Wiki 目录结构提案**。

### 提案生成指南

**所有项目都必须包含 `00-Home/` 作为入口目录**，这是导航起点。

| 检测到 | 生成什么 |
|--------|---------|
| **任何项目** | `00-Home/` + `Home.md`（Wiki 导航入口，链接到所有主要目录） |
| 内核源码 | `01-Architecture/`, `02-Subsystem/`（按实际子系统生成页面）, `03-Drivers/`（按实际驱动类型生成页面） |
| Qualcomm 平台 | `04-Qualcomm-Platform/`，分析 `drivers/clk/qcom/` 等目录生成子页面 |
| SoC defconfigs | `05-SoC-Families/`，每个 SoC 一个页面 |
| 构建系统 | `06-Build-System/` |
| 设备树 | `07-Device-Tree/` |
| 任何项目 | `08-Debug/`, `09-Bringup/`（工程师总有调试和 bringup 需求） |
| 通用笔记 | `10-Notes/`（轻量笔记区） |

### 命名规范

- 目录编号从 `01-` 开始，按逻辑层次排列（架构 → 子系统 → 驱动 → 平台 → SoC → 构建 → DT → 调试 → Bringup → 笔记）
- **编号的作用是排序**，让目录在 Obsidian 文件列表中按逻辑顺序排列
- 页面用英文 kebab-case 命名（与 Wiki 内部中文铁律不同——顶层结构页可以英文，因为反映的是技术术语）
- **总览页文件名用领域名（目录名去掉 `NN-` 前缀），不用 `Overview.md`**：如 `01-Architecture/` → `Architecture.md`、`03-Drivers/` → `Drivers.md`、`00-Home/` → `Home.md`。理由：Obsidian 关系图谱按文件名显示节点，统一用 `Overview.md` 会产生一堆同名节点无法区分；领域名让图谱一目了然。铁律「文件名=title」不变（`Architecture.md` → `title: Architecture`）。

### 提案输出格式

向用户展示结构图 + 简短说明：

```
🗂️ 建议的 Wiki 结构（基于扫描: Linux Kernel arm64 + Qualcomm）

00-Home/                 导航入口
  └── Home.md            Wiki 总导航，链接到所有主要目录
01-Architecture/         内核架构总览
  └── Architecture.md    ARM64 架构概述 + 启动流程
02-Subsystem/            核心子系统
  ├── Memory-Management.md
  ├── Process-Scheduling.md
  ├── Interrupts-IRQ.md
  ├── Locking.md
  ├── Virtual-Filesystem.md
  ├── Networking.md
  └── Power-Management.md
03-Drivers/              驱动框架（检测到 17 个驱动子系统）
  ├── DMA.md
  ├── USB-Gadget.md
  ├── GPU-DRM-KMS.md
  ├── I2C-SPI.md
  ├── PCIe.md
  ├── NVMe.md
  ├── ...

wiki/                    知识管理层（含所有基础设施）
  ├── scripts/           辅助脚本（wiki-lock.sh + wiki-search.py）
  ├── hot.md index.md log.md overview.md
  ├── sources/ concepts/ entities/ analyses/ cards/
  ├── .locks/ .mode.json
  └── .ingest-folders.yaml
  ↑ 注: .search_index.json 在 vault 根目录(wiki_dir),由 wiki-search.py --wiki . 自动维护
```

---

## 步骤 B：用户确认 / 修改

使用 `AskUserQuestion`：

```
question: "是否采纳建议的 Wiki 结构？"
header:  "确认结构"
options:
  1. label: "采纳"
     description: "按建议结构创建全部目录和 Seed 页面"
  2. label: "调整"
     description: "我想增减目录、重命名、或改变组织方式（在 Other 中输入调整要求）"
  3. label: "手动指定"
     description: "我自己描述想要的目录结构（在 Other 中输入）"
```

- **「采纳」**→ 直接进入步骤 C
- **「调整」**→ 根据 Other 中的要求修改提案，重新展示，再次用 AskUserQuestion 确认
- **「手动指定」**→ 根据用户描述生成新结构，展示后确认

---

## 步骤 C：创建目录 + Seed 页面

### C1. 创建目录

按确认后的结构创建所有目录。

### C2. 创建 Seed 页面

Seed 页面分两种：**导航入口**（`00-Home/Home.md`）和**领域总览**（其他目录，文件名用去 `NN-` 前缀的领域名，如 `Architecture.md` / `Drivers.md`，而非统一的 `Overview.md`——见命名规范）。

#### 导航入口：`00-Home/Home.md`

这是整个 wiki 的门户。**不要写成一个简单目录列表**——要像一本技术手册的封面，让任何第一次打开的人 10 秒内明白：这是什么、源码在哪、从哪开始。

**模板**：

```markdown
---
created: YYYY-MM-DD
tags: [moc, home]
---

# {emoji} {项目名称}

> {一句话: 平台/版本/用途}

## 📋 源码位置

- **{描述1}**: `{绝对路径1}`
- **{描述2}**: `{绝对路径2}`

## 🗺️ 导航地图

### {目录1}
- [[01-XXX/具体页面|中文显示名]] — {一句话描述这个主题}

### {目录2}
- [[02-XXX/具体页面|中文显示名]] — {一句话描述}
- ...

## 📝 笔记

- [[10-Notes/Index|笔记索引]] — 按时间或主题整理的工作笔记

## 🔧 工具

- `/han-util-tools` — {工具说明，如果有}
```

**关键要求**：
- **标题必须包含具体项目名 + emoji**：`# 🏠 Qualcomm 5.15 内核知识库`，不是 `# Wiki 导航`
- **子标题有上下文**：`> 基于 Qualcomm Snapdragon MSM 平台的 Android Linux 5.15 内核源码分析`
- **源码路径是必须的**：用户通过 add-dir 加入的路径必须出现在「源码位置」中
- **使用 `[[路径/页面|中文显示名]]` 格式**：不是 `[[目录]]` 或 `[[文件名]]`，而是带描述性别名
- **每个导航链接都有一句话描述**：`[[03-Drivers/GPU|GPU 驱动]] — Adreno DRM`，不是 `- [[03-Drivers]]`
- **按逻辑分组**：架构 → 子系统 → 驱动 → 平台 → SoC → 构建 → DT → 调试 → Bringup → 笔记

#### 领域总览 Seed（其他目录）

对每个非 00-Home 目录下的 `.md` 文件：

```markdown
---
title: <页面标题>
type: concept
tags: [<相关标签>]
created: YYYY-MM-DD
status: seed
---

# <页面标题>

> 检测自 <源码路径> — <一句话说明为什么创建这个页面>

## 概述

（ingest 相关源码/文档后自动填充）

## 核心概念

（ingest 后提取）
```

**通用原则**：
- Seed 页面的 `status: seed` 标记表示"骨架，待填充"——lint 时跳过此类页面的"内容过短"警告
- Seed 页面的标题和 tags 应该反映该领域的核心术语
- 不要编造内容！只写从目录名/文件名能合理推断的一行概述
- 对于没有明确子页面的目录（如 `10-Notes/`），可以不创建 seed 页面，或只创建 `Index.md`

### C3. 创建领域模板（可选）

如果检测到特定项目类型，创建一个 `templates/` 目录并放入 1-3 个针对性模板：

| 项目类型 | 建议模板 |
|---------|---------|
| Linux Kernel | `driver-analysis-template.md`（驱动分析模板） |
| Android BSP | `bringup-checklist-template.md`（Bringup 清单模板） |
| 软件项目 | `component-review-template.md`（组件评审模板） |
| 知识库 | `note-template.md`（通用笔记模板） |

模板只需一个——用户可以根据需要复制修改。不要像旧版那样强制复制 7 个。

> **lint 说明**：`templates/` 下的模板用描述性 `title`（如 `title: 驱动开发模板`），与文件名不必一致——`wiki-lint.py` 的 `NAME_SKIP_DIRS` 会自动豁免 `templates/` 目录的 P0-2 命名一致性检查（死链扫描仍覆盖，故模板里的真实 `[[链接]]` 照常校验）。

---

## 步骤 D：基础设施文件

以下文件在所有项目中通用，在 `wiki/` 下创建：

1. **`wiki/hot.md`**（会话热缓存）：
```markdown
---
last_updated: YYYY-MM-DD
session_count: 0
---

## 最近活跃主题
（ingest/query 操作后自动填充）

## 未完成任务

## 最近查询热点

## 关注矛盾
```

2. **`wiki/index.md`**（内容索引，按项目结构生成分类标题）
3. **`wiki/log.md`**（操作日志，带标题）
4. **`wiki/overview.md`**（总览，状态统计初始为 0）
5. **`wiki/.mode.json`**：
```json
{"schema_version": 1, "mode": "engineering", "configured_at": "ISO-8601"}
```
6. **`wiki/.ingest-folders.yaml`**（格式见 cmd-ingest.md）
   - 💡 若用户已通过 `/add-dir` 明确加入源码目录（如内核源码），可预注册该目录（`last_ingest: null`），便于后续无参数 `/han-llm-wiki ingest` 直接收录
   - ⚠️ 创建前检查项目根目录是否有旧版 `.ingest-folders.yaml`（v2 遗留）
   - 若根目录存在旧注册文件且 `wiki/` 下不存在 → **迁移**：读取旧文件的 `folders`，按新格式（增加 `path` 字段）写入 `wiki/.ingest-folders.yaml`，迁移后不移除旧文件（用户手动处理）
   - 若 `wiki/` 下已存在 → 不覆盖（幂等）
7. **`.raw/`**（vault 根目录，与 `00-Home/` 同级）— 原始文档收件箱
   - 创建 `.raw/` 目录，用于放置待收录的原始文档（网页导出、笔记草稿等）
   - 自动将 `.raw/` 注册到 `wiki/.ingest-folders.yaml`（`last_ingest: null`），便于后续无参数 `/han-llm-wiki ingest` 直接收录
   - 若 `.raw/` 和注册条目均已存在 → 跳过（幂等）

   > **注意**：`.raw/` 已被注册到 `.ingest-folders.yaml`，后续运行无参数 `/han-llm-wiki ingest` 时会自动收录其中的新文档到 `wiki/sources/`。已在 wiki 目录中的文件自动算作已收录。

8. **`wiki/scripts/wiki-lock.sh`** — 从 skill 自带脚本复制（位于 skill 根目录的 `scripts/wiki-lock.sh`）：
   `cp <skill-dir>/scripts/wiki-lock.sh wiki/scripts/`
9. **`wiki/scripts/wiki-search.py`** — 同上（`<skill-dir>/scripts/wiki-search.py`，纯 Python stdlib，零依赖）
   > skill 目录 = 加载本 SKILL.md 的目录（含 `references/`、`scripts/`、`SKILL.md`）。若 `.claude/skills/han-llm-wiki` 是软链接，用 `realpath` 解析确认真实路径后再 `cp`，避免软链导致 `cp: cannot stat`。
10. **`wiki/scripts/wiki-lint.py`** — 同上（`<skill-dir>/scripts/wiki-lint.py`，纯 stdlib）；P0 链接自检脚本（死链 + 文件名=title 一致性），init/ingest/lint 收尾复用，取代手写 grep。

> **注意**：scripts 等基础设施放在 `wiki/` 下，不污染项目顶层。唯一例外是 `.search_index.json`——由 `wiki-search.py` 写入 `--wiki` 指定目录(即 vault 根，`--wiki .`)，与 `00-Home/`~`10-Notes/` 同级；它是隐藏文件，Obsidian 默认不显示。用户的 Obsidian 文件浏览器主要看到 `00-Home/` ~ `10-Notes/` 和 `wiki/` 目录。

11. **`AGENTS.md`**（vault 根目录，与 `00-Home/` 同级）—— 跨工具通用维护约定（Claude Code / Cursor / Copilot 均识别）。schema-guide.md 是其配置指南，init 时应一并创建。必含：
   - wiki 基本信息 + **只读源码路径**（用户通过 `/add-dir` 加入的路径必须列出并标注「只读,绝不修改」）
   - 目录结构说明
   - **检索约定**：`python3 wiki/scripts/wiki-search.py search "关键词" --wiki .`
   - 页面命名 / 收录约定
   > 详见 `references/schema-guide.md`，模板见该文件末尾。

---

## 步骤 E：验证（收尾自检，不可跳过）

init 创建了大量带 `[[交叉链接]]` 的页面，收尾必须验证链接网络与检索索引：

1. **建检索索引**：`python3 wiki/scripts/wiki-search.py index --wiki .`
2. **链接自检**：`python3 wiki/scripts/wiki-lint.py check --wiki .`
   - 输出 `0 死链` + `0 命名不一致`（退出码 0）→ 通过
   - 有死链 → 立即修复（创建缺失页 或 修正链接名），重跑直到退出码 0
3. wiki-lint 自动跳过反引号 / 代码块内的 `[[ ]]`，配置文档（如 AGENTS.md）的示例 wikilink 不会被误判为死链。

---

## 幂等性

如果目录已部分存在，只补建缺失部分：
- 目录缺失 → 创建
- Seed 页面缺失 → 创建（不覆盖已有页面！用户可能已经填充了内容）
- `templates/` 已存在 → 不覆盖（用户可能已自定义模板）
- 基础设施文件缺失 → 创建（不覆盖已有，特别是 hot.md/index.md/log.md 可能已有内容）
- `wiki/.mode.json` 已存在 → 不覆盖
- `.raw/` 已存在 → 不覆盖，注册条目已存在则跳过

重复执行 init 也应跑一遍 **步骤 E**（只验证不重建已有内容）：建索引 + 链接自检，确保补建/遗漏的页面没有引入死链。
