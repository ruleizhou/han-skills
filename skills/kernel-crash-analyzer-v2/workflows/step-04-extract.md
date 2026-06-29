# Step 4: 提取关键信息

**优先从 `dmesg_TZ.txt` 提取完整的 crash 信息。** `dmesg_TZ.txt` 是高通 ramdump 中最完整的内核日志，包含 kernel panic 全文、完整调用栈、CPU 寄存器快照、`Code:` 段内存指令 dump。如果当前目录或 `parser_out/` 中存在此文件，首选它作为 crash 信息源。

从 crash log 中逐项提取：

```
1. Fault address / virtual address → 定位具体哪条指令
2. PC (Program Counter) → 崩溃时的执行位置
3. LR (Link Register) → 调用者地址
4. Full call trace → 完整调用栈（按列出的每个函数追踪）
5. Process context → comm=, pid= 确定崩溃进程
6. CPU registers → x0-x30，特别关注包含指针值的寄存器
```

**提取顺序**：
1. **优先**：`dmesg_TZ.txt`（完整内核 crash log，一条龙拿到上述全部信息）
2. **次选**：`parser_out/` 下的 `*.log` 或 `*.txt` 文件
3. **补充**：其他 crash log 文件（如 `kasan.txt`、`reboot.txt`）

**完成后，读取 `workflows/step-05-disasm.md` 继续。**
