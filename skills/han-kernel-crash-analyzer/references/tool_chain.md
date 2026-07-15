# 工具链备忘

ARM64 反汇编工具链的使用备忘。具体缓存数据（按工作区）参见 `data/tool_cache.json`。

## 工具优先级

| 优先级 | 工具 | 检测方式 | 说明 |
|---|---|---|---|
| 1 | `aarch64-linux-gnu-objdump` | `which aarch64-linux-gnu-objdump` | ARM64 交叉工具链 |
| 2 | `llvm-objdump` | `which llvm-objdump` | LLVM 工具链，通常已安装 |
| 3 | `objdump` | `which objdump` | 系统自带，需验证支持 ARM64 |
| 4 | crash log 内嵌 `Code:` 行 | grep `Code:` | 高通 dmesg_TZ.txt 特有 |
| 5 | Python Capstone | `python3 -c "import capstone"` | 反汇编库 |
| 6 | ARM ARM 手动解码 | — | 最后手段 |

## 内存分析工具（crash）— 内存破坏类必用

**触发条件**：crash log 出现内存破坏签名——`spinlock bad magic`、链表 `List corrupted/cycle`、`SLUB redzone`、KASAN UAF/OOB、多个无关结构同时损坏——且 crash 工具可用（`data/tool_cache.json` 有 `crash` 字段，或 `which crash`）时，**必须** 启动 crash 做内存分析，不要只用 python 手动读内存。手动 python 读得出内存字节，但**读不出对象归属/边界/freelist/slab 健康度**——而这些正是定位破坏源的关键。

> 铁律延伸：SKILL.md「反汇编之前不得给根因」→ **内存破坏类在 crash `kmem`/`kmem -s`/`search` 分析之前，不得轻易下「破坏源未定位」就收尾**。

### 启动命令（严格按 `workflows/crash-parse-raw.md` C0/C1/C2，别手拼漏参数）

```bash
crash <vmlinux> "<DDRCS0_0.BIN@phys0>,<DDRCS0_1.BIN@phys1>" \
  --kaslr=<从OCIMEM 0xdead4ead读出的偏移> --no_data_debug --machdep vabits_actual=39 --no_panic
```

- **必带 `--kaslr=<值>`**，否则报 `kimage_voffset cannot be determined` 直接退出。
- DDR phys 段从 `dump_info.txt` 的 `DDR CS* Memo` 行拼（如 `DDRCS0_0.BIN@0x40000000`）。
- kaslr 从 `OCIMEM.BIN` 搜 `0xdead4ead` magic，其后 u64 小端即偏移（**必须 2MB 对齐才合法**）。
- vabits_actual / extra_flags 从 `data/tool_cache.json` 对应工作区读。

### 核心命令（python 做不到的，全在这）

| 命令 | 作用 |
|---|---|
| `kmem <addr>` | 地址所属 slab cache + **对象边界** + freelist（判断活/UAF/越界方向） |
| `kmem -s <cache>` | slab cache 健康度 + 红区损坏 |
| `struct <type> <addr>` | 用**正确 DWARF 布局**解析对象字段（别手动猜偏移，含 dep_map 会错位） |
| `search -p <pattern>` | 全物理内存搜破坏指纹（如改坏的 magic 值）分布，看是否周期性→越界 |

### 已知坑

- `CONFIG_KASAN_HW_TAGS` 需 MTE 硬件，无 MTE 则运行时不激活——不能靠「无 KASAN 报告」推断无 UAF；要抓写入者改用 `CONFIG_KASAN_GENERIC`。
- 符号定位优先用 ramparse 自带符号化栈（它用正确 kaslr），别手动算地址喂 symbolizer（易错位巧合命中）。

## vmlinux 格式处理

- **PIE (shared object)**：ARM64 内核 vmlinux 常见格式，objdump 可正常处理，但 `nm` 可能返回空
- **符号表缺失**：检查 `SymbolTable/` 独立目录，或使用 `readelf -s vmlinux`
- **Section 检查**：`readelf -S vmlinux | grep -E "\.text|\.symtab"`

## 安装命令参考

```bash
# ARM64 交叉工具链 (Ubuntu/Debian)
sudo apt install binutils-aarch64-linux-gnu

# LLVM 工具链
sudo apt install llvm

# Python Capstone
pip3 install capstone
```
