# 崩溃类型签名表

硬编码签名匹配表。运行时优先查询 `data/signatures.json`（自学习累积），此表作为回退。

| Crash 签名 | 类型 | 分析重点 |
|---|---|---|
| `Unable to handle kernel NULL pointer dereference at virtual address` | NULL 指针解引用 | 检查 ERR_PTR 转换、错误路径返回 |
| `KASAN: use-after-free` | KASAN UAF | 追踪 alloc/free 时间线、竞态条件 |
| `KASAN: slab-out-of-bounds` | KASAN OOB | 检查数组边界、结构体大小变化 |
| `SLUB: redzone` | SLUB 红区损坏 | 检查相邻对象越界写入 |
| `Kernel panic - not syncing: panic_on_taint` | Taint 触发 panic | 先找 taint 来源，再追根因 |
| `Kernel panic - not syncing: Oops` | Oops 转 panic | 从 oops 信息逆向追踪 |
| `BUG: scheduling while atomic` | 原子上下文调度 | 检查 mutex/sleep 调用路径 |
| mutex 交叉持有模式 | ABBA 死锁 | 画锁依赖图，检查错误路径 |
| `No explicit kernel panic; CPU hung in DebugImage` | 无 panic 签名的 hang | 从 DebugImage CPU 上下文定位卡死指令，追中断前上下文，检查 shutdown/电源时序 |
| `Panicking, remoteproc .* crashed` | 子系统(remoteproc) crash 触发 HLOS 主动 panic | ramparse CheckForPanic 可能漏检→grep 全文；查 esr_el1 区分主动 panic vs 内存 fault；读 fatal 原文找子系统诱因；HLOS 无 bug 勿改 q6v5 crash handler |
| `qcom_q6v5_pas.*fatal error received:` | 子系统 ERR_FATAL → SSR → panic | fatal 消息含子系统 file:line+诱因；核查 NV/QCN 校准数据是否缺失；确认目标版本 crash 策略(panic+dump vs SSR) |
| `Object padding overwritten` | SLUB padding 损坏(疑 DRAM SEU/位线) | 红区(0xbb)完整→排除 CPU 线性越界/UAF；翻转 bit 跨样本一致+地址飘移=DRAM 位线/SEU；损坏在静态 padding 区=SEU 易暴露处；查 panic_on_taint=0x20 放大；无 MTE 平台 KASAN_HW_TAGS 未启用(详见 patterns ptrn-007) |
| `Poison overwritten` | SLUB poison 损坏(疑 DRAM SEU/位线) | 红区完整+翻转 bit 跨样本一致+free 对象静态 poison 区→DRAM SEU；alloc/free 栈每次不同=非特定代码 bug；查 panic_on_taint 放大 |
