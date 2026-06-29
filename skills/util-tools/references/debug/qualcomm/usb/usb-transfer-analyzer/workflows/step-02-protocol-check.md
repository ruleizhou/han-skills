# Step 2: 检查传输协议

## 目标

判断当前连接使用的传输协议（BOT vs UAS）和 USB 速度等级。

## 流程

### 2.1 运行时检查（设备端命令）

```bash
lsusb -t                          # 查看 USB 设备树，确认 UAS 还是 usb-storage
cat /sys/bus/usb/devices/<dev>/speed   # USB 速度等级 (5000=SuperSpeed, 480=HighSpeed)
```

### 2.2 内核配置检查（代码端）

```bash
grep "CONFIG_USB_UAS" <kernel_path>/arch/arm64/configs/*defconfig*
```

### 2.3 协议对比

| 特性 | BOT (Bulk-Only Transport) | UAS (USB Attached SCSI) |
|------|--------------------------|------------------------|
| 命令队列 | `can_queue=1` (串行) | 支持多命令并发 |
| 数据通道 | 共享 bulk 端点 | 独立 Data-In/Data-Out 管道 |
| 写后缓存刷新 | SYNCHRONIZE_CACHE 阻塞 | 异步/更高效 |
| 写性能影响 | **大** (每次写后阻塞) | 小 |
| 典型速度 | 读 80-150, 写 20-50 MB/s | 读 200-400, 写 100-200 MB/s |

### 2.4 判断结论

- **UAS 模式**：命令队列可用，但部分 U 盘实现有 bug（`US_FL_BROKEN_FUA` 等）
- **BOT 模式**：这是消费级 U 盘最常见的情况，写慢主要受 `SYNCHRONIZE_CACHE` 和 `can_queue=1` 限制

---

完成后，读取 `workflows/step-03-kernel-params.md` 继续。
