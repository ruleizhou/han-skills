# LLM Wiki Skill

个人知识库 Wiki 维护技能——让 Claude 成为你的 wiki 维护者。

## 这是什么

一个 Claude Code skill，教你用 LLM **增量构建和维护持久化的个人知识库**。

传统 RAG 每次从原始文档中重新检索，没有积累。LLM Wiki 不同——Claude 会持续构建一个由 markdown 文件组成的、相互链接的 wiki 知识库。每次收录新来源、每次查询，wiki 都会更丰富。交叉引用已经建好，矛盾已经标记，综合分析反映了所有读过的内容。

配合 Obsidian 使用效果最佳：Claude 写 wiki，你用 Obsidian 浏览和导航。

## 安装

将 `han-llm-wiki` 目录复制到你的 Claude Code skills 目录：

```bash
# 方式一：复制到项目级
cp -r han-llm-wiki /你的项目目录/.claude/skills/

# 方式二：复制到全局
cp -r han-llm-wiki ~/.claude/skills/
```

或者将 skill 路径添加到项目的 `AGENTS.md` 中。

## 快速开始

```
1. /han-llm-wiki init              → 创建 wiki 目录骨架
2. 把深度知识文档放到 note/10-Domains/ 下
3. /han-llm-wiki ingest            → 收录文档到 wiki（自动生成知识卡片）
4. /han-llm-wiki query 你的问题     → 查询知识库
5. /han-llm-wiki card              → 抽卡复习学习
6. /han-llm-wiki weekly            → 生成本周工作总结
7. /han-llm-wiki lint              → 定期健康检查
```

## 命令列表

### `/han-llm-wiki init`

初始化 wiki 项目。创建目录结构和基础文件。

```
/han-llm-wiki init
```

创建的目录结构：

```
.
├── note/                     # 笔记层——你的原始素材
│   ├── 00-Inbox/             # 未分类的临时存储
│   ├── 01-Daily/             # 每日工作日志
│   ├── 02-Weekly/            # 每周总结
│   ├── 03-Projects/          # 项目文档
│   ├── 10-Domains/           # 深度知识（按领域组织）
│   │   ├── Kernel/
│   │   ├── Android/
│   │   ├── BSP/
│   │   └── Tools/
│   └── assets/               # 图片等附件
├── wiki/                     # wiki 页面（Claude 全权维护）
│   ├── index.md              # 内容目录索引
│   ├── log.md                # 操作日志（追加式）
│   ├── overview.md           # 总览/综合页
│   ├── entities/             # 实体页面
│   ├── concepts/             # 概念页面
│   ├── sources/              # 来源摘要页面
│   ├── analyses/             # 分析、比较、综合页面
│   └── cards/                # 知识卡片（用于抽卡复习）
└── AGENTS.md                  # schema 配置（兼容多 Agent 工具）
```

**note/ 目录说明：**

| 目录 | 定位 | 说明 |
|------|------|------|
| `00-Inbox` | 临时收件箱 | 想法、网页剪辑、代码段等。原则：先记录，后分类 |
| `01-Daily` | 每日日志 | 任务、问题、观察、结论和次日计划 |
| `02-Weekly` | 每周总结 | 整合每日条目，包含完成事项、进展、风险、收获、下周计划 |
| `03-Projects` | 项目文档 | 概览、需求、硬件、软件架构、编译环境、BSP适配、驱动bringup |
| `10-Domains` | 深度知识 | 长期可复用的原理性知识（Kernel/Android/BSP/Tools），**ingest 的收录对象** |

如果目录已存在，会检查完整性并补建缺失部分，不会覆盖已有文件。

---

### `/han-llm-wiki ingest`

收录新的源文件到 wiki。这是最核心的操作。

```
/han-llm-wiki ingest
```

收录对象是 `note/10-Domains/` 下的文档。使用前先把深度知识文档放到对应领域子目录下（Kernel/Android/BSP/Tools）。

**收录流程（9 步）：**

