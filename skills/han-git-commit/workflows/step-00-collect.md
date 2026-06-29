# Step 0: 交互收集元数据

## 目标

通过交互收集 commit message 所需的元数据。**先确认是否使用模板，再决定后续流程。**

## 前置检查

1. 确认当前目录是 git 仓库：
   ```bash
   git rev-parse --git-dir 2>/dev/null || echo "NOT_A_GIT_REPO"
   ```
   如果不是，立即报错退出。

2. 读取 `~/.git-template`，确认当前模板格式。解析第一行结构：
   - 格式：`[Project][Bug-ID][Module]xxxxxx [Owner]zhourulei`
   - 记录 `[Owner]` 字段值（默认为 zhourulei）

## 执行步骤

### 步骤 1：是否使用模板？（单独交互）

**首先用一个 AskUserQuestion 确认是否使用 ~/.git-template 模板：**

| 字段 | 值 |
|------|-----|
| header | "模板" |
| question | "是否使用 ~/.git-template 模板格式？" |
| 选项 1 | **使用模板** — 按 `[Project][Bug-ID][Module]...` 格式生成 |
| 选项 2 | **不使用模板** — 跳过后面的字段交互，只用简短描述提交 |

**分支处理：**

- **选择"不使用模板"** → 设置 `use_template = false`，Module/Project/Bug-ID 均为空。直接跳到 Step 1（diff 分析）。
- **选择"使用模板"** → 设置 `use_template = true`，继续步骤 2。

### 步骤 2：收集 Module/Project/Bug-ID（仅使用模板时）

读取 `data/modules.json` 和 `data/projects.json` 获取预设列表。

**在同一个 AskUserQuestion 调用中同时收集 3 个字段：**

**问题 1：选择 Module**（header: "Module", multiSelect: false）

从 modules.json 读取列表，取前 3 个 + "其他（自由输入）"：

| 选项 | label | description |
|------|-------|-------------|
| 1 | (从 modules.json[0]) | 如 Kernel |
| 2 | (从 modules.json[1]) | 如 Driver |
| 3 | (从 modules.json[2]) | 如 USB |
| 4 | 其他（自由输入） | 输入自定义 Module 名称 |

> 用户选"其他"时在 Other 中输入自定义 Module 名称。

**问题 2：选择 Project**（header: "Project", multiSelect: false）

从 projects.json 读取列表，展示 `internal_name`。取前 3 个 + "其他（手动输入）"：

| 选项 | label | description |
|------|-------|-------------|
| 1 | MT582 | 客户项目 SM6225 |
| 2 | MT6989 | 客户项目 SM8550 |
| 3 | 其他（手动输入） | 输入自定义 Project 名称 |

> - 选预设项 → 使用对应的 `customer_name` 写入 commit
> - 选"其他" → 用户在 Other 中输入，直接使用（无需映射）

**问题 3：输入 Bug-ID**（header: "Bug-ID", multiSelect: false）

| 选项 | label | description |
|------|-------|-------------|
| 1 | 输入 Bug-ID | 在 Other 中输入 Bug-ID |
| 2 | NA（无 Bug-ID） | 使用 NA 作为占位符 |

> - 选"输入 Bug-ID" → 用户在 Other 中输入具体 Bug-ID
> - 选"NA" → 直接使用 `NA` 填充 `[Bug-ID]` 字段

## 输出

收集完成后，输出结构化摘要：

```
📋 收集结果:
  使用模板:  <是/否>
  Module:    <用户选择或输入的 Module，不使用模板则为空>
  Project:   <customer_name 或自定义名称，不使用模板则为空>
  Bug-ID:    <Bug-ID 或 NA，不使用模板则为空>
  Owner:     <从 template 读取的 Owner>
```

**完成后，读取 `workflows/step-01-diff.md` 继续。**