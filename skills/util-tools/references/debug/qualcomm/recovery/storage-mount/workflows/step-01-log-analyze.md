# Step 1: 日志分析

从收集到的日志中提取挂载失败的关键线索。

## 目标

从 recovery 日志、dmesg、SELinux avc 中定位失败原因。

## 指令

### 1.1 检查 init.rc 挂载点

在 recovery 日志中搜索：

```bash
grep -E "(mkdir|mount|/udisk|/sdcard|/mnt)" recovery.log
```

**判断标准**：
- 如果日志中**没有** `mkdir /udisk` 或类似指令 → **挂载点缺失**，跳至 1.4
- 如果 mkdir 存在但**失败**（如 `Permission denied`）→ **SELinux 拦截**，检查 1.3
- 如果 mkdir 和 mount 都没有执行 → **init.rc 未触发**，检查触发条件

### 1.2 检查 USB 枚举日志

在 dmesg 中搜索 USB 相关日志：

```bash
grep -E "(dwc3|xhci|usb|otg|mass.storage|sd[a-z][0-9])" dmesg.log
```

**关键检查点**（按时间顺序）：
1. **OTG 检测**：寻找 `otg`、`id_change`、`extcon` 日志 —— 确认 U 盘插入被检测到
2. **DWC3 模式**：寻找 `dwc3` mode switch 日志 —— 确认从 peripheral 切到 host
3. **XHCI 枚举**：寻找 `xhci`、`usb-storage`、`sdg1` 日志 —— 确认块设备创建
4. **XHCI destroy**：寻找 `xhci` remove/destroy 日志 —— 这是 DWC3 DRD 竞态的典型信号

**典型问题模式**：
- 日志显示 `xhci-hcd.0.auto` remove 后被 destroy → DWC3 DRD 竞态
- 日志显示 OTG 检测成功但无 `sd[a-z][0-9]` 出现 → 枚举失败
- 日志显示 `sd[a-z][0-9]` 出现后突然消失 → ADB peripheral 抢占

### 1.3 检查 SELinux avc 日志

```bash
grep -E "avc.*denied" dmesg.log
```

**典型被拦截操作**：
- `avc: denied { create } for name="udisk"` → init.rc 中 mkdir 被 SELinux 拦截
- `avc: denied { mounton }` → mount 操作被拦截
- `avc: denied { read write } for dev="sdg1"` → 块设备访问被拦截

### 1.4 输出分析摘要

按优先级排序问题：

```
## 日志分析摘要

1. [P0] 挂载点缺失: /udisk 未在 init.rc 中创建
2. [P0] DWC3 DRD 竞态: t=17s XHCI remove，与 ADB peripheral 冲突
3. [P1] SELinux avc: recovery 进程 mkdir 被拦截
```

**完成后，读取 `workflows/step-02-code-check.md` 继续。**