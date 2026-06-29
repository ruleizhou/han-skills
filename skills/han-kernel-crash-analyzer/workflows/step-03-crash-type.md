# Step 3: 识别 crash 类型

扫描 crash log 中的关键签名，确定分析策略。

## 签名匹配优先级

1. **优先查询 `data/signatures.json`**：先检查自学习累积的签名库，可能有比硬编码表更新的条目
2. **再匹配硬编码签名表**（`references/signature_table.md`）：
3. **模糊匹配**：当精确字符串匹配失败时：
   - 搜索 `CPU: <n> PID:` 获取崩溃进程上下文
   - 如果存在有效调用栈但无已知签名，按"通用 crash"处理
   - 如果存在 `Code:` 行且有可读 ARM64 指令，提取反汇编
   - 如果日志混合多种 crash 类型（如 KASAN 报告中的 NULL 指针），报告两者——第一个通常是根因
4. **全部失败**：记录为 `unknown-<异常字符串前 100 字符>`，继续走通用流程，分析结束后 Step 10 会提示收录

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

**如果 `[未知类型]`**：上述签名均不匹配时，不影响继续分析。从 crash log 中提取异常指令/BUG 字符串作为临时类型名，按通用 crash 流程走完 Step 4-9。分析结束后自动触发 Step 10 提示用户确认是否收录。

**完成后，读取 `workflows/step-04-extract.md` 继续。**
