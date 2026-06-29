# Step 3: 检查内核参数

## 目标

检查 USB 存储和主机控制器驱动中的关键性能参数。

## 流程

### 3.1 运行时参数检查

```bash
# 单次 I/O 大小限制 (BOT 默认 240 扇区 = 120KB)
cat /sys/block/sdX/device/max_sectors

# 硬件最大 I/O 大小 (USB 3.0 可达 2048 扇区 = 1MB)
cat /sys/block/sdX/queue/max_hw_sectors_kb

# I/O 调度器
cat /sys/block/sdX/queue/scheduler

# USB 自动挂起状态
cat /sys/bus/usb/devices/<dev>/power/control
```

### 3.2 代码端关键参数

如果用户提供了内核代码路径，检查以下文件：

| 参数 | 文件:行号 | 默认值 | 对写性能的影响 |
|------|----------|--------|---------------|
| `max_sectors` | `scsiglue.c:661` | **240 (120KB)** | 决定每次 I/O 命令的数据量，偏小 → 更多 SYNCHRONIZE_CACHE 调用 |
| `max_hw_sectors` (USB3) | `scsiglue.c:122` | 2048 (1MB) | 硬件上限，但被上层 max_sectors 限制 |
| `can_queue` | `scsiglue.c:631` | **1** | BOT 协议下同时仅 1 个命令，无法流水线 |
| `SYNCHRONIZE_CACHE` | `transport.c:661` | 每次写后执行 | 强制刷 U 盘缓存，一次 100-500ms |
| `imod_interval` | `xhci-plat.c:312` | 40000ns (40us) | 中断调节间隔，影响 I/O 完成延迟 |
| U1/U2 节能 | `dwc3-msm-core.c:3186` | 开启 | 链路状态切换延迟，写操作更敏感 |

### 3.3 参数影响分析

**max_sectors = 120KB 的影响**：
- 1GB 写入需要 ~8533 次 I/O 命令
- 每次命令后发 SYNCHRONIZE_CACHE
- 如果 U 盘每次缓存刷新 ≥ 3ms → 总刷新开销 ≥ 25 秒
- 提升到 1MB → 只需 1024 次命令 → 刷新开销降至 ~3 秒

---

完成后，读取 `workflows/step-04-root-cause.md` 继续。
