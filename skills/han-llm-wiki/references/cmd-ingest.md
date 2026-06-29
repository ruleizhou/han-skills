# /han-llm-wiki ingest —— 收录

分析指定收录源目录（或已注册的所有目录）中的文档，提炼实体和概念，整合到 wiki 中。这是最核心的操作。

**触发条件：**
- 用户显式执行 `/han-llm-wiki ingest`
- 用户说「收录」「整理到 wiki」「加入知识库」等

**参数：**
- `/han-llm-wiki ingest <文件夹名>` — 收录指定目录下的未收录文档（支持 `note/<子目录>/`、绝对路径、或相对路径）
  - 示例：`/han-llm-wiki ingest 03-Drivers` → 收录 `03-Drivers/` 下的文档
  - 示例：`/han-llm-wiki ingest 02-Subsystem` → 收录 `02-Subsystem/` 下的文档
- `/han-llm-wiki ingest` — 无参数时，增量收录所有已注册文件夹（记忆功能）
  - 1 个文件夹 → 串行交互模式（逐步讨论，即时反馈）
  - ≥2 个文件夹 → **批量并行模式**（多 agent 并行提取 + 串行汇总，跳过逐个讨论，最后统一汇报）
- `/han-llm-wiki ingest all` — 显式批量所有已注册文件夹（同 ≥2）
- `/han-llm-wiki ingest 批量` — 同 `ingest all`
- 用户说「同步 seed 页面」「回填入口页面」「填充 Seed 页」→ 跳过 Step 0-4，直接执行 Step 4.5（同步已有实体/概念页到 Seed 页面，替换占位符）
  - 已注册文件夹列表存储在 `wiki/.ingest-folders.yaml`

**收录对象：** 由参数决定。用户可以指定具体文件，也可以不指定（由你扫描目标目录下未被收录的文档）。

**如何判断文档是否已收录：** 检查 `wiki/sources/` 下是否已有对应的来源摘要页。来源摘要页的 `raw_path` 字段指向 note 中的原始文件。如果来源摘要页不存在，说明该文档尚未被收录。如果来源摘要页存在但 `ingest_status` 为 `paused`，说明上次收录未完成，可断点续传。

---

## 预处理：热缓存 & 僵尸锁清理

在进入正式流程之前：

1. **读取 `wiki/hot.md`**（不存在则跳过）——了解最近活跃主题和未完成任务，辅助本次收录的重点判断
2. **清理僵尸锁**——执行 `bash wiki/scripts/wiki-lock.sh stale`，清除超过 10 分钟的残留锁文件

---

## 断点续传检查

在扫描未收录文档之前，先检查 `wiki/sources/` 下是否有 `ingest_status` 为 `paused` 的页面。

如有，向用户报告：

```
发现上次未完成的收录：
- [[来源A]] — 进度 4/10（停在第 4 步：更新实体和概念）
- [[来源B]] — 进度 7/10（停在第 7 步：追加日志）

是否要从中断处继续？还是重新开始？
```

- **用户选择继续** → 对每个 paused 的来源，从 `ingest_progress` 记录的下一步开始执行（跳过已完成的步骤）
- **用户选择重新开始** → 忽略旧进度，对 paused 来源从头开始

**断点续传的幂等性保证：**
- 步骤 4（更新实体/概念）：整合操作天然幂等，重复执行不会丢失数据
- 步骤 4.5（同步 Seed 页）：以占位符 `自动填充` 发现 Seed 页（不依赖 `status: seed` 字段），已更新为 `status: active` 的页面不会回退，重复执行只更新 `updated` 日期
- 步骤 4.6（生成图表）：重新生成并覆盖已有图文件，无副作用；已嵌入的图引用保持有效
- 步骤 5-7（overview/index/log）：重新执行时会覆盖/追加，结果正确
- 步骤 8-9（链接检查/卡片）：重新执行无副作用

---

## 模式感知（v3+）

