---
name: usb-transfer-analyzer
description: >
  分析 Qualcomm 平台 USB Host 模式下的传输性能问题，特别是读写不对称（写比读慢）。
  触发条件：用户描述 USB 传输速度慢/读写不对称/OTG U盘性能问题，或提供了 logcat 日志要求分析 USB 传输性能。
  关键词：usb, U盘, OTG, 传输速度, 读写, copy, mass storage, dwc3, xhci, BOT, UAS.
---

# USB Transfer Analyzer

分析 Qualcomm 平台 USB Host 模式下的传输性能问题。

## 核心原则

1. **先数据后代码** — 日志优先，从 logcat 提取精确耗时后再看内核参数
2. **U 盘硬件优先排除** — 消费级 U 盘 NAND 写慢是常态，先验证是否硬件固有差异
3. **BOT 协议是主要瓶颈** — 写比读慢 2-4x 在 BOT 协议下属于正常范围
4. **交互不可跳过** — Step 0 的信息收集是唯一合法下一步

## 模式判断

| 触发信号 | 模式 | 动作 |
|----------|------|------|
| 用户描述 USB 传输速度/读写不对称问题 | 分析模式 | Step 0 → 1 → 2 → 3 → 4 → 5 → 6 |
| "问题解决了/修好了/搞定了/根因确认了" | 反馈闭环 | 读取 `workflows/feedback-loop.md` |

## 预检清单

- 是否有 logcat 日志？→ 没有则引导用户提供
- 是否有内核代码路径？→ 没有则仅做运行时参数检查
- 是否是纯知识问答（不需要实际调试）？→ 不应触发本 skill

## Workflow

本 skill 使用 7 步工作流（Step 0 ~ Step 6），按顺序执行。**每个步骤开始时，先 Read 对应的详细指令文件：**

| Step | 文件 | 做什么 |
|------|------|--------|
| 0 | `workflows/step-00-collect.md` | 收集问题描述和日志/代码路径 |
| 1 | `workflows/step-01-extract-timing.md` | 从 logcat 提取精确传输耗时 |
| 2 | `workflows/step-02-protocol-check.md` | 检查 BOT/UAS 协议和连接速度 |
| 3 | `workflows/step-03-kernel-params.md` | 检查内核可调参数 |
| 4 | `workflows/step-04-root-cause.md` | 五维分析 + 根因判据矩阵 |
| 5 | `workflows/step-05-fix.md` | 输出修复建议并等待验证 |
| 6 | `workflows/step-06-learn.md` | 自主学习与收录（新类型/新模式） |

**反馈闭环由用户主动触发（"搞定了/修好了"等），不在主流程中自动弹出。**

**开始分析时，首先读取 `workflows/step-00-collect.md`。**

## 参考资料速查

| 文件 | 用途 |
|------|------|
| `data/patterns.json` | 模式/经验库（置信度评分） |
| `data/cases/` | 历史案例存档 |
| `../kernel_platform/msm-kernel/drivers/usb/storage/scsiglue.c` | max_sectors/can_queue 定义 |
| `../kernel_platform/msm-kernel/drivers/usb/storage/transport.c` | SYNCHRONIZE_CACHE 处理 |
| `../kernel_platform/msm-kernel/drivers/usb/dwc3/dwc3-msm-core.c` | DWC3 U1/U2 配置 |
| `../kernel_platform/msm-kernel/drivers/usb/host/xhci-plat.c` | xhci IMOD 中断调节 |
