# /llm-wiki save —— 对话保存

将当前对话中高价值的分析、洞察或决策归档为结构化 wiki 页面。不让好的回答消失在聊天记录里。

**触发条件：**
- `/llm-wiki save` — 自动识别对话中最高价值的内容并询问标题
- `/llm-wiki save <标题>` — 指定标题保存
- 用户说「保存这段」「归档这个分析」「存到 wiki」「记录下来」

**设计哲学：** 保存的不是对话转录，而是**蒸馏后的知识**。保存后，未来的会话可以冷启动读到这篇笔记，不需要翻聊天记录。

---

## 工作流（9 步）

**步骤 1：扫描对话**

识别当前对话中最有价值保存的内容：
- 多步分析或推理链
- 新的技术理解和洞察
- 架构/策略决策及理由
- 比较和对比
- 被讨论的外部资料摘要

跳过：简单问答、一次性命令、闲聊。

**步骤 2：询问标题**

如果用户未指定标题 → 「用什么标题保存？」（简短、描述性、符合 wiki 命名铁律）
如果用户指定了 → 直接用

**步骤 3：判定笔记类型**

按下表确定类型。如果用户指定了类型，遵守用户选择。

| 类型 | 归档位置（engineering） | 判断标准 |
|------|------------------------|---------|
| `synthesis` | `wiki/analyses/` | 多步分析、对比、综合回答、研究总结 |
| `concept` | `wiki/concepts/` | 解释/定义了一个概念、模式、框架 |
| `source` | `wiki/sources/` | 讨论了外部资料（文章/论文/网页），含 URL |
| `decision` | `wiki/analyses/` | 做了架构/策略决策，含理由和上下文 |
| `session` | `*会话保存目录*`（如 `10-Notes/` 或 `sessions/`） | 整段对话摘要，覆盖多个主题 |

不确定时默认 `synthesis`。

**步骤 4：提取内容**

用**声明式现在时**重写（不是"用户问了 DMA..."而是"DMA 是一种..."）：

- ✅ "DMA 通过 scatter-gather 模式支持不连续内存块传输"
- ❌ "用户问了关于 DMA 的问题，我解释说 DMA 是直接内存访问..."
- 包含足够上下文，让未来会话能冷启动读懂
- 链接所有提到的 wiki 页面 `[[页面]]`
- 标注来源：`> 来源：[[来源页]]`

**步骤 5：创建页面**

- 在目标目录下创建 `.md` 文件
- 完整 frontmatter（见下方模板）
- **模式感知**：归档路径根据 `wiki/.mode.json` 的 mode 决定（见下方路由表）

**步骤 5.5：图文并茂（按需配 D2 图）**

页面创建后，为适合可视化的笔记配上 D2 图，做到图文并茂。详细规则见 `references/diagram-guide.md`（与 `ingest` 共用同一套配图内核）。

**配图范围**：`synthesis` / `decision` / `concept` / `source` 类型配图；`session`（整段多主题对话摘要）默认**跳过**。

**流程**：
1. 检测 D2 CLI：`which d2 && d2 --version`。未安装 → 走降级（D2 源以代码块嵌入 + 手动编译提示，见 diagram-guide.md 第 7 节），不中断
2. 按笔记类型 + 内容特征，依 `references/diagram-guide.md` 智能判断：是否配图、配什么类型
   - synthesis（多步分析/对比）→ flowchart 或 system-architecture
   - decision（架构/策略选型）→ system-architecture（决策涉及的架构）+ 可选方案对比
   - concept / source → 同 ingest 规则
   - 简单结论性笔记（无结构/流程）→ 跳过
3. 对待配图笔记：
   - 在笔记**同目录**建 `_diagrams/`（如 `wiki/analyses/_diagrams/`，路径随上方 mode 路由表）
   - 读 `d2-diagram/assets/templates/<type>.d2` 作骨架，写 `<笔记slug>-<类型短码>.d2`
   - 编译为 SVG（命令见 diagram-guide.md 第 4 节；SVG 自动适配亮/暗主题，无需 PNG/Playwright）
   - 正文嵌入 `![图 N: 标题](_diagrams/xxx.svg)` + 图号 + **图后 2-5 句说明**
4. **最小本地验证**：`ls -lh _diagrams/<name>.svg` 确认文件存在且非空（save 不跑全量 lint，保持轻量；全量图片死链检查由后续 `ingest` Step 10 或 `/llm-wiki lint` 兜底）

**步骤 6：收集链接**

- 扫描对话中提到的所有 wiki 页面标题
- 加入 frontmatter 的 `related` 字段
- 在正文中建立 `[[双向链接]]`

**步骤 6.5：同步 00-10 层 Seed 入口页**

仅 `engineering` 模式下执行（其他 mode 无 00-10 目录结构，跳过）。

将新页面注册到用户可见的 00-10 层，让浏览目录的用户能发现它，而不是只藏在 `wiki/` 深处。