在处理任何页面创建之前，**先读取 `wiki/.mode.json`** 获取当前模式（不存在则默认 `engineering`）。

根据模式决定步骤 3（来源页）和步骤 4（概念/实体页）的归档路径。参见 `references/cmd-mode.md` 的路由表：

| 步骤 | engineering | generic | lyt | para | zettelkasten |
|------|-----------|---------|-----|------|-------------|
| 3 — 来源页 | `wiki/sources/` | `wiki/sources/` | `wiki/notes/` | `wiki/resources/<topic>/` | `wiki/<ID>-<slug>.md` |
| 4 — 概念页 | `wiki/concepts/` | `wiki/concepts/` | `wiki/notes/` | `wiki/resources/concepts/` | `wiki/<ID>-<slug>.md` |
| 4 — 实体页 | `wiki/entities/` | `wiki/entities/` | `wiki/notes/` | `wiki/resources/people/` | `wiki/<ID>-<slug>.md` |

**zettelkasten 模式**的 ID 生成：`YYYYMMDDHHMMSSffffff`（当前时间，20 位微秒精度，防碰撞）。页面命名：`<ID>-<slug>.md`（如 `20260613153045123456-dma-driver.md`）。

**lyt 模式**：新建概念/实体页面后，额外更新相关 MOC 页面。在 `wiki/mocs/` 下找到或创建对应主题的 MOC，添加新页面的链接。

**Step 4.5（同步 Seed 页）不受模式影响**——Seed 页面位于 vault 根目录（如 `03-Drivers/Clock.md`），是所有模式的共有入口层。无论当前是哪种模式，步骤 4.5 的匹配和更新逻辑一致。

**Step 4.6（图表生成）的模式感知**：`_diagrams/` 目录建在页面**实际所在目录**下（按上方路由表）。例如 engineering 模式概念页在 `wiki/concepts/`，图就在 `wiki/concepts/_diagrams/`；lyt 模式页面在 `wiki/notes/`，图就在 `wiki/notes/_diagrams/`。

---

## 完整流程（10 步）

**第 0 步：参数解析与文件夹注册**

1. 判断用户是否提供了文件夹名参数
2. **有参数时：**
   - 参数可能是：a) `note/` 子目录名 b) 绝对路径 c) 相对路径。确认目标目录存在；不存在则提示用户
   - 读取（不存在则创建）`wiki/.ingest-folders.yaml`
   - 检查该文件夹是否已在注册表中。未注册则追加一条记录（`added` 设为当天，`last_ingest` 设为 `null`）
   - 将该目录设为 `{target_dir}`，继续第 1 步
3. **无参数时：**
   - 读取 `wiki/.ingest-folders.yaml`
   - 文件不存在或 `folders` 为空 → **进入自动发现流程**：
     1. 扫描 vault 根目录下除 `00-Home/`~`90-Notes/`、`wiki/`、`.raw/`、`.claude/`、`assets/`、`Temp/` 外的所有一级目录，标记为候选收录源
     2. 扫描已通过 `/add-dir` 添加到工作区的额外目录（如 Claude Code 环境中的 working directories），标记为候选
     3. 扫描 vault 根目录下的 `.raw/`（如果存在且尚未注册）
     4. 向用户展示候选目录列表，询问是否注册并收录：
        ```
        未注册任何收录目录。发现以下候选：
        - /path/to/xxx/（因含 .md 文件被检测到）
        - /path/to/yyy/（因是工作区目录被检测到）
        - .raw/（原始文档收件箱）
        是否注册并收录这些目录？
        ```
     5. 用户确认后 → 追加到 `.ingest-folders.yaml`（`last_ingest: null`），进入对应模式
     6. 用户拒绝或无可选目录 → 提示 "请先执行 `/han-llm-wiki ingest <文件夹路径>` 手动指定"
   - 有已注册文件夹 → 判断文件夹数量：只有 1 个 → 串行交互模式（执行第 1-9 步，逐步讨论）；≥2 个 → **批量并行模式**（跳转到末尾「批量并行模式」章节）
   - 对每个已处理文件夹，更新其 `last_ingest` 为当天日期

