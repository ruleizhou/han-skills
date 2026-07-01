# Step 1: 收集输入文件

**自动检测当前工作目录下的 crash 相关文件**，缺什么就用交互式提问补什么。

1. 检查用户消息中是否已明确提供了文件路径（`@parser_out`、`@symbols` 等）。
2. 扫描当前工作目录下的 crash 相关文件，**按优先级排列**：
   - **`dmesg_TZ.txt`** 最高优先级 — 高通 ramdump 中最完整的 crash 日志，包含 kernel panic 全文、调用栈、寄存器、`Code:` 内存指令转储，应作为 crash 信息的第一来源
   - `parser_out/` 目录 — 高通 ramdump 解析输出（`dmesg_TZ.txt` 通常在此目录或当前目录下）
   - `issues/<BugID>/artifacts/vmlinux` — 禅道/军师工作流下与 dump **Linux version 整行匹配** 的符号文件（见 `zentao-bug-log-fetch` § vmlinux 匹配）
   - `symbols/` 目录 — vmlinux/System.map 符号文件
   - `*.txt` 文件（如 `kasan.txt`、`reboot.txt`）— crash 日志文本
   - `*.log` 文件 — 内核日志/dmesg 输出
   - `*.json` 文件 — 解析元数据
3. **如有足够文件**：直接进入 Step 2。
3.5 **如无 dmesg_TZ.txt 但有 raw ramdump BIN + vmlinux**：检查 dump/ 目录含 DDRCS*.BIN 文件时 → 走crash直接解析路径：读取 workflows/crash-parse-raw.md → 从dump_info.txt取DDRCS物理映射 → 从OCIMEM.BIN取KASLR(0xdead4ead) → 拼接crash启动命令(优先从data/tool_cache.json读crash字段) → 启动crash执行sys/bt -a/log提取panic现场 → 写等效dmesg_TZ.txt → 回到主流程。
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

### vmlinux 匹配（禅道 / aosp-log-analysis-workspace 场景）

当分析路径为 `aosp-log-analysis-workspace/issues/<BugID>/` 时，**必须**遵守：

| 规则 | 说明 |
|:---|:---|
| **检索范围** | **仅** `aosp-log-analysis-workspace/` 内 `find -name vmlinux`；禁止全机扫描 |
| **匹配依据** | `DDRCS0_0.BIN` 的 `strings \| grep '^Linux version '` 与候选 vmlinux **整行 EXACT MATCH** |
| **禁止** | 按禅道 build 号、目录名、产品型号路径选 vmlinux |
| **落盘** | 目标串 → `artifacts/dump_linux_version.txt`；匹配 vmlinux → `artifacts/vmlinux` |
| **未匹配** | 标注待补充，不得用近邻 build 凑合 addr2line |

详细流程见 Skill **`zentao-bug-log-fetch`** §「vmlinux 匹配」。

**完成后，读取 `workflows/step-02-encoding.md` 继续。**
