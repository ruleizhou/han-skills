# Step 2: 组装 Commit Message

## 目标

使用 Step 0 收集的元数据和 Step 1 的 AI 分析结果，生成 commit message。
**根据 Step 0 的"使用模板"选择，走不同分支。**

## 前置条件

已从 Step 0 获取：
- `use_template`: 是否使用 ~/.git-template 格式 (true/false)
- `module`: Module 名称
- `project`: Project 名称（customer_name）
- `bug_id`: Bug-ID
- `owner`: Owner 名称

已从 Step 1 获取：
- `short_summary`: 变更摘要
- `root_cause`: 根因描述
- `solution`: 方案描述

## 分支 A：不使用模板（use_template = false）

直接使用 Step 1 AI 生成的 `short_summary` 作为 commit message：

```
<short_summary>
```

跳过模板组装和校验，直接输出→ 进入 Step 3。

## 分支 B：使用模板（use_template = true）

### 1. 重新读取模板

重新读取 `~/.git-template`，确认格式未变化。

当前模板格式（基于读取结果）：

```
[Project][Bug-ID][Module]xxxxxx [Owner]zhourulei

[Root Cause]
	xxxx
[Solution  ]
	xxxxx
```

### 2. 组装 Subject 行

**Subject 行格式**（Module 始终包含）：

```
[<project>][<bug_id>][<module>]<short_summary> [Owner]<owner>
```

**组装规则**：
- `project` = Step 0 选择的 customer_name（或用户自定义输入）
- `bug_id` = Step 0 用户输入的 Bug-ID
- `module` = Step 0 用户选择的 Module
- `short_summary` = Step 1 AI 生成的摘要
- `owner` = 从 ~/.git-template 第一行提取的 Owner 值（默认 zhourulei）

**示例**：
```
[SM6225][CR-12345][USB] Fix NULL pointer dereference in DWC3 gadget disconnect [Owner]zhourulei
```

### 3. 组装 Body

```
[Root Cause]
	<root_cause 内容，使用 tab 缩进>
[Solution  ]
	<solution 内容，使用 tab 缩进>
```

**注意**：
- `[Root Cause]` 和 `[Solution  ]` 后不跟内容，另起一行
- 正文每行以 **tab** 缩进（与模板一致）
- `[Solution  ]` 中方括号内有**两个空格**，保持与模板一致
- 如果 root_cause 或 solution 有多行，每行都要 tab 缩进

### 4. 校验

检查以下项目：

1. **无占位符残留**：message 中不应出现 `xxxxxx`、`xxxx`、`xxxxx` 等占位符
2. **必填字段完整**：`[Project]`、`[Bug-ID]`、`[Module]`、`[Owner]` 均非空
3. **格式一致性**：Subject 行和 Body 与 `~/.git-template` 结构一致
4. **行长度**：Subject 行建议不超过 72 字符（git 惯例），若过长提示但不强制截断

### 5. 输出完整 Commit Message

将完整 commit message 保存为上下文变量，进入 Step 3。

**完成后，读取 `workflows/step-03-commit.md` 继续。**