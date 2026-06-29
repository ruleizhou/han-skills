# Step 2: 检测文件编码和格式

**在读取任何 crash log 内容之前，必须先确定文件格式。**

```bash
file <log_path>
```

Android/高通平台的 crash log 常见格式：

| `file` 输出 | 含义 | 处理方式 |
|---|---|---|
| `UTF-16LE Unicode text, with CRLF` | Android event log | `iconv -f UTF-16LE -t UTF-8` 转换后再分析 |
| `ASCII text` / `UTF-8 text` | 标准文本 | 直接读取 |
| `data` | 未知编码/二进制 | 用 `head -c 200` 查看前几个字节判断编码，尝试 `iconv -f UTF-16LE` |
| `ELF 64-bit LSB shared object, ARM aarch64` | vmlinux (PIE 格式) | 参见 Step 5 的反汇编注意事项 |

**文件内容类型检测** — 文件名可能有误导性（如 `kasan.txt` 实际是 XBL boot log）：

1. 用 `head -50` 和 `tail -50` 快速浏览文件头和尾
2. 判断文件是**纯 crash 报告**还是**混合日志**（如 bootloader + kernel + crash 混在一起）
3. 如果是混合日志：定位 crash 相关段落的行号范围（`grep -n "KASAN\|BUG:\|panic\|Unable to handle"`），只分析相关段落
4. 在输出中明确告知用户文件实际格式（"该文件是 XBL Core boot log，KASAN 报告仅位于 L2030-L2042"）

**完成后，读取 `workflows/step-03-crash-type.md` 继续。**