**`.ingest-folders.yaml` 格式：**
```yaml
# Ingest 文件夹注册表
# 记录用户曾经收录过的目录（支持项目内 note/ 子目录和外部绝对路径）
# 无参数执行 /han-llm-wiki ingest 时，会对所有已注册文件夹进行增量收录
folders:
  - name: kernel_platform
    path: /home/user/study/kernel/kernel_platform/
    description: Qualcomm MSM Kernel Platform 源码
    added: 2026-06-13
    last_ingest: 2026-06-13
  - name: 10-Domains
    path: note/10-Domains/
    description: 领域知识笔记
    added: 2026-05-27
    last_ingest: null
```

`path` 为必填字段 —— 可以是 `note/<name>/`（项目内笔记目录）或绝对路径（外部源码/文档目录）。`name` 作为显示短名，`description` 用于向用户展示目录用途。

**第 1 步：读取来源**
- 找到用户指定的文档（在 `{target_dir}` 下）
- 认真通读，理解核心内容
- 如果文档中有图片，单独查看获取额外上下文

**第 2 步：与用户讨论**
分享关键发现，格式如：

```
我刚读完《XXX》，有几个关键发现：
1. 核心观点：...
2. 与 wiki 中已有信息的关系：支持了 / ⚠️ 矛盾于 [[某页面]]
3. 建议创建的新页面：...
4. 建议更新的页面：...
你觉得重点放在哪些方面？
```

等用户确认方向后再开始写页面。

**第 3 步：创建来源摘要页**
- 在 `wiki/sources/` 下创建
- 使用 `references/page-templates.md` 中的来源模板
- 包含：摘要、核心观点、提取的实体和概念、指向原始文件的链接
- 来源摘要页的 `raw_path` 指向 `{target_dir}/...` 下的原始文件
- **设置初始进度**：`ingest_status: paused`、`ingest_progress: 0/10`
- **完成本步后**：更新 `ingest_progress: 3/10`

**第 4 步：更新实体和概念页面**
对文档中提到的每个重要实体/概念：
- 页面已存在 → 用新信息**整合**（不是追加），注明来源，更新 `updated` 日期
- 页面不存在 → 用对应模板创建新页面，建立 `[[双向链接]]`
- 标记与其他实体的关系
- **完成本步后**：更新 source 页面的 `ingest_progress: 4/10`

**验证门（Step 4 必须执行）：**
- 用 `grep` 检查本次新建/更新的每个实体页和概念页的 frontmatter，确认以下字段都存在：
  - `title` — 必须与文件名一致
  - `type` — 必须为 `entity` 或 `concept`
  - `created` — 必须为日期格式 `YYYY-MM-DD`
  - `updated` — 必须为日期格式 `YYYY-MM-DD`
- 发现缺失字段 → 立即补充后重验
- 检查 `sources` 字段中的 `[[链接]]` 目标文件是否存在（即来源页是否已创建）
- 每缺少一个必填字段，计入本次收录的一个待修复项
- **目的**：防止 agent 创建不完整的实体/概念页，避免类似 DisplayDxe 缺 title/created/updated 的问题再次发生

**⚠️ 第 4.5 步：同步 Seed 页面（不可跳过！—— 打通 init ↔ ingest 断层）**

> **这是 ingest 的关键步骤，不可跳过！** 若跳过，vault 根目录的 Seed 入口页面将永久保留「（ingest 相关源码/文档后自动填充）」占位符，整个知识库入口层无实质内容。批量并行模式的串行汇总阶段也必须包含本步。

创建/更新实体和概念页后，用占位符文本 `自动填充` 发现需要同步的 Seed 页面，将其填充为真实内容。

**匹配规则（文件名关键词匹配，不依赖 tags）：**

