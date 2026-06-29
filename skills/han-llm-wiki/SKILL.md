---
name: han-llm-wiki
description: >
  个人知识库 Wiki 维护技能——通过命令操作。支持 init（初始化）、ingest（收录）、query（查询）、lint（健康检查）、card（抽卡学习）、weekly（周总结）、research（自主研究）、mode（方法论）、think（深度思考）、save（对话保存）九种命令。
  使用方式：/han-llm-wiki <命令> [参数]
  当用户输入 /han-llm-wiki 时务必使用此技能。当用户提到「收录到 wiki」「wiki 健康检查」「查一下 wiki」
  「初始化知识库」「抽一张卡」「复习一下」「考考我」「周总结」「这周做了什么」「写周报」
  「研究一下」「帮我查一下」「深入调查」「保存这段」「归档这个分析」「存到 wiki」「深度思考」「切换模式」「切换到 PARA」「想清楚」等场景时也触发此技能并自动匹配对应命令。
---

# LLM Wiki —— 个人知识库维护技能

> **路由规则：用户输入 `/han-llm-wiki` 无参数或 `help` → 输出以下命令列表。用户指定了命令参数 → 读取 `references/cmd-<命令名>.md`（如 `init` → `cmd-init.md`）中对应命令的详细流程后执行。**
>
> **无参数时立即输出（不要读文件，不要解释，直接输出）：**
> ```
> 📖 LLM Wiki 命令列表：
>   /han-llm-wiki init    → 初始化 wiki 目录结构
>   /han-llm-wiki ingest  → 收录指定目录的文档到 wiki（无参数时收录所有已注册目录）
>   /han-llm-wiki query   → 查询 wiki 内容
>   /han-llm-wiki lint    → 健康检查（死链、矛盾、缺失页面等）
>   /han-llm-wiki card    → 抽卡学习（支持测验和讨论模式）
>   /han-llm-wiki weekly   → 生成本周工作总结
>   /han-llm-wiki research → 自主联网研究（查资料并整理到 wiki）
>   /han-llm-wiki mode     → 查看/切换 wiki 组织方法论模式
>   /han-llm-wiki think    → 10 原则深度思考框架
>   /han-llm-wiki save     → 保存对话洞察为结构化 wiki 页面
> ```

## 命令路由

| 命令 | 功能 | 详解位置 |
|------|------|----------|
| `init` | 初始化 wiki 目录结构 | `references/cmd-init.md` |
| `ingest` | 收录指定目录文档到 wiki（概念/来源页按内容智能选引擎配图，图文并茂） | `references/cmd-ingest.md` |
| `query` | 查询 wiki 内容（BM25 检索 + 综合回答） | `references/cmd-query.md` |
| `lint` | 健康检查 | `references/cmd-lint.md` |
| `card` | 抽卡学习 / 复习知识卡片 | `references/cmd-card.md` |
| `weekly` | 生成本周 Wiki 活动周报（从 log.md/hot.md/index.md 自动生成，无需日记） | `references/cmd-weekly.md` |
| `research` | 自主联网研究并整合到 wiki | `references/cmd-research.md` |
| `mode` | 查看/切换 wiki 方法论模式（Engineering/Generic/LYT/PARA/Zettelkasten） | `references/cmd-mode.md` |
| `think` | 10 原则深度思考框架（观察→倾听→思考→连接→感受→接受→创造→成长） | `references/cmd-think.md` |
| `save` | 保存对话洞察为结构化 wiki 页面（5 种笔记类型，按需多引擎智能配图，模式感知） | `references/cmd-save.md` |

如果用户的话意明确指向某个操作但没有用命令格式（如「帮我收录这篇论文」「检查一下 wiki」「抽张卡」「考考我」「复习一下」），自动匹配对应命令执行。

---

## 项目结构

**结构由 `init` 动态生成**——不再使用固定模板。`init` 扫描工作区内容（如 kernel 源码的 `drivers/`, `arch/`, `kernel/`），智能生成与项目对齐的目录骨架。典型例子：