| 步骤  | 操作                         |
| --- | -------------------------- |
| 1   | 读取来源文件，理解核心内容              |
| 2   | 与你讨论关键发现，确认重点方向            |
| 3   | 创建来源摘要页（`wiki/sources/` 下） |
| 4   | 创建/更新实体和概念页面               |
| 5   | 更新 overview.md（如有重大变化）     |
| 6   | 更新 index.md（添加所有新条目）       |
| 7   | 追加 log.md（记录操作）            |
| 8   | 链接自检（验证所有 `[[链接]]` 有效）     |
| 9   | 生成/更新知识卡片（`wiki/cards/` 下） |

一次收录通常影响 10-15 个 wiki 页面。Claude 会：
- 提取关键实体和概念，创建对应的 wiki 页面
- 与已有页面建立交叉引用
- 主动标记新信息与已有信息的矛盾
- 收录完毕后自检所有链接，确保零死链
- 为每个概念自动生成知识卡片（含测验题）

---

### `/han-llm-wiki query`

基于 wiki 内容回答问题。

```
/han-llm-wiki query Scaling Laws 和语言模型有什么关系？
```

Claude 会：
1. 先读 `index.md` 了解 wiki 结构
2. 定位并读取相关页面
3. 综合多个页面的信息，给出深度回答
4. 标注信息来源（引用了哪些 wiki 页面）
5. 如果回答有价值，建议存为新的分析页面

如果相关 wiki 页面还没建，会回退到 `note/10-Domains` 获取信息，并告知你哪些页面待建。

---

### `/han-llm-wiki lint`

检查 wiki 的健康状况。

```
/han-llm-wiki lint
```

执行 9 项检查，按优先级输出报告：

| 优先级 | 检查项 | 说明 |
|--------|--------|------|
| P0 | 链接完整性 | 扫描所有 `[[链接]]`，验证目标文件是否存在 |
| P0 | 文件名一致性 | 文件名 = 链接名 = frontmatter title |
| P1 | 矛盾检测 | 不同页面间是否有矛盾信息 |
| P1 | 过时信息 | 是否有被新来源推翻的旧论断 |
| P2 | 孤立页面 | 没有入站链接的页面 |
| P2 | 缺失页面 | 被引用但不存在的页面 |
| P2 | 缺失交叉引用 | 内容相关但没有互相链接的页面 |
| P3 | 数据空白 | 可以用搜索填补的信息缺口 |
| P3 | 结构优化 | 是否需要合并、拆分或重组 |
| P3 | 卡片一致性 | 概念页更新后卡片是否同步 |

报告包含每个问题的具体修复建议。修复操作需要你确认后才执行。

建议定期执行 lint（比如每收录 5-10 个来源后）。

---

### `/han-llm-wiki card`

抽卡学习——从知识卡片中抽取一张进行复习。

```
/han-llm-wiki card              # 随机抽取一张（智能优先：新学的、复习少的优先）
/han-llm-wiki card quiz         # 抽卡 + 测验模式（出选择题/判断题考你）
/han-llm-wiki card discuss      # 抽卡 + 讨论模式（围绕卡片展开深度讨论）
/han-llm-wiki card Scaling Laws # 抽取指定概念的卡片
```

**什么是知识卡片？**

知识卡片是 wiki 概念页面的精华浓缩版。每张卡片包含：
- 一句话核心定义（看到就能回忆起来的锚点）
- 3-5 条核心要点
- 3-5 道测验题（选择题、判断题、填空题）
- 2-3 个讨论切入点
- 讨论记录（每次讨论后自动追加）

卡片存放在 `wiki/cards/` 目录下，**只为概念建卡片**，不为实体或来源建。

**卡片自动生成：**

执行 `/han-llm-wiki ingest` 时，每创建一个新的概念页面，都会自动生成对应的卡片。如果该概念已有卡片，新信息会被整合进去（补充要点、增加测验题）。

**三种复习模式：**

| 模式 | 命令 | 做什么 |
|------|------|--------|
| 浏览 | `/han-llm-wiki card` | 展示卡片核心要点，问你要测验还是讨论 |
| 测验 | `/han-llm-wiki card quiz` | 展示要点回顾 → 出 2-3 道题 → 判卷解析 → 更新掌握度 |
| 讨论 | `/han-llm-wiki card discuss` | 选一个切入点提问 → 引导你思考和表达 → 总结讨论收获 → 追加到卡片 |

**讨论模式的流程：**