| 优先级 | 匹配方式 | 示例 |
|--------|---------|------|
| 1 | Seed 文件名关键词是实体页文件名的子串 → 明确命中 | `Clock.md` → `ClockDxe.md`（`Clock` ⊆ `ClockDxe`），`Display.md` → `DisplayDxe.md` |
| 2 | 目录语义 + 文件名关键词关联 → 候选命中 | `Storage.md` → `UFSDxe.md`（Storage 语义对应 UFS 存储驱动） |

> 不再使用 tags 匹配：Seed 页用英文 tags（`clock`, `driver`），实体页用中文 tags（`时钟`, `驱动`），直接交集匹配实际无效。

**实际操作：**
1. 扫描 vault 根目录下所有含占位符的 Seed 页面：`grep -rl "自动填充" <vault-root>/0*-*/`
   - 使用占位符文本 `（ingest 相关源码/文档后自动填充）` 作为发现锚点，不依赖 `status: seed` 字段
   - 原因：部分 init 创建的 Seed 页缺少 `status: seed` 字段，grep seed 会遗漏它们
2. 对每个 Seed 页面，提取其**文件名**（不含扩展名，如 `Clock`）和**所在目录名**（如 `03-Drivers`）
3. 用文件名关键词去匹配本次新建/更新的实体和概念页的**文件名**：
   - **完全包含（优先级 1）**：Seed 文件名关键词是实体页文件名的子串（如 `Clock` ⊆ `ClockDxe`，`Display` ⊆ `DisplayDxe`，`PIL` ⊆ `PILDxe`）→ 明确命中
   - **语义关联（优先级 2）**：Seed 文件名关键词的语义对应实体页功能（如 `Storage` → `UFSDxe`、`Charger` → `PmicDxe`）→ 候选命中，需结合目录确认
4. **命中后更新 Seed 页面**：
   ```yaml
   ---
   # 保留原有 frontmatter，但更新：
   status: active          # seed → active
   updated: YYYY-MM-DD
   see_also: [[wiki/entities/ClockDxe]]  # 新增：指向详细实体页
   ---
   
   # 保留原标题
   
   > 原有一句话描述（保留）
   
   ## 概述
   
   （基于实体/概念页内容写 2-4 句精炼概述，指向详细页）
   
   ## 核心要点
   
   - 要点一
   - 要点二
   - 要点三
   
   ## 详细信息
   
   > 详细分析请见 [[wiki/entities/ClockDxe]]
   
   ## 关联页面
   
   - [[wiki/entities/相关实体]]
   - [[wiki/concepts/相关概念]]
   ```
5. **无匹配**：不做任何修改，Seed 页保持原样等待后续 ingest
6. **多对一**：多个实体页对应一个 Seed 页（如 `UFSDxe`+`SdccDxe`+`PartitionDxe` 都对应 `03-Drivers/Storage.md`），合并概述并从各详细页引用

**验证门（必须执行）：**
- 执行本步后，重新运行 `grep -rl "自动填充" <vault-root>/0*-*/`，确认输出中**不再包含本次匹配到的 Seed 页**
- 如果本次匹配到的 Seed 页仍含 `自动填充`，说明更新未生效 → 检查更新逻辑后重试
- 将验证结果汇报给用户：「同步了 N 个 Seed 页面：[[页面1]], [[页面2]], ...」

> **目的**：保证 `03-Drivers/Clock.md` 这样的顶层入口页有基本内容可读，同时引导读者到 `wiki/entities/ClockDxe.md` 获取更详细的技术分析。打通 init 创建的 Seed 页面和 ingest 创建的深度页面之间的断层。
> **完成本步后**：更新 source 页面的 `ingest_progress: 4.5/10`

**第 4.6 步：为内容页生成图表（多引擎图文并茂）**

在所有内容页创建/更新完成后，为适合可视化的页面配图，做到图文并茂。按内容智能选引擎（D2 / han-svg / han-infographic / han-hand-write-pic / han-disassembly-diagram），详细规则见 `references/diagram-guide.md`。

