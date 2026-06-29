# Step 0: 信息收集

交互式收集 Recovery 存储挂载失败场景的必要信息。

## 目标

确定问题范围：平台、日志、代码路径、失败现象。

## 指令

### 0.1 确认平台与环境

收集以下信息：
- **芯片平台**：如 Khaje/Bengal (SM6115)、Lahaina、Holi 等
- **Android 版本**：如 11/12/13/14
- **Recovery 模式**：标准 recovery 还是 fastbootd
- **存储介质**：U 盘 / SD 卡 / OTG 外接硬盘

### 0.2 收集故障日志

至少需要以下日志之一：
- **recovery 日志**：从 `/tmp/recovery.log` 或串口日志中的 recovery 部分
- **dmesg/logcat**：开机到 recovery 阶段的完整内核日志
- **SELinux avc 日志**：`adb shell dmesg | grep avc` 或 `audit2allow` 输出

如果用户提供了日志文件路径 → 读取并确认格式。
如果用户仅描述了现象没有日志 → 提示用户提供日志或通过串口/windows-remote 抓取。

### 0.3 确认代码路径

如果用户要进行代码级分析，需要确认：
- **Recovery 源码路径**：如 `bootable/recovery/`
- **内核源码路径**：如 `kernel/msm-5.4/`
- **设备配置路径**：如 `device/qcom/khaje/`

### 0.4 确认失败现象

明确记录：
- 挂载目标路径（如 `/udisk`、`/sdcard`）
- 错误信息（如 `No such file or directory`、`Invalid argument`）
- 是否插拔多次复现
- 是否特定 U 盘型号才有问题

### 0.5 输出收集摘要

收集完成后输出摘要，让用户确认：

```
## 收集摘要

- 平台: Khaje (SM6115)
- Android: 13
- 存储介质: U 盘 (SanDisk 32GB)
- 挂载点: /udisk
- 错误: mount: No such file or directory
- 日志: 已读取 recovery.txt (234 行)
- 代码路径: bootable/recovery/install/udisk_install.cpp
```

**完成后，读取 `workflows/step-01-log-analyze.md` 继续。**