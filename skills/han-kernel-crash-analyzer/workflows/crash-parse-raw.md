# crash 直接解析 raw ramdump（无 parser_out 时的降级路径）

> 注：crash 有两个用途。本文件是**用途一**——无现成 dmesg 时降级生成等效 dmesg_TZ.txt。
> **用途二**：即使有 dmesg_TZ.txt，遇到内存破坏类问题（spinlock magic 坏 / 链表 cycle / UAF / SLUB redzone / 多结构损坏）也**必须**用 crash 做 `kmem`/`kmem -s`/`struct`/`search` 内存分析——python 读不出对象归属/边界/slab 健康度。详见 `references/tool_chain.md`「内存分析工具（crash）」档。

## ⚠️ 强制前置检查（所有 crash 使用场景，跳过即踩坑）

加载 crash 前**必须按序**完成，任一步跳过都会导致加载失败或 segfault：

1. **先读 `data/tool_cache.json`**：查当前工作区/源码路径是否已有 `crash` 字段（含 `verified_cmd`、`vabits_actual`、`kaslr_method`、`ddr_segments`）。**有就直接抄 `verified_cmd`，禁止改参数！**
2. **读本文件 C0/C1/C2**：物理映射拼接、KASLR 取法、启动命令。
3. **取 KASLR**：`OCIMEM.BIN` 搜 `0xdead4ead` magic，其后 u64 小端 = KASLR（**必须 2MB 对齐才合法**）。
4. **必带 `--kaslr=<offset>`**。**禁止**用 `--machdep kimage_voffset=<val>`（运行时值/链接基准值都会导致 segfault 或 `do not match`）。

> **血泪教训（SM6115 MC5612 elo/5# 案）**：跳过此检查，自创 `--machdep kimage_voffset=<val>` → crash 拿它翻译线性映射地址 → 算出非法物理 → **segfault（exit 139）**；或漏 `--kaslr` → `kimage_voffset cannot be determined` 直接退出。**`--kaslr` 是 rawdump+KASLR 唯一正确入口**——crash 8.0.4 对 rawdump 无 vmcore header，必须手动喂，别指望它自动推。

## 触发条件
- 存在 dump/ 目录含 DDRCS*.BIN
- 存在 vmlinux
- 不存在 parser_out/Small/dmesg_TZ.txt

## C0: 读物理地址映射
从 dump/dump_info.txt 提取 DDR CS Memo 行拼接 crash file@addr 对。
QCM6490 典型: DDRCS0_0.BIN@0x80000000,DDRCS0_1.BIN@0x100000000,DDRCS1_0.BIN@0x180000000,DDRCS1_1.BIN@0x200000000

## C1: 读 KASLR
python搜OCIMEM.BIN中0xdead4ead(magic),其后5字节小端=KASLR offset。

## C2: 启动 crash
crash vmlinux "${DDRCS_MAP}" --kaslr=${KASLR} --no_data_debug --machdep vabits_actual=39 --no_panic
参数: vabits_actual from tool_cache, --no_panic防read error退出

## C3: 提取并写入等效dmesg
crash命令: sys(内核版本), bt -a(调用栈), log(dmesg)
写入parser_out/Small/dmesg_TZ.txt

## C4: 继续step-02-encoding.md