**配图范围**：本次新建/更新的**概念页 + 来源页**（实体页、知识卡片**不配图**）。

**流程**：
1. 一次性检测引擎可用性：`which d2 && d2 --version`、`python3 "${CLAUDE_PLUGIN_ROOT}/skills/han-svg/scripts/main.py" --help`、检查 `.han-skills/.env` 是否有 han 作用域 key（无 key 标记 AI 引擎不可用）
2. 对每个候选页面，按 `references/diagram-guide.md` 决定：是否配图、配几张、**用哪个引擎 + 什么类型**
   - 先查 `data/patterns.json`（diagram-guide.md 第 8 节）命中经验（content_type 关键词 + confidence≥3 强推荐）
   - 无命中走第 2 节映射表：结构（架构/流程/状态/时序/ER/类/网络/甘特）→ **D2**；对比/日程/时间线/易读架构 → **han-svg**；高密度总览 → **han-infographic**；暖色总结 → **han-hand-write-pic**；物体拆解 → **han-disassembly-diagram**
   - AI 引擎选中但无 key → 降级到 D2/han-svg（见 diagram-guide.md 第 7 节）
   - 简单概念（纯定义、无结构）→ 跳过；来源页 → 1 张整体概览图
3. 对每个待配图页面（按引擎执行，命令见 diagram-guide.md 第 4 节）：
   - 在页面**同目录**建 `_diagrams/`（如 `wiki/concepts/_diagrams/`，路径随 mode 路由表）
   - **D2**：读 `han-d2-diagram/assets/templates/<type>.d2` 作骨架，写 `<页面slug>-<短码>.d2` → 编译 SVG
   - **han-svg**：写 spec.json → `render --svg <绝对路径>_diagrams/<slug>-svg-<code>.svg`（直出，无需 --download）
   - **AI 三件套**：跑对应 skill 的 workflow 生成 prompt → 调 `han-imagen --json` 拿 output_path → `cp` 到 `_diagrams/<slug>-<code>.png`
   - 在正文相应章节嵌入：`![图 N: 标题](_diagrams/xxx.svg|.png)` + 图号 + **图后 2-5 句说明**
4. **验证门（必须执行）**：对每张图 `ls -lh _diagrams/<name>` 确认文件存在且非空；确认嵌入的相对路径正确（指向页面同目录的 `_diagrams/`）
5. **自学习回写**：配图成功后回写 `data/patterns.json`（命中条目 frequency+1，新组合追加 confidence=1；降级记 outcome=degraded）
6. **完成本步后**：更新 source 页面的 `ingest_progress: 4.6/10`
7. 收录结束汇报："为 N 个概念页/来源页配了 M 张图：D2 x / han-svg y / info z / hand w / disasm v（其中 a 张因无 key 降级为 D2/han-svg）"（或"本次无适合配图的页面"）

**第 5 步：更新 overview.md**
只有以下情况才更新：
- 新的主题维度出现
- 核心论点发生变化
- 重要矛盾被发现
- 状态统计需要更新

> **文件锁**：写 overview.md 前执行 `bash wiki/scripts/wiki-lock.sh lock wiki/overview.md`，写完后执行 `bash wiki/scripts/wiki-lock.sh unlock wiki/overview.md`

- **完成本步后**：更新 source 页面的 `ingest_progress: 5/10`

**第 6 步：更新 index.md**
按类别添加所有新建和更新的页面条目。

> **文件锁**：写 index.md 前执行 `bash wiki/scripts/wiki-lock.sh lock wiki/index.md`，写完后执行 `bash wiki/scripts/wiki-lock.sh unlock wiki/index.md`

- **完成本步后**：更新 source 页面的 `ingest_progress: 6/10`

**第 7 步：追加 log.md**
```markdown
## [YYYY-MM-DD] 收录 | 来源标题

- 新建页面：页面A、页面B...
- 更新页面：页面C、页面D...
- 关键发现：一句话总结
- 发现矛盾：如有
```

