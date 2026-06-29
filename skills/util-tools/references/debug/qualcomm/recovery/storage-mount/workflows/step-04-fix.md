# Step 4: 修复实施

根据根因分析报告，生成并实施修复方案。

## 目标

对每个根因产生修复代码，并通过 LSP 诊断验证。

## 指令

### 4.1 按优先级修复

按 P0 → P1 → P2 顺序逐一修复，每修复一项验证一项。

#### 修复 1：init.rc 添加挂载点（P0）

**操作**：
1. 搜索 `bootable/recovery/etc/init.rc` 中的 `on init` 或 `on fs` 阶段
2. 在 `mount` 相关指令附近添加：
   ```
   mkdir /udisk 0755 shell shell
   ```
3. 如果挂载点是 `/sdcard`，改为 `mkdir /sdcard 0755 shell shell`

**验证**：检查语法，确保不在注释块内。

#### 修复 2：udisk_install.cpp 添加设备等待逻辑（P0）

**操作步骤**：

1. 添加常量和超时宏：
```cpp
#define DEV_UDISK_BLK_PATH "/dev/block/sdg1"
#define UDISK_ROOT "/udisk"
#define USB_DEVICE_TIMEOUT 15
```

2. 在 `ApplyFromUDisk()` 开头添加设备等待循环：
```cpp
struct stat st;
int waited = 0;
while (stat(DEV_UDISK_BLK_PATH, &st) != 0 && waited < USB_DEVICE_TIMEOUT) {
    sleep(1);
    waited++;
}
if (waited >= USB_DEVICE_TIMEOUT) {
    // 超时处理
    return INSTALL_ERROR;
}
```

3. 设备就绪后添加块设备层稳定延时：
```cpp
sleep(2);  // 等待 VFS 层完成块设备初始化
```

4. 添加挂载点兜底创建：
```cpp
mkdir(UDISK_ROOT, 0755);  // 兜底，主路径已在 init.rc 创建
```

5. 执行挂载：
```cpp
if (mount(DEV_UDISK_BLK_PATH, UDISK_ROOT, "vfat", MS_NOATIME, NULL) != 0) {
    // 失败处理
    return INSTALL_ERROR;
}
```

**关键约束**：
- ❌ **不要**添加 `SetProperty("sys.usb.config", "none")` —— 触发 DWC3 reset
- ❌ **不要**手动写 `/sys/kernel/debug/dwc3` mode —— MSM 驱动自动处理
- ✅ stat() 轮询 OTG 枚举完成
- ✅ sleep(2) 等块设备层就绪

### 4.2 LSP 验证

每修复一个文件后立即运行：

```bash
lsp_diagnostics <修改的文件路径>
```

### 4.3 输出修复摘要

```
## 修复实施摘要

### 文件 1: bootable/recovery/etc/init.rc
- 变更: +1 行 (mkdir /udisk)
- 验证: LSP clean ✅

### 文件 2: bootable/recovery/install/udisk_install.cpp
- 变更: +18 行 (设备等待 + sleep + mkdir + mount)
- 验证: LSP clean ✅
```

**完成后，读取 `workflows/step-05-learn.md` 继续。**