```
Claude：抽到卡片「Scaling Laws」。
        讨论切入点：如果 Scaling Laws 的幂律关系突然失效了，
        你觉得最可能的原因是什么？
你：  我觉得可能是数据质量的问题...
Claude：有道理，数据质量确实是一个因素。但如果数据量足够大呢？
        ...
你：  差不多了，总结一下
Claude：讨论摘要：
        - 核心收获：幂律关系依赖数据分布的稳定性
        - 新理解：Scaling Laws 可能在分布漂移场景下失效
        - 待探索：分布漂移对语言模型性能的影响
        [摘要已追加到卡片讨论记录]
```

**掌握度机制：**

| 状态 | 条件 | 抽取优先级 |
|------|------|-----------|
| 新学 | 默认 / 测验多数答错 | 最高 |
| 熟悉 | 测验全对 | 中等 |
| 掌握 | 连续多次全对 | 最低 |

间隔超过 7 天未复习的卡片会自动提升优先级。

---

### `/han-llm-wiki weekly`

生成本周工作总结——读取每日日志，提炼为结构化周报。

```
/han-llm-wiki weekly            # 总结本周
/han-llm-wiki weekly 上周        # 总结上周
/han-llm-wiki weekly 2026-04-06 # 总结指定日期所在的那一周
```

**工作流程：**

1. 确定时间范围（默认本周一到本周日）
2. 读取 `note/01-Daily/` 中该周的每日日志
3. 分析提炼：完成任务、关键进展、问题、知识收获、风险、下周计划
4. 生成结构化总结，保存到 `note/02-Weekly/`
5. 展示关键发现，用户确认后定稿

**总结内容包含：**

| 模块 | 说明 |
|------|------|
| 完成的任务 | 本周做完的所有事情，标注来源日期 |
| 关键进展 | 技术和项目上的重要突破 |
| 遇到的问题 | 卡点、阻碍及解决状态 |
| 知识收获 | 新学到的东西、新认知 |
| 风险与关注点 | 需要留意的事项 |
| 下周计划 | 从日志推断的待办和优先级 |
| 日志索引 | 每天日志的一句话摘要 |

**核心原则：** 忠实于日志——只总结实际记录的内容，不臆测不编造，每条总结都标注来自哪天的日志。

---

### `/han-llm-wiki help`

显示帮助信息。

```
/han-llm-wiki help
```

---

## 命名规范

**铁律：文件名 = 链接名 = frontmatter title**

Obsidian 的 `[[双向链接]]` 按文件名匹配，所以这三者必须一致。推荐中文命名：

| 正确 | 错误 |
|------|------|
| `Transformer 架构.md` → `[[Transformer 架构]]` | `transformer-architecture.md` → `[[Transformer 架构]]`（死链） |
| `自注意力机制.md` → `[[自注意力机制]]` | `self-attention.md` → `[[自注意力机制]]`（死链） |
| `OpenAI.md` → `[[OpenAI]]` | `openai.md` → `[[OpenAI]]`（可能死链） |

## 页面类型

每种页面都有固定结构（含 YAML frontmatter），详见 skill 中的 `references/page-templates.md`：

| 类型  | 目录                 | 说明             |
| --- | ------------------ | -------------- |
| 实体  | `wiki/entities/`   | 人物、组织、项目等「名词」  |
| 概念  | `wiki/concepts/`   | 理论、方法、框架等「主题」  |
| 来源  | `wiki/sources/`    | 每个 raw 文件的摘要页  |
| 分析  | `wiki/analyses/`   | 查询产生的深度分析和比较   |
| 卡片  | `wiki/cards/`      | 概念的精华浓缩，用于抽卡复习 |
| 总览  | `wiki/overview.md` | wiki 整体状态和核心主题 |
| 索引  | `wiki/index.md`    | 所有页面的目录        |
| 日志  | `wiki/log.md`      | 操作历史记录         |

## 配置

wiki 根目录的 `AGENTS.md` 是 schema 配置文件，记录：
- wiki 的主题领域和范围
- 目录结构的定制
- 页面格式偏好
- 收录工作流的偏好
- 领域特有的约定

你和 Claude 共同维护这个文件。初始化时 Claude 会创建基础模板，后续根据使用情况逐步完善。

