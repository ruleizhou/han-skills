# Crash 类型专项指南

每种 crash 类型的详细分析策略、常见误区和案例。

## NULL Pointer Dereference

### 识别特征
```
Unable to handle kernel NULL pointer dereference at virtual address 000000000000005f
```

### Fault Address 解读

| FA 范围 | 含义 |
|---------|------|
| `0x0` ~ `0xFFF` | 接近空指针，通常是真的 NULL 传给了解引用 |
| `0x5f`、`0xa1` 等 | 小偏移 → 结构体成员偏移，指针来自 ERR_PTR(-Exxx)，例如 `PTR_ERR(-EEXIST)` |
| 大地址  | `0xdead`... 之类的毒药值，通常是已释放内存 |

### 分析方法
1. 确认 fault address 的十进制值
2. 若 < 0xFFF，检查 ERR_PTR 转换：`IS_ERR()` 返回 true 但代码路径却当作成功继续执行
3. 若 > 0xFFF，反汇编确认是哪条 load/store 指令，算偏移量
4. 追踪寄存器值：load 指令的基址寄存器值从哪来？

### 常见模式
- 函数返回 `ERR_PTR(-EEXIST)`，调用者检查 `IS_ERR()` 失败
- probe 失败路径中 `goto err_xxx` 跳过了必要的初始化
- 设备树属性缺失导致指针未赋值

---

## KASAN Use-After-Free

### 识别特征
```
KASAN: use-after-free in <function>
```

### 分析方法
1. KASAN 报告包含**两套调用栈**：
   - `alloc` 栈：对象是何时、通过哪个调用链分配的
   - `free` 栈：对象是何时、通过哪个调用链释放的
2. 将两个调用栈并排对比，找时间窗口
3. 阅读 free 和 use 之间的代码，确认是否有并发释放的可能
4. 检查 `kfree()` 后是否缺少 `ptr = NULL`

### 常见模式
- 驱动 remove/probe 失败路径释放了结构体，但 workqueue/timer 还持有引用
- 设备注销时 `device_destroy()` 后还有线程在 open() 回调中
- 中断处理函数访问了已释放的设备私有数据

---

## SLUB Redzone 损坏

### 识别特征
```
SLUB: Unable to allocate memory on node -1
Redzone: ddb6e53f
```

### 分析方法
1. 查看被破坏对象的地址和所属 slab cache（`/proc/slabinfo`）
2. 读取 `/sys/kernel/debug/slab/<cache>/alloc_calls` 和 `free_calls`
3. 红区损坏意味着**相邻对象越界写入**，不是目标对象本身的问题
4. 找出红区被修改的字节模式（如 `0x00` 覆盖了 `0xcc`）

### 常见模式
- 相邻对象的 `memset` 越界
- 使用 `sizeof(wrong_struct)` 进行了内存分配
- IIO/SPMI 设备在完全初始化之前被注册到子系统

---

## ABBA 死锁

### 识别特征
系统 hang、watchdog 超时、或无明确 panic 的卡死。

### 分析方法
1. 从 crash dump 或 `sysrq-t` 获取所有线程的 backtrace
2. 找到所有 `mutex_lock` 调用，画出锁获取的顺序图
3. 寻找路径 A：`mutex_lock(L1)` → `mutex_lock(L2)` 和 路径 B：`mutex_lock(L2)` → `mutex_lock(L1)`
4. **特别关注错误路径中的锁释放**：正常路径可能顺序正确，但 goto 错误处理中漏了 unlock

### 常见模式
```
线程 1 (open):          线程 2 (错误处理/复位):
  mutex_lock(&dev->lock)   mutex_lock(&spi->lock)
  mutex_lock(&spi->lock)   mutex_lock(&dev->lock)
  ...                       → ABBA deadlock!
```

---

## Kernel Panic (通用)

