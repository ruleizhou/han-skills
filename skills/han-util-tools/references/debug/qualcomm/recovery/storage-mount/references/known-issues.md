# Recovery 存储挂载已知问题库

## 问题 1：init.rc 缺少挂载点

### 现象
Recovery 模式下选择 "Apply update from U-Disk" 后，mount 报错：
```
mount: mounting /dev/block/sdg1 on /udisk failed: No such file or directory
```

### 根因
Recovery 的 `init.rc` 中没有 `mkdir /udisk` 指令，恢复进程无 rootfs 写权限，SELinux enforcing 下 mkdir 被拦截。

### 修复
在 `bootable/recovery/etc/init.rc` 的 `on fs` 阶段添加：
```
mkdir /udisk 0755 shell shell
```

### 适用平台
Qualcomm (通用)

---

## 问题 2：DWC3 DRD 竞态导致块设备消失

### 现象
U 盘插入后短暂出现 `/dev/block/sdg1`，几秒后消失，mount 时设备不存在。
dmesg 中可见：
```
[   14.xx] dwc3-msm 4e00000.ssusb: OTG mode
[   17.xx] xhci-hcd xhci-hcd.0.auto: remove, state 1
[   17.xx] xhci-hcd xhci-hcd.0.auto: Host halt failed, -19
```

### 根因
Recovery 启动时 `SetUsbConfig("adb")` 将 DWC3 从 host 切回 peripheral，与 OTG 的 host 检测竞态。DWC3 MSM 驱动在 `msm_dwc3_perf_vote_work` 中触发 reset。

### 修复
```cpp
// udisk_install.cpp 中 ApplyFromUDisk():
#define DEV_UDISK_BLK_PATH "/dev/block/sdg1"
#define UDISK_ROOT "/udisk"
#define USB_DEVICE_TIMEOUT 15

// 1. 等待 OTG 枚举完成
struct stat st;
for (int i = 0; i < USB_DEVICE_TIMEOUT; i++) {
    if (stat(DEV_UDISK_BLK_PATH, &st) == 0) break;
    sleep(1);
}

// 2. 等待 VFS 层完成块设备初始化
sleep(2);

// 3. 挂载点兜底
mkdir(UDISK_ROOT, 0755);

// 4. 挂载
mount(DEV_UDISK_BLK_PATH, UDISK_ROOT, "vfat", MS_NOATIME | MS_NODEV | MS_NODIRATIME, NULL);
```

**重要**：不要设置 `sys.usb.config=none`，这会触发 DWC3 reset 破坏枚举。

### 适用平台
Qualcomm Khaje/Bengal (SM6115)，可能影响其他使用 DWC3 + PM7250B PD PHY 的平台

---

## 问题 3：stat() 成功但 mount 失败

### 现象
stat() 返回成功（块设备 node 存在），sleep(1) 后 mount 仍失败：
```
mount: No such file or directory
```

### 根因
块设备 node 创建成功仅表示 udev 完成，但内核 VFS 层/块设备层的内部初始化（队列建立、分区表解析）还未完成。

### 修复
stat() 成功后额外 `sleep(2)` 等待 VFS 层就绪。

### 适用平台
Qualcomm (通用)

---

## 问题 4：SELinux enforcing 拦截 recovery 进程操作

### 现象
dmesg 中出现：
```
avc: denied { create } for name="udisk" dev="rootfs"
avc: denied { mounton } for path="/udisk"
```

SELinux permissive 模式下挂载成功，enforcing 下失败。

### 根因
Recovery 进程的 SELinux domain 没有在 rootfs 上创建目录和 mount 的权限。

### 修复（推荐方案）
不在 recovery 进程中创建挂载点和 mount，而是在 init.rc 中由 init 进程完成：

```
# init.rc (on fs)
mkdir /udisk 0755 shell shell
```

### 修复（备选方案）
如果需要 recovery 进程 mount，添加 SELinux 策略：
```
allow recovery rootfs:dir { create search add_name };
allow recovery udisk_file:dir { search mounton };
allow recovery device:blk_file { read write open };
```

### 适用平台
Qualcomm (通用)，Android 10+ SELinux 强制启用