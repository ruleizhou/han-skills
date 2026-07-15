# crash 直接解析 raw ramdump（无 parser_out 时的降级路径）

> 注：crash 有两个用途。本文件是**用途一**——无现成 dmesg 时降级生成等效 dmesg_TZ.txt。
> **用途二**：即使有 dmesg_TZ.txt，遇到内存破坏类问题（spinlock magic 坏 / 链表 cycle / UAF / SLUB redzone / 多结构损坏）也**必须**用 crash 做 `kmem`/`kmem -s`/`struct`/`search` 内存分析——python 读不出对象归属/边界/slab 健康度。详见 `references/tool_chain.md`「内存分析工具（crash）」档。

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
