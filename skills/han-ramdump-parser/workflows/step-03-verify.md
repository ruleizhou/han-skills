# Step 3: 产物校验 + panic 摘要 + 交棒

## 3.1 产物校验

检查 `<dump目录>/parser_out/`：

1. 目录存在且有内容（`ls` 一眼，全量模式应有几十个文件/子目录）
2. `dmesg_TZ.txt` 存在且非空——这是核心产物
3. 快速模式只校验 dmesg_TZ.txt

异常处理：dmesg_TZ.txt 缺失或为空 → 读 `workflows/troubleshoot.md` 的「dmesg_TZ 为空/缺失」条目，常见原因是 vmlinux 不匹配或 KASLR 算错。

## 3.2 panic 签名扫描（轻分析）

读 `dmesg_TZ.txt`（大文件先 `wc -l` 再分段/从尾部读——panic 在最后），扫描崩溃签名：

- 内核 panic 类：`Kernel panic - not syncing`、`Unable to handle kernel paging request`、`Internal error`、`Oops`、`BUG:`、`Call trace`
- 看门狗类：`Watchdog`、`wdt` bark bite
- 签名库复用：`~/.claude/skills/han-kernel-crash-analyzer/data/signatures.json`（引用不复制，那边持续维护）

有崩溃签名 → 输出一行摘要：**崩溃类型 + fault 地址 + 顶部 1-3 个符号化栈帧 + 出现位置（行号）**。只做摘要，不展开根因分析。

无崩溃签名 → 如实说明（dmesg 里未见 HLOS 崩溃签名），并列出值得看的产物：`parser_out/` 下的 taskdump（各进程栈）、`smem` 相关输出、以及提示可能是 TZ/RMP 侧问题（dmesg_TZ 里只有 HLOS 视角）。

## 3.3 交棒

摘要输出后加一句交棒指引：

> 深度根因分析（栈回溯、反汇编、源码定位）交给 han-kernel-crash-analyzer——直接说「分析这个 ramdump」即可，parser_out 它会自动接手。

到此本 skill 职责完成。

## 3.4 新坑收录（轻自学习）

本次若踩到 `troubleshoot.md` 没覆盖的坑并解决了，追加到 `data/patterns.json` 的 `patterns` 数组（schema 见文件头注释）：

- `id`: ptrn-XXX 自增三位数
- `name` / `category` / `description`（症状 + 解法写一起，方便下次 grep）
- `confidence` 初始 1，`first_seen`/`last_seen` 填今天
- 同一个坑再次命中并解掉 → confidence+1、frequency+1、更新 last_seen

**所有步骤完成。如需重新执行，从 Step 0（`workflows/step-00-scenario.md`）开始。**
