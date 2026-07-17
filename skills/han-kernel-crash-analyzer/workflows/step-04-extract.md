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

## 铁律：调用栈必须读完整，不能只凭单帧 PC 下结论

- 优先用 ramparse 的 `current callstack` section（`dmesg_TZ.txt` 中各 CPU 的完整栈，从 syscall 到卡死点全链路）或 crash 的 `bt`。
- **单帧 PC 往往只是受害者**：卡在 `__delay`/`printk`/`udelay`/`hub_thread` 这类"工具人"函数时，真正肇事者在栈更上层。本案例曾只看 PC（`__delay`）误判根因为 perf_event，读完整栈才发现真实路径 `connect → unix_stream_connect → copy_peercred → do_raw_spin_lock`。
- 内存破坏类的"坏对象/坏锁"现场几乎都是**受害者**，肇事者要靠完整栈 + `crash kmem` 反推（见 `references/tool_chain.md` 内存分析档）。

## SLUB overwrite 专项提取（脚本加速）

检测到 SLUB 签名（`Object padding overwritten` / `Poison overwritten` / `SLUB: redzone`，见 `data/signatures.json`）时，直接调脚本自动提取事件 + 算 PA + 判软硬，**对齐 patterns.json ptrn-007**：

```bash
python3 scripts/slub_pa_extract.py <串口log/dmesg_TZ> [<log2> ...]
# 跨平台/设备：--va-bits 39|48  --phys-offset 0x...  --dma-region NAME:LO:HI
# 回写知识库：--json（对齐 cases/*.json 的 two_sample_evidence）
```

脚本输出每个事件的 cache/损坏VA/PA/bit翻转/红区完整性/alloc-free 栈，并按 **红区完整 + bit 跨样本一致 + 物理区域聚集 → DRAM SEU** 给出软硬 verdict（红区被踩→CPU软件嫌疑；PA落DMA区→DMA stray write；单事件→提示攒样本）。

**职责边界**：脚本只做启发式倾向，**对象边界 / freelist / slab 健康度仍必须用 `crash kmem` / `kmem -s` 复核**（tool_chain.md 铁律）。脚本不替代 crash，是 step-4 的前置加速器。

**提取顺序**：
1. **优先**：`dmesg_TZ.txt`（完整内核 crash log，一条龙拿到上述全部信息）
2. **次选**：`parser_out/` 下的 `*.log` 或 `*.txt` 文件
3. **补充**：其他 crash log 文件（如 `kasan.txt`、`reboot.txt`）

**完成后，读取 `workflows/step-05-disasm.md` 继续。**
