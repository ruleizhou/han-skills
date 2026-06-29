# Schema 配置指南

## 什么是 Schema

Schema 是 wiki 根目录下的配置文件（AGENTS.md），它告诉 LLM 如何维护这个特定的 wiki。
AGENTS.md 是跨工具通用约定，Claude Code、Cursor、Copilot 等主流 Agent 工具均能识别。
不同的知识领域、不同的用户偏好，需要不同的 schema 配置。

## Schema 应该包含什么

### 1. Wiki 基本信息

```markdown
## Wiki 基本信息
- **主题**：这个 wiki 关注什么领域
- **范围**：覆盖哪些内容，不覆盖哪些
- **目标**：用户希望用这个 wiki 达到什么目的
```

### 2. 目录结构

目录结构由 `init` 动态生成，反映工作区实际内容（如 kernel 源码的 `drivers/` → `03-Drivers/`）。在 AGENTS.md 中描述当前结构即可：

```markdown
## 目录结构
- 01-Architecture/ — 架构总览
- 02-Subsystem/ — 核心子系统
- 03-Drivers/ — 驱动框架
- ...
- wiki/ — AI 维护的知识层（sources/ concepts/ entities/ analyses/ cards/）
```

### 3. 页面格式偏好

```markdown
## 页面格式偏好
- 实体页面是否需要特定字段？
- 概念页面是否有领域特有的分类方式？
- 是否使用特定的标签体系？
- frontmatter 中需要哪些自定义字段？
```

### 4. 收录偏好

```markdown
## 收录偏好
- 一次处理一个来源 vs 批量处理
- 是否需要每次确认后才写入
- 哪些类型的信息优先收录
- 是否有特定领域的实体/概念需要重点关注
```

### 5. 领域特有约定

```markdown
## 领域特有约定
- 特定术语的统一写法
- 特定关系类型的命名
- 特定的页面分类维度
```

## 如何维护 Schema

Schema 是一个活的文档。建议：

1. **开始时简单**——先写基本信息和目录结构，其余在使用中逐步完善
2. **遇到问题就更新**——如果发现同样的纠正重复出现，把它写进 schema
3. **用户主导**——schema 的重大变更应该与用户讨论
4. **保持精简**——schema 不是教科书，是操作手册

## Schema 模板

```markdown
# [Wiki 名称] Schema

## 基本信息
- **主题**：[领域]
- **范围**：[覆盖什么]
- **目标**：[要达到什么目的]

## 目录结构
（由 init 动态生成，根据工作区内容调整）
- 01-.../
- 02-.../
- wiki/ — AI 维护的知识层
  - sources/ concepts/ entities/ analyses/ cards/

## 页面约定
- 文件名 = 链接名 = frontmatter title
- 使用中文命名
- 每个页面包含 YAML frontmatter

## 收录流程
- 一次处理一个文档
- 收录后必须执行链接自检
- 概念页面必须创建对应知识卡片

## 每日工作流程（可选，仅 engineering 模式启用）

### 日间 — 每条消息必做
- 判断是否为工作/技术内容，如果是则执行动作A和动作B
- 动作A：保存完整内容到收件目录（如 `10-Notes/` 或 `inbox/`），一类问题一个文件（`topic-关键词.md`）
- 动作B：追加到当日日志（`.today.md`），格式：`- HH:MM 摘要 [→ topic-xxx.md](inbox/topic-xxx.md)`

### 下班 — 用户说"下班"或"收工"时必做
1. 读取当日的 `.today.md`
2. 整理成正式日报，写入日志目录（如 `daily/`）
3. 清空 `.today.md`
4. 回复下班问候

## 领域术语
- [术语1]：[定义]
- [术语2]：[定义]

## 已知偏好
- [用户的偏好1]
- [用户的偏好2]
```
