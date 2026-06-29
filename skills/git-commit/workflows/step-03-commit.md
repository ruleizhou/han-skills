# Step 3: 预览确认 + 执行 Commit

## 目标

展示最终 commit message 预览，**优先确认 Subject 行**，等待用户确认后执行 `git commit`。

## 前置条件

已从 Step 2 获得完整的 commit message。

## 执行步骤

### 1. 展示完整 Commit Message 和文件列表

先展示完整 commit message 和文件列表（在对话中输出）：

````
===== 完整 Commit Message 预览 =====

[<project>][<bug_id>][<module>]<short_summary> [Owner]<owner>

[Root Cause]
	<root_cause>
[Solution  ]
	<solution>

======================================
````

```bash
git diff --staged --stat
```

### 2. 确认

使用 **AskUserQuestion** 确认。**在 question 中直接嵌入 Subject 行**，让用户一眼确认 title：

| 字段 | 值 |
|------|-----|
| header | "确认提交" |
| question | "确认以下 Subject 行无误，执行 git commit？\n\n[<project>][<bug_id>][<module>]<short_summary> [Owner]<owner>" |
| 选项 1 | **确认提交** — 执行 git commit |
| 选项 2 | **修改 Subject 行** — 修改第一行 title |
| 选项 3 | **取消** — 放弃本次提交 |

> **重要**：question 中 `[<project>][<bug_id>][<module>]<short_summary> [Owner]<owner>` 必须替换为 Step 2 生成的**实际 Subject 行**，不能显示占位符。

### 3. 分支处理

#### 3a. 确认提交

将 commit message 写入临时文件并执行 commit：

```bash
# 写入临时文件
cat > /tmp/git-commit-msg-$$.txt <<'COMMITEOF'
<完整 commit message>
COMMITEOF

# 执行 commit
git commit -F /tmp/git-commit-msg-$$.txt

# 清理临时文件
rm -f /tmp/git-commit-msg-$$.txt
```

展示 commit 结果给用户。如果 commit 失败（如 pre-commit hook 报错），将错误信息展示给用户并退出。

#### 3b. 修改 Subject 行

使用 **AskUserQuestion** 让用户输入修改后的 Subject 行：

| 字段 | 值 |
|------|-----|
| header | "修改 Subject" |
| question | "输入修改后的 Subject 行（第一行）？" |
| 选项 | **输入新的 Subject 行**（用户在 Other 中输入） |

用户输入后，只替换 Subject 行，body 部分保持不变。然后重新展示预览并确认。

#### 3c. 取消

> 提交已取消。生成的 commit message 如下，如需使用可手动执行：
>
> ```
> <完整 commit message>
> ```

### 4. 完成

提交成功后，运行 `git log -1 --oneline` 展示最新提交，确认无误。

**完成。**