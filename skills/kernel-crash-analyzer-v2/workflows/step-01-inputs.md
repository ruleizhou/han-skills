# Step 1: 收集输入文件

**自动检测当前工作目录下的 crash 相关文件**，缺什么就用交互式提问补什么。

1. 检查用户消息中是否已明确提供了文件路径（`@parser_out`、`@symbols` 等）。
2. 扫描当前工作目录下的 crash 相关文件，**按优先级排列**：
   - **`dmesg_TZ.txt`** 最高优先级 — 高通 ramdump 中最完整的 crash 日志，包含 kernel panic 全文、调用栈、寄存器、`Code:` 内存指令转储，应作为 crash 信息的第一来源
   - `parser_out/` 目录 — 高通 ramdump 解析输出（`dmesg_TZ.txt` 通常在此目录或当前目录下）
   - `symbols/` 目录 — vmlinux/System.map 符号文件
   - `*.txt` 文件（如 `kasan.txt`、`reboot.txt`）— crash 日志文本
   - `*.log` 文件 — 内核日志/dmesg 输出
   - `*.json` 文件 — 解析元数据
3. **如有足够文件**：直接进入 Step 2。
4. **如缺少关键文件**：使用 `AskUserQuestion` 弹出交互式提问，收集缺失的输入。

`AskUserQuestion` 示例：
```
question: "需要哪些 crash 分析输入？"
header: "输入"
options:
  - label: "parser_out + symbols + 代码路径"
    description: "高通 ramdump 三件套，最常见"
  - label: "只有 crash log (txt/log)"
    description: "dmesg、KASAN 报告、kernel panic log 等"
  - label: "只有 symbols + 代码路径"
    description: "已有 crash 信息，需要反汇编分析"
```

无论如何，最终必须拿到三个核心输入：
- **Crash 现场**：`dmesg_TZ.txt` > parser_out/ > 其他 crash log 文件
- **符号文件**：vmlinux 或 System.map（用于 objdump）
- **内核代码路径**：对应的内核源码树（Step 0 已收集）

**完成后，读取 `workflows/step-02-encoding.md` 继续。**