```
# Kernel 源码项目 — 结构反映源码组织
01-Architecture/        # 架构总览
02-Subsystem/           # 核心子系统（Memory/Process/Network...）
03-Drivers/             # 驱动框架（DMA/USB/GPU...）
04-Qualcomm-Platform/   # 平台专题（检测到 qcom）
...

# 软件项目 — 结构反映代码组织
src/  Components/  Hooks/  API/  Docs/
...

# 知识库 — 结构反映概念关系
concepts/  sources/  analyses/  daily/
...
```

**公共基础设施（所有项目通用）**：
```
wiki/                          # AI 维护的知识层 + 全部基础设施
├── scripts/                   # 辅助脚本
│   ├── wiki-lock.sh           # 文件锁
│   └── wiki-search.py         # 检索引擎（index/search/stats/rerank）
├── hot.md                     # 会话热缓存（~500词）
├── index.md                   # 内容索引
├── log.md                     # 操作日志（追加式）
├── overview.md                # 总览
├── sources/ concepts/ entities/ analyses/ cards/
├── .locks/                    # 文件锁（自动管理）
└── .mode.json                 # 方法论模式配置
```

> **`.search_index.json` 位于 vault 根目录**(与 `00-Home/`~`10-Notes/` 同级，即 `wiki-search.py --wiki .` 指定的 wiki_dir)，由引擎写入/读取；它是隐藏文件，Obsidian 默认不显示。其余基础设施均在 `wiki/` 下。

**分工**：用户编写原始笔记，Claude 维护 wiki/ 层。已 ingest 的文件夹记录在 `wiki/.ingest-folders.yaml`。

---

## 核心规范

### 文件命名（极其重要）

**铁律：文件名 = 链接名 = frontmatter title**（无例外）

- 中文命名示例：`[[Transformer 架构]]` → `Transformer 架构.md`
- 英文标题含空格时，文件名也含空格：`[[Qualcomm IPC Logging]]` → `Qualcomm IPC Logging.md`
- 禁止英文 kebab-case 命名：`transformer-architecture.md` → 链接 `[[transformer-architecture]]` 会死链
- 禁止卡片加「卡片」后缀：`Transformer 架构 卡片.md` → 和概念页混淆
- 禁止链接带 `.md`：`[[overview.md]]` → 死链，正确写法 `[[overview]]`
- **何时用 kebab-case**：仅限非 wiki 页面的代码路径/URL 引用（如 `drivers/gpu/drm/msm`），且不允许用 `[[]]` wikilink 包裹
- 顶层结构页（如 `01-Architecture/` 下的页面）推荐英文 title 但**文件名仍然等于 title**

### YAML frontmatter

每个 wiki 页面必须包含：
```yaml
---
title: 页面标题
type: entity | concept | source | analysis | index | log | overview
# 注：index/log/overview 用于 wiki/ 基础设施页（index.md/log.md/overview.md）；
#     普通知识页用 entity/concept/source/analysis
tags: [标签1, 标签2]
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: [[来源1]], [[来源2]]
---
```

### 写作规范

- 使用 `[[双向链接]]` 连接相关页面
- 信息注明来源：`> 来源：[[来源页面名]]`
- 矛盾标记：`⚠️ 与 [[另一页面]] 中的描述存在矛盾`

### 绝对禁止

- **绝不修改 note/ 下的原始文件**——只读不改
- **绝不覆盖已有页面中的有价值内容**——整合不是替换
- **绝不跳过链接自检**——收录完必须验证死链

---

## 参考文件

按需读取，不要一次性全部加载：

- `references/cmd-<命令名>.md`——各命令的详细流程（执行对应命令时读取该文件）
- `references/page-templates.md`——页面模板（创建页面时读取）
- `references/diagram-guide.md`——图文并茂配图指南（多引擎：D2 / han-svg / han-infographic / han-hand-write-pic / han-disassembly-diagram，ingest/save 配图时读取）
- `references/schema-guide.md`——AGENTS.md 配置指南（初始化时读取）
