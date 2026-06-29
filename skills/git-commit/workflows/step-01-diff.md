# Step 1: Git Diff 分析

## 目标

获取 git diff 内容，通过 AI 分析提取 commit message 所需的摘要、根因、方案。

## 前置条件

已从 Step 0 获取以下信息：
- `module`: Module 名称
- `project`: Project 名称（customer_name 或自定义）
- `bug_id`: Bug-ID
- `owner`: Owner 名称

## 执行步骤

### 1. 获取 Diff 内容

优先检查 staged 变更：

```bash
git diff --staged
```

如果 staged diff 为空，检查 unstaged 变更：

```bash
git diff
```

如果两者都为空 → 提示用户：
> 没有检测到变更。请先用 `git add <files>` 暂存需要提交的文件，然后重新触发提交。

询问用户是否需要帮助 stage 文件（用 AskUserQuestion 确认），如果需要，运行 `git status` 展示文件列表，然后按用户指示 `git add`。

### 2. 检查变更规模

```bash
git diff --staged --stat
```

如果变更文件过多（>100 个文件）或 diff 过大（>5000 行），提示用户：
> 变更规模较大（X 个文件，Y 行），建议拆分为多个提交。是否继续？

### 3. AI 分析 Diff 内容

基于 diff 内容，AI 进行分析并提取：

1. **short_summary**（替换 `xxxxxx`）：
   - 1-2 句英文摘要，描述本次修改的核心内容
   - 保持简洁，不超过 80 个字符
   - 使用技术准确的语言
   - 示例：
     - `Fix NULL pointer dereference in USB DWC3 gadget disconnect`
     - `Add thermal throttling support for SM6225 GPU`
     - `Update camera sensor power sequence for MT6989`

2. **root_cause**（替换 `[Root Cause]` 下的 `xxxx`）：
   - 分析问题的根本原因
   - 如果 diff 是 bug fix，描述原代码的问题和触发条件
   - 如果 diff 是新功能/优化，描述为什么需要这个变更（背景/动机）
   - 用中文或英文描述，保持技术精确性
   - 多行时用 tab 缩进

3. **solution**（替换 `[Solution]` 下的 `xxxxx`）：
   - 描述本次修改如何解决问题或实现功能
   - 列出关键改动点（算法、数据结构、配置等）
   - 用中文或英文描述
   - 多行时用 tab 缩进

### 4. 输出分析结果

结构化输出：

```
📊 Diff 分析结果:
  文件变更数:  X 个文件
  行变更:     +A -B
  摘要:       <short_summary>
  根因:       <root_cause>
  方案:       <solution>
```

**完成后，读取 `workflows/step-02-draft.md` 继续。**