### panic_on_taint 分析
```
Kernel panic - not syncing: panic_on_taint set ...
```
1. 先找 taint 来源：`Tainted: G W ...`
2. `G` = GPL 污染，`W` = warning，`B` = bad page，等等
3. taint 本身不是根因，是 symptom——在 log 中搜索 taint 前最近的 BUG/WARNING/Oops
4. 用那个 BUG/WARNING 的信息继续追踪

---

## DRAM SEU / 单 bit 翻转（极易误判为软件内存破坏）

### 识别特征
- Oops/panic 解引用一个"看着像野值"的指针，但指针值**整齐落在某编译期常量基址**（如 arm64 `vmemmap` 变量、`PAGE_OFFSET`）或其 ±2^k 偏移处
- 同一压测/场景多次复现，但每次 KASLR 不同 → 物理地址飘移
- `CONFIG_KASAN` 开了却**无任何 KASAN 报告**（SEU 非 OOB/UAF，KASAN 抓不到；若开的是 KASAN_HW_TAGS 且 CPU 无 MTE，更是全程不激活）
- live slab 对象（crash `kmem` 显示 ALLOCATED + refcount>0）的字段值被改，但对象本身没被 free

### Fault Address / 指针解读（决定是否误判的关键）
1. **先算"期望值"**：被解引用的指针合法值应是什么？（如 `f_mapping` 应 = `&inode->i_data`；`page` 应 = `vmemmap + pfn×sizeof(struct page)`）
2. **XOR popcount=1 → 单 bit 翻转铁证**：`python3 -c "print(bin(合法^实际).count('1'))"`，结果为 1 即 SEU
3. **勿把"不在有效映射区"等同于"纯随机 garbage"**——arm64 `vmemmap` C 变量 ≠ `VMEMMAP_START`！
   - 公式：`vmemmap = VMEMMAP_START − (memstart_addr>>PAGE_SHIFT)×sizeof(struct page)`（详见 platform_quirks.md）
   - pfn=0 的 page 结构 = vmemmap 基址，因物理 0 无 RAM 而**未映射** → crash `kmem` 报 "not in mem map"，但它不是 garbage，是**合法 pfn 经 SEU 翻转后落到的精确基址**
   - 合法 pfn 若恰好是 2 的幂（如 `min_low_pfn = memstart_pfn = 0x40000 = 2^18`），翻其唯一置位 bit → pfn=0 → page=vmemmap 基址

### 分析方法
1. 对每个"野指针"，用 crash `kmem <ptr>` + `struct <type> <ptr>` 核验：对象是否 live（ALLOCATED+refcount>0）？字段值是否=期望值±1bit？
2. 对 page 指针，**先算 `vmemmap` C 变量基址**（见 platform_quirks 公式），看野 page 是否=该基址或其 2^k 偏移；别只看"在不在 vmemmap 区"
3. 抠翻转 bit：跨样本一致性判硬件类型（bit 固定+地址飘移=位线 DQ 缺陷；PA 固定=marginal cell；随机=纯 SEU 考虑 ECC）
4. **不上 KASAN**（抓不到单 bit）；走 memtester / DDR retrain / ECC log / RMA

### 常见误判（本类型最大坑）
- ❌ "crash kmem 报 not in mem map → 纯随机 garbage → 软件 UAF/OOB" —— 错，可能是 vmemmap 基址（pfn=0 未映射）
- ❌ "指针离有效区差太多 bit → 非 SEU" —— 错，差的是 pfn 域的 bit，换算到 page 柄域放大 sizeof(page)=64 倍，看着"差很多"实则 pfn 单 bit
- ❌ "KASAN 没报 → 排除内存破坏" —— 错，KASAN_HW_TAGS 无 MTE 不激活；即便 KASAN_GENERIC 也只抓 OOB/UAF 不抓 SEU
- ✅ 同平台多次 SEU（不同 bit/不同目标）→ DRAM 位线/cell 缺陷，软件无 bug，走硬件 RAS

> 沉淀来源：MC5612/SM6115 reboot 压测 smaps_rollup 死机（5# PTE.pfn bit18 + 6# file->f_mapping bit52），详见 data/cases sm6115-mc5612 + patterns ptrn-008

---