1. **读取 Seed 映射表**（根据 tags → 00-10 目录），确定归属：

   ```yaml
   # tag → 00-10 目录映射
   01-Platform:      [qualcomm, qcom, platform, sm6225, sm8450, sm8550, agatti, divar, kamorta]
   02-Subsystem:     [memory, mm, slub, kasan, ion, ddr, usb, dwc3, storage, ufs, kernel, arm64, register]
   03-Stability:     [crash, panic, deadlock, watchdog, stability, brk, kasan]
   04-Performance-Power: [performance, power, suspend, pm, cpufreq, eas, benchmark]
   05-Tools:         [debug, trace32, perf, lockdep, simpleperf, ai, llm, claude, cursor, opencode, git, dev]
   06-Special-Topics: [camera, camx, chi, xr, special, 6dof]
   ```

   匹配规则：页面 tags 中任意一项命中映射表的 tag 列表 → 落入对应目录。
   多个目录命中时，选**命中数最多**的；若无命中，跳过此步骤并注明建议。

2. **确认目标 Seed 页**：

   - 若目标目录下已有同名 Seed 页（`<topic-slug>.md` 或已有覆盖该主题的总结页）→ **更新已有页**：追加一行 `- [[wiki/路径|标题]]` 引用
   - 若无 → **创建新 Seed 页**，格式见下方模板

3. **Seed 页内容要求**：

   - frontmatter：`type: concept`、`status: seed`
   - 正文结构：概述（2-3 句摘要）→ 核心方法（链接到 wiki 层新页面）→ 相关概念（链接其他 Seed/Concept 页）
   - 文档化注释：`> 由 /llm-wiki save 自动生成，YYYY-MM-DD`

4. **更新原 Seed 页**（如果目标目录的入口页如 `01-Platform/qualcomm.md` 存在）：在其「相关概念」或「核心来源」区追加一行新引用。

5. `session` 类型跳过此步骤（多主题异构，无法归入单一目录）。

**步骤 7：更新基础设施（加锁）**

> 以下每步写操作前后加锁（`bash wiki/scripts/wiki-lock.sh lock/unlock <file>`）

- 更新 `wiki/index.md`：在相关章节顶部添加新条目
- 追加 `wiki/log.md`：
  ```markdown
  ## [YYYY-MM-DD] save | 笔记标题
  - Type: synthesis
  - Location: wiki/analyses/笔记标题.md
  - From: conversation on [简要主题描述]
  ```
- 更新 `wiki/hot.md`：刷新「最近活跃主题」

**步骤 8：确认**

```
✅ 已保存：[[笔记标题]]
   → wiki/analyses/笔记标题.md（知识层）
   → 04-Performance-Power/xxx.md（Seed 入口页，如适用）
```

---

## Frontmatter 模板

```yaml
---
type: synthesis | concept | source | decision | session
title: "笔记标题"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - <相关标签>
status: developing
related:
  - "[[提到的 Wiki 页面1]]"
  - "[[提到的 Wiki 页面2]]"
sources:
  - "[[来源页面]]"
---
```

`synthesis` 类型额外字段：
```yaml
question: "触发这个问题/分析的原问题"
answer_quality: solid  # solid | preliminary | speculative
```

`decision` 类型额外字段：
```yaml
decision_date: YYYY-MM-DD
status: active  # active | superseded | implemented
```

**Seed 页模板**（步骤 6.5 创建时使用）：
```yaml
---
title: <topic-slug>
type: concept
tags: [<标签1>, <标签2>]
created: YYYY-MM-DD
updated: YYYY-MM-DD
status: seed
---

# <标题>

> <2-3 句摘要> —— 已收录 N 篇 analyses/sources/concepts

## 概述

<2-3 句正文>

## 核心方法 / 核心来源

- [[wiki/路径|标题]] — <简短说明>

## 相关概念

- [[其他 Seed 页]] — <简短说明>
```

> 由 `/llm-wiki save` 自动生成。

---

## 模式感知路由

根据 `wiki/.mode.json` 的 mode 决定归档路径：

| 类型 | engineering | generic | lyt | para | zettelkasten |
|------|-----------|---------|-----|------|-------------|
| synthesis | `wiki/analyses/` | `wiki/analyses/` | `wiki/notes/` | `wiki/resources/` | `wiki/<ID>-syn-<slug>.md` |
| concept | `wiki/concepts/` | `wiki/concepts/` | `wiki/notes/` | `wiki/resources/concepts/` | `wiki/<ID>-con-<slug>.md` |
| source | `wiki/sources/` | `wiki/sources/` | `wiki/notes/` | `wiki/resources/` | `wiki/<ID>-src-<slug>.md` |
| decision | `wiki/analyses/` | `wiki/analyses/` | `wiki/notes/` | `wiki/projects/` | `wiki/<ID>-dec-<slug>.md` |
| session | `*会话目录*` | `wiki/sessions/` | `wiki/notes/` | `wiki/projects/inbox/` | `wiki/<ID>-sess-<slug>.md` |

> 如果 `wiki/.mode.json` 不存在 → 默认 `engineering` 模式。

---

## 保存 vs 跳过

**保存：**
- 非显而易见的洞察或综合
- 带理由的决策
- 花了功夫的分析
- 可能被再次引用的对比
- 研究结果和总结

**跳过：**
- 简单问答（一个命令就解决的）
- 纯粹的事务性对话
- 临时性的、明天就过时的内容
- 已经在 wiki 中充分覆盖的内容