> **文件锁**：写 log.md 前执行 `bash wiki/scripts/wiki-lock.sh lock wiki/log.md`，写完后执行 `bash wiki/scripts/wiki-lock.sh unlock wiki/log.md`

- **完成本步后**：更新 source 页面的 `ingest_progress: 7/10`

**第 8 步：链接自检（必须执行）**
逐一检查本次新建/更新的所有页面中的 `[[链接]]`，确认每个链接目标文件确实存在。
发现死链立即修复：创建缺失页面或修正链接名。
这是收录流程的最后一步，**不可跳过**。
（无参数批量收录时，所有文件夹处理完毕后统一执行一次自检。）
- **完成本步后**：更新 source 页面的 `ingest_progress: 8/10`

**第 9 步：生成/更新知识卡片**
收录过程中每个新建的概念页面，都应该提炼为一张知识卡片。卡片是概念页面精华的浓缩版，方便后续抽卡复习。
- 读取 `wiki/cards/` 下已有的卡片，检查本次涉及的概念是否已有对应卡片
- **已有卡片**→ 将新信息整合进现有卡片，补充或修正核心要点，增加新的测验题
- **没有卡片**→ 为每个重要概念新建一张卡片
- 卡片的 `concept` 字段链接回对应的 wiki 概念页面
- 不要为实体、来源、分析页面建卡片——卡片只针对**概念**
- **卡片文件名与概念页同名**（不加「卡片」后缀），靠 `cards/` 目录区分。如概念叫 `Bear.md`，卡片也叫 `Bear.md` 放在 `cards/` 下
- **完成本步后**：更新 source 页面的 `ingest_status: completed`、`ingest_progress: 9/10`

**第 10 步：更新检索索引**

- 执行 `python3 wiki/scripts/wiki-search.py index --wiki .` 更新 BM25 搜索索引
- 索引采用增量更新（按 mtime 判断），只重算变化的页面，成本极低
- **验证门（自动 lint）**：执行 `python3 wiki/scripts/wiki-lint.py check --wiki .`，确认：
  - 死链 = 0（防止新建内容引入死链接）
  - frontmatter 完整性问题 = 0（防止缺失 title/type/created/updated）
- 如果 lint 检测到 P0 问题 → 列出问题并询问「是否先修复再继续？」用户确认后执行 `python3 wiki/scripts/wiki-lint.py fix --wiki .`
- **完成本步后**：更新 source 页面的 `ingest_progress: 10/10`

---

## 后处理：更新热缓存

全部收录完成后，更新 `wiki/hot.md`（不存在则跳过）：

1. **刷新「最近活跃主题」**：将本次涉及的核心页面（概念、实体）加入，去重保留最近 5 条
2. **追加「未完成任务」**：如本次发现需后续处理的条目（矛盾待确认、建议新建页面等）
3. **更新「关注矛盾」**：如本次发现新的矛盾信息
4. `session_count` +1
5. **总长度控制** ≤ 500 词（约 30 行），超出时裁剪最旧的条目

---

**一次收录可能影响 10-15 个 wiki 页面。这很正常。**

**收录原则：**
- 主动标记**矛盾**——新信息是否与 wiki 中已有信息冲突？明确标注 `⚠️`
- 主动建立**链接**——新内容与已有页面之间的关联都要体现
- 优先考虑用户关注的重点，不罗列所有细节

---

## 批量并行模式

当无参数 ingest 且 ≥2 个已注册文件夹时，自动进入批量并行模式。目标：利用多 sub-agent 并行提取 source 页面，大幅缩短多文件夹 ingest 的时间。

### 并行架构

| 阶段 | 执行方式 | 步骤 | 文件范围 |
|------|---------|------|----------|
| **并行提取** | 每 folder 一个 sub-agent（`Agent` tool） | 1-3（读、自动提取要点、写 source 页面） | `wiki/sources/<x>.md`（独立文件，无冲突） |
| **串行汇总** | 主 agent 加锁执行 | 4-10（实体/概念/同步 Seed/overview/index/log/链接/卡片/索引） | 共享文件 + vault 根目录 Seed 页 |

### 并行提取阶段（每个 sub-agent 独立执行）

对每个已注册文件夹启动一个 sub-agent：
```
Agent("处理 {folder_name} 的文档，读取 {folder_name}（通过 .ingest-folders.yaml 的 path 字段解析）下的未收录文档，
      执行第 1-3 步：理解内容 → 创建 wiki/sources/ 来源摘要页
      （ingest_status: paused, ingest_progress: 3/10）。
      返回：已处理的文档列表 + 建议新建/更新的实体和概念清单（JSON）")
```

**sub-agent 职责**：
- 扫描文件夹下未被收录的文档（检查 source 页面的 raw_path）
- 认真阅读每个文档，提取核心观点
- 为每个文档创建 source 摘要页面（带 frontmatter + ingest 进度）
- 返回结构化清单：
  ```json
  {
    "folder": "10-Domains",
    "new_sources": ["[[source A]]", "[[source B]]"],
    "suggested_new_entities": [{"name": "实体名", "type": "entity"}],
    "suggested_new_concepts": [{"name": "概念名", "type": "concept"}],
    "suggested_updates": [{"page": "[[现有页面X]]", "reason": "新信息关于..."}],
    "key_findings": ["关键发现1", "关键发现2"],
    "contradictions": ["⚠️ 矛盾描述"]
  }
  ```

**并行触发**：在同一轮中发送多个 `Agent` 调用（并行），每个处理不同 folder。

### 串行汇总阶段（主 agent 统一执行）

收集所有 sub-agent 返回的清单后，主 agent 按以下顺序加锁串行执行：

1. **步骤 4 — 更新实体/概念**：合并所有建议，逐一更新或创建。去重：多个 folder 建议同一概念 → 只更新一次，整合所有视角
2. **步骤 4.5 — 同步 Seed 页面（不可跳过）**：将新实体/概念回填到 vault 根目录的同主题 Seed 页面
   - 使用 `grep -rl "自动填充" <vault-root>/0*-*/` 发现所有含占位符的 Seed 页
   - 以文件名关键词匹配（非 tags），优先级 1 完全包含 + 优先级 2 语义关联
   - 执行后运行验证门：`grep -rl "自动填充" <vault-root>/0*-*/` 确认匹配到的 Seed 页不再含占位符
3. **步骤 4.6 — 为内容页生成图表（多引擎图文并茂）**：按 `references/diagram-guide.md` 智能选引擎为本次新建/更新的概念页 + 来源页配图（实体页/卡片不配）。因要写 `_diagrams/` 文件并修改多个页面，**必须在主 agent 串行执行**（不下放给并行 sub-agent）
4. **步骤 5 — 更新 overview.md**：加锁
5. **步骤 6 — 更新 index.md**：加锁，统一添加所有新建/更新条目
6. **步骤 7 — 追加 log.md**：加锁，汇总所有 folder 的操作
7. **步骤 8 — 链接自检**：统一检查所有新页面的链接
8. **步骤 9 — 生成卡片**：为所有新概念统一创建卡片
9. **步骤 10 — 更新检索索引**：`python3 wiki/scripts/wiki-search.py index`

### 交互流程

批量模式下与用户的交互简化为两次：
- **开始时**：列出要处理的文件夹和预计文档数，确认后开始
- **完成后**：统一汇报关键发现、矛盾、建议创建的页面

（不像单文件夹模式逐步讨论每个文档，批量模式追求速度）

### 容错

- 单个 folder 失败不阻断其他：失败的 sub-agent 在汇总中报告错误，已成功的 folder 正常继续
- 汇总完后统一清理僵尸锁：`bash wiki/scripts/wiki-lock.sh stale`
