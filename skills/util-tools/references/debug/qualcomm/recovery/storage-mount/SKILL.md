---
name: recovery-storage-mount
description: >
  分析 Qualcomm/Android 平台 Recovery 模式下 U 盘/SD 卡挂载失败问题。
  触发条件：用户报告 recovery 模式 U 盘挂载失败、mount 报 "No such file or directory"、
  recovery 日志显示 /udisk 或 /sdcard 挂载异常、OTG 模式下 DWC3 XHCI
  remove/destroy 日志。也支持反馈闭环：用户说"搞定了"/"修好了"/"问题解决了"
  时回顾历史案例、更新模式库。
  关键词：recovery, udisk, mount, otg, usb, storage, selinux, init.rc,
  No such file or directory, DWC3, XHCI, DRD
---

# Recovery 存储挂载调试器

分析 Recovery 模式下 U 盘/SD 卡挂载失败问题，覆盖 DWC3 OTG 模式冲突、init.rc 挂载点缺失、SELinux 拦截等常见根因。

## 核心原则

1. **先查 init.rc → 再查 USB 日志 → 最后看代码** — 70% 的挂载失败是 init.rc 缺少 mkdir 或 OTG 枚举未完成，不要一上来就改代码。
2. **DWC3 OTG 模式不需要手动切换** — MSM 驱动在 OTG 模式下由 extcon (PD PHY) 自动处理 Host/Peripheral 切换。用户态写 `dwc3_mode` 或 `sys.usb.config` **反而会破坏已有枚举**，是反作用。
3. **`stat()` 成功 ≠ 可 mount** — 块设备 node 存在不等于内核块设备层完成内部初始化，需要额外 `sleep(2)` 等 VFS 层完成。
4. **挂载点由 init 进程创建** — recovery 进程无 rootfs 写权限，SELinux enforcing 下 mkdir 会被拦截。挂载点必须在 init.rc 中声明。

## 模式判断

**先判断用户意图属于哪种模式**：

| 触发信号 | 模式 | 动作 |
|----------|------|------|
| recovery 挂载失败 / mount 报错 / U 盘不识别 / OTG USB 异常 | 分析模式 | Step 0 → Step 1 → Step 2 → Step 3 → Step 4 |
| 问题解决了 / 修好了 / 搞定了 / 根因确认了 / 不再复现 | 反馈闭环模式 | 跳过分析，直接读取 `workflows/feedback-loop.md` |

## 预检清单

在进入工作流之前快速判断：
- 用户是否提供了 recovery 日志？→ 可能跳过 Step 0 收集阶段，直接进入 Step 1
- 用户是否明确说了"init.rc 没问题"？→ 1/2 跳过后仍需验证
- 用户是否提到了 SELinux？→ 提前在 Step 3 关注 avc 日志
- 是否涉及 OTG USB 模式？→ 提前标记 DWC3 DRD 检查

## Workflow

本 skill 使用 6 步工作流（Step 0 ~ Step 5），按顺序执行。**每个步骤开始时，先 Read 对应的详细指令文件：**

| Step | 文件 | 做什么 |
|------|------|--------|
| 0 | `workflows/step-00-info-collect.md` | 收集恢复日志、代码路径、平台信息 |
| 1 | `workflows/step-01-log-analyze.md` | 分析日志：init.rc 挂载点、USB 枚举、SELinux avc |
| 2 | `workflows/step-02-code-check.md` | 检查源代码：udisk_install.cpp、init.rc、内核 USB 配置 |
| 3 | `workflows/step-03-root-cause.md` | 定位根因、匹配已知模式（patterns.json） |
| 4 | `workflows/step-04-fix.md` | 生成修复方案并实施 |
| 5 | `workflows/step-05-learn.md` | 收录新类型/场景到自学习库 |

**反馈闭环由用户主动触发，不在分析流程中自动弹出。触发后读取 `workflows/feedback-loop.md`。**

**开始分析时，首先读取 `workflows/step-00-info-collect.md`。**

## 参考资料速查

- 已知问题库：`references/known-issues.md`（已沉淀的常见挂载问题和修复模板）
- 自学习模式库：`data/patterns.json`（历史分析模式累积）
- 案例存档：`data/cases/`（JSON 格式，机器索引）