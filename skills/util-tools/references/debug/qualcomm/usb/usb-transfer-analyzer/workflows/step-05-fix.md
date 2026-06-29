# Step 5: 修复建议

## 目标

基于根因分析，给出分级修复建议并等待用户验证。

## 修复方案（按优先级）

### 1. 验证 U 盘自身性能（优先级：最高）

在 PC 上用 `fio` 或 CrystalDiskMark 测同一 U 盘：
```bash
# Linux PC
fio --name=test --filename=/dev/sdX --size=1G --rw=readwrite --bs=1M --direct=1
```
如果 PC 写入也是 40MB/s 左右 → U 盘自身限制，内核侧无需改动。

### 2. 增大传输粒度（优先级：高，立即生效）

```bash
echo 2048 > /sys/block/sdX/device/max_sectors
```
- 240 → 2048 将 I/O 次数减少 8.5 倍
- 减少 SYNCHRONIZE_CACHE 调用频率

### 3. 切换 I/O 调度器（优先级：中）

```bash
echo none > /sys/block/sdX/queue/scheduler
```
- 对于 U 盘这类设备，`none` (noop/mq-deadline) 比 `bfq` 更合适

### 4. 禁用 USB 自动挂起（优先级：中）

```bash
echo on > /sys/bus/usb/devices/<dev>/power/control
```
- 阻止 U1/U2 链路节能状态切换

### 5. 测试 SYNCHRONIZE_CACHE 开销（优先级：低，有风险）

仅用于性能测试，不建议生产使用：
```bash
# 格式: usb-storage.quirks=<vid>:<pid>:<flags>
# flag n = US_FL_NO_SYNCHRONIZE_CACHE
```
或在 `unusual_devs.h` 中为该 U 盘添加 quirk 条目。

### 6. 换用支持 UAS 的 U 盘（优先级：长期方案）

支持 UAS 的 U 盘（通常是 SSD 主控的高端型号）可同时改善读写性能。

## 输出格式

```
## 修复建议

| 优先级 | 方案 | 操作 | 预期效果 |
|--------|------|------|----------|
| 1 | PC 验证 | fio/CrystalDiskMark | 排除硬件差异 |
| 2 | 增大 max_sectors | echo 2048 > ... | 减少 I/O 碎片 |
| 3 | 切换调度器 | echo none > ... | 减少调度开销 |
| ... | ... | ... | ... |
```

## 等待验证

修复建议输出后，**等待用户反馈**。用户发出"搞定/修好/解决"信号时，进入反馈闭环。

---

完成后，读取 `workflows/step-06-learn.md` 继续。
