# Step 3: 根因定位

根据日志分析和代码检查的结果，定位根因并匹配已知模式。

## 目标

输出精确的根因结论，如有已知模式则引用。

## 指令

### 3.1 查询已知模式

先读取 `data/patterns.json`，尝试匹配当前问题与已知模式：

- 按关键词匹配 patterns.json 中的 `keywords` 字段
- 按平台匹配 `platform` 字段
- 按现象匹配 `category` 和 `description` 字段

如果有匹配的模式 → 引用模式 ID 和描述，加速分析。

### 3.2 根因分类

根据 Step 1 和 Step 2 的发现，将问题归类：

#### 类别 A：init.rc 挂载点缺失（最常见 ~40%）

**特征**：
- init.rc 中没有 `mkdir /udisk` 或类似指令
- mount 时报 `No such file or directory`
- 可能伴随 SELinux avc: denied { create }

**根因**：Recovery 进程无 rootfs 写权限，挂载点必须由 init 进程在启动时创建。

**修复模板**：
```
# 在 init.rc 的 on init 或 on fs 阶段添加：
mkdir /udisk 0755 shell shell
```

#### 类别 B：DWC3 DRD 模式竞态（常见 ~35%）

**特征**：
- dmesg 中看到 `dwc3` host→peripheral 或 peripheral→host 反复切换
- 看到 `xhci-hcd` remove/destroy 日志
- `/dev/block/sd[a-z][0-9]` 出现后又消失
- 通常与 ADB (sys.usb.config=adb) 并发启动有关

**根因**：Recovery 启动时 ADB 将 DWC3 切到 peripheral 模式，与 OTG 自动检测 U 盘需要的 host 模式竞态。写 `sys.usb.config=none` 会触发 UDC write → DWC3 reset → 破坏 Host 枚举。

**修复模板**：
```cpp
// udisk_install.cpp 中 ApplyFromUDisk() 内：
// 1. 等待设备就绪（15s 超时）
for (int i = 0; i < USB_DEVICE_TIMEOUT; i++) {
    if (stat(DEV_UDISK_BLK_PATH, &st) == 0) break;
    sleep(1);
}
// 2. 等待块设备层就绪
sleep(2);
// 3. 确保挂载点存在（兜底，主路径已在 init.rc 创建）
mkdir(UDISK_ROOT, 0755);
// 4. 挂载
mount(DEV_UDISK_BLK_PATH, UDISK_ROOT, "vfat", ...);
```

**DO NOT**: 不要在 udisk_install.cpp 中设置 `sys.usb.config=none` — 这会触发 DWC3 reset。

#### 类别 C：SELinux 拦截（常见 ~15%）

**特征**：
- dmesg 中有 `avc: denied` 日志
- mount 或 mkdir 报 `Permission denied`
- 通常在 SELinux enforcing 模式下出现

**根因**：recovery 进程的 SELinux domain 没有 mount/mkdir 权限，或目标路径的 context 不匹配。

**修复模板**：
- **优先方案**：让 init 进程创建挂载点（init.rc mkdir），避免 SELinux 策略修改
- **备选方案**：添加 SELinux 策略（如需要 recovery 进程 mount）：
  ```
  allow recovery udisk_file:dir { create search mounton };
  allow recovery device:blk_file { read write open };
  ```

#### 类别 D：块设备路径不固定（~10%）

**特征**：
- U 盘在不同情况下被分配不同设备名（sdg1 / sdh1 / sda1）
- 硬编码设备路径导致挂载失败

**根因**：内核块设备命名取决于枚举顺序，多 U 盘或多分区时路径不固定。

**修复模板**：
```cpp
// 动态查找块设备路径，而非硬编码 /dev/block/sdg1
```

### 3.3 输出根因报告

```
## 根因分析报告

### 问题归类
- 类别: [A] init.rc 挂载点缺失 + [B] DWC3 DRD 模式竞态
- 优先级: P0

### 直接根因
1. init.rc 缺少 mkdir /udisk 指令 → mount 报 ENONENT
2. DWC3 DRD 竞态 → XHCI destroy → /dev/block/sdg1 消失

### 已知模式匹配
- ptrn-001: Recovery init.rc 挂载点缺失 (confidence: 5)
- ptrn-003: DWC3 OTG 与 ADB peripheral 竞态 (confidence: 3)

### 修复方向
1. init.rc: 添加 mkdir /udisk
2. udisk_install.cpp: 添加设备等待 + sleep(2) + mkdir 兜底
3. 不写 sys.usb.config=none
```

**完成后，读取 `workflows/step-04-fix.md` 继续。**