配置指南详见 skill 中的 `references/schema-guide.md`。

## 配合 Obsidian 使用

推荐搭配 Obsidian 使用：

1. **Obsidian Web Clipper**：浏览器扩展，将网页文章转存为 markdown 到 `note/00-Inbox/`，整理后再移到 `10-Domains/`
2. **下载图片**：Obsidian 中 `Ctrl+Shift+D` 下载文章图片到 `note/assets/`
3. **图谱视图**：查看 wiki 的链接关系图，发现哪些页面是枢纽、哪些是孤立页面
4. **Dataview 插件**：基于 frontmatter 运行查询，生成动态列表和表格
5. **Marp 插件**：从 wiki 内容生成演示文稿

## 工作流示例

```
你：/han-llm-wiki init
Claude：[创建目录结构和基础文件]

你：[把深度知识文档放到 note/10-Domains/Kernel/ 下]

你：/han-llm-wiki ingest
Claude：我刚读完《Attention Is All You Need》，关键发现如下...
        1. 核心观点：...
        2. 建议创建：Transformer 架构、自注意力机制、多头注意力...
        重点放在哪些方面？
你：重点放在架构设计和实验结果上
Claude：[创建 10+ 个 wiki 页面 + 4 张知识卡片，更新 index/log/overview，链接自检通过]

你：/han-llm-wiki query Transformer 和 Scaling Laws 有什么关系？
Claude：[读取相关 wiki 页面，综合回答]
        Transformer 架构是 Scaling Laws 的载体...

你：/han-llm-wiki card quiz
Claude：抽到卡片「Scaling Laws」
        快速回顾：语言模型性能与规模呈幂律关系...
        第 1 题：Scaling Laws 中参数量的幂律指数是多少？
        A. -0.076  B. -0.095  C. -0.050  D. -0.080
你：A
Claude：正确！L(N) ∝ N^{-0.076}。参数量每增加约 10 倍，损失降低...
        第 2 题：...
        ...

你：/han-llm-wiki card discuss
Claude：抽到卡片「自注意力机制」
        讨论切入点：如果没有位置编码，自注意力机制能处理序列顺序吗？为什么？
你：不能，因为自注意力是排列不变的...
Claude：对，这是 Transformer 的一个关键设计问题。那你想想位置编码为什么用正弦余弦函数...
你：差不多了，总结一下
Claude：讨论摘要：
        - 核心收获：排列不变性是自注意力的特性也是局限
        - 新理解：正弦编码的外推性让模型能处理更长序列
        - 待探索：旋转位置编码（RoPE）的改进
        [摘要已追加到卡片]

你：/han-llm-wiki lint
Claude：Wiki 健康检查报告：
        P0: 0 个死链 ✅
        P1: 未发现矛盾 ✅
        P2: 建议为「位置编码」添加与「编码器-解码器架构」的交叉引用
        P3: 卡片「自注意力机制」的测验题只有 3 道，建议补充
```

## 适用场景

- **学术研究**：深入某个领域，收录论文，构建渐进式的知识图谱
- **读书笔记**：逐章收录，建立人物、主题、情节的关系网
- **项目管理**：将会议记录、设计文档、决策记录整合成团队 wiki
- **个人知识管理**：追踪目标、健康、心理学，构建关于自己的结构化知识
- **竞品分析 / 尽职调查 / 课程笔记**：任何需要长期积累和整理知识的场景

## 文件结构

```
han-llm-wiki/
├── SKILL.md                    # 核心技能文件
├── README.md                   # 本文件
└── references/
    ├── page-templates.md       # 页面模板 + 知识卡片模板
    └── schema-guide.md         # AGENTS.md 配置指南
```

## 注意事项

- **note/ 目录下的笔记永远不被修改**——它们是你的原始素材，Claude 只读不改
- **wiki 的价值在于链接**——一个有良好链接的 wiki 比一堆孤立长文更有用
- **矛盾是好东西**——发现矛盾说明知识库在成长，标记它而不是隐藏它
- **定期 lint**——每收录 5-10 个文档后跑一次健康检查，保持 wiki 健康
- **先 Inbox 后 Domains**——素材先扔进 `00-Inbox`，整理好再移到 `10-Domains` 供收录
