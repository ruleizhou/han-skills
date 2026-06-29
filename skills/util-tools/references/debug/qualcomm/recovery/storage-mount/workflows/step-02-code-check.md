# Step 2: 代码检查

检查 Recovery 挂载相关的源代码，确认代码层面是否存在问题。

## 目标

定位源代码中与日志分析结果对应的代码缺陷。

## 指令

### 2.1 检查 init.rc

搜索并读取 recovery 的 `init.rc`：

```bash
# 通常在这些路径
bootable/recovery/etc/init.rc
device/qcom/<platform>/init.recovery.rc
```

**检查项**：
- [ ] 是否有 `mkdir /udisk 0755 shell shell`（或类似挂载点创建）？
- [ ] 是否有 `mount` 相关的 service 定义？
- [ ] SELinux context 是否正确（`u:object_r:...`）？

**如果没有 mkdir → 这是根因之一，记录为 P0。**

### 2.2 检查 udisk_install.cpp（或等效的挂载代码）

搜索挂载实现代码：

```bash
grep -r "ApplyFromUDisk\|ApplyFromSdCard\|mount.*udisk\|mount.*sdcard" bootable/recovery/
```

读取挂载函数，检查：

- [ ] 挂载前是否有**设备就绪检查**（如 `stat()` 轮询）？
- [ ] 挂载前是否有**挂载点存在检查**？
- [ ] 是否有**延时等待**（如 `sleep(2)`）等块设备层就绪？
- [ ] 是否有**错误处理**（mount 失败的重试逻辑）？

**典型代码缺陷**：
```cpp
// ❌ 问题代码：没有任何准备逻辑
int ApplyFromUDisk() {
    return mount("/dev/block/sdg1", "/udisk", "vfat", ...);
}
```

### 2.3 检查内核 USB 配置

搜索内核 defconfig：

```bash
grep -E "CONFIG_USB_DWC3|CONFIG_USB_GADGET|CONFIG_USB_XHCI" kernel/**/<platform>_defconfig
```

**关键配置**：
- `CONFIG_USB_DWC3_MSM=y` — MSM DWC3 驱动（OTG 自动切换依赖此项）
- `CONFIG_USB_DWC3_DUAL_ROLE=y` — DRD (Dual Role Device) 支持
- `CONFIG_USB_CONFIGFS_F_FS=y` — FunctionFS（ADB 用）

如果 DWC3 配置为 `=m`（模块）→ 模块加载时序可能影响 OTG。

### 2.4 输出代码检查摘要

```
## 代码检查摘要

### init.rc
- [FAIL] 缺少 mkdir /udisk → P0 修复

### udisk_install.cpp
- [FAIL] 无设备就绪检查
- [FAIL] 无挂载点存在检查
- [FAIL] 无延时等待

### 内核配置
- [PASS] CONFIG_USB_DWC3_MSM=y
- [PASS] CONFIG_USB_DWC3_DUAL_ROLE=y
```

**完成后，读取 `workflows/step-03-root-cause.md` 继续。**