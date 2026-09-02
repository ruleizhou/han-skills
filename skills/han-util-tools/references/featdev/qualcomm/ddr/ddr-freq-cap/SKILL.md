---
name: ddr-freq-cap
description: >
  Qualcomm 平台（RPM 架构）调整 DDR 训练/运行频率上限的跨固件改动指导。当用户提到
  DDR 降频、降低训练频率、训练上限、DDR max frequency、clock plan cap、
  ddr_num_clock_levels、band7/band6 降档、1804800/2092800、DDR 频率天花板、
  换 DDR 颗粒降规格、SMEM clock_plan 修改时触发。覆盖 XBL/RPM/Kernel 三层联动
  改动清单、降频后死机（kernel 数据腐烂/卡 RPM ACK/训练 ABORT）指纹判别。
  反馈闭环：能开机了/降频生效了/验证通过了。
  边界：训练 ABORT/错误码 84/small_eye 阈值调优 → debug/ddr/ddr-training-debug；
  kernel 代码级崩溃 → han-kernel-crash-analyzer；无 dump 重启 → qualcomm-reboot-analyzer。
---

# DDR Freq Cap（DDR 频率上限跨固件调整）

高通 RPM 架构平台（无 AOP）主动调整 DDR 训练/运行频率上限的完整改动指导。核心事实：**SMEM 共享数据（clock_plan/训练数据）是跨固件 ABI，XBL/RPM/Kernel 三层必须一致变更**，任何单边修改都会以 kernel 阶段 DDR 数据腐烂的形式炸出来。

## 核心原则

1. **三层联动不可拆** — XBL 训练上限、RPM 切频钳位、Kernel 投票上限必须同代际联刷，缺一层必死
2. **先基线后实验** — 任何降频改动前，先刷基线确认环境健康（排除"本来就有病"）
3. **SMEM 是 ABI** — 共享表结构/索引任何字段变化都是跨固件事件，不是 XBL 内部事务
4. **改 RPM 必验产物** — RPM 有平台独立源码副本，改完必须反汇编确认改的是编译产物
5. **成果必须沉淀** — 案例存 data/cases/，更新 patterns.json

## 模式判断

| 触发信号 | 模式 | 动作 |
|----------|------|------|
| 降频/训练上限/clock plan/band 降档/频率天花板 | 改动指导 | Step 0 → 1 → 2 → 3 → 4 → 5 → 6 |
| 降频后死机/数据腐烂/卡 RPM ACK（已有 dump 或 log） | 排障分诊 | Step 1 指纹三态分诊 + references/fingerprint-library.md |
| 能开机了/降频生效了/验证通过了 | 反馈闭环 | workflows/feedback-loop.md |
| 训练 ABORT/错误码 84/small_eye/眼图阈值调优 | 转交 | debug/qualcomm/ddr/ddr-training-debug |
| kernel panic/ramdump 代码级崩溃 | 转交 | han-kernel-crash-analyzer |

## 预检清单

- 用户是否给出平台/芯片族（如 MT582/Divar）与目标频率？没有 → Step 0
- **训练与运行是否都受限？**（"训练硬性 ≤X" vs "仅运行 ≤X" 两类需求方案完全不同）→ Step 0
- 当前状态：未改/已改已死/改完想验证？→ 决定从 Step 1 还是 Step 2 进入
- 三层源码路径是否可达（boot_images / RPM.BF / kernel_platform）→ references/platform-paths.md

## Workflow

| Step | 文件 | 做什么 |
|------|------|--------|
| 0 | workflows/step-00-intake.md | 收集平台/目标频率/硬性要求边界/当前现象 |
| 1 | workflows/step-01-baseline.md | 基线对照 + 死机指纹三态分诊 |
| 2 | workflows/step-02-xbl.md | XBL 联动清单（训练宏/switchboard/INDEX/DIT/MAX_FREQ） |
| 3 | workflows/step-03-rpm.md | RPM 切频 clamp 修法 + 独立源码路径陷阱 |
| 4 | workflows/step-04-kernel.md | Kernel BIMC 四路径投票 + dts 可选属性 |
| 5 | workflows/step-05-verify.md | 三层联刷矩阵 + 开机判据 + dump 对比法 |
| 6 | workflows/step-06-report.md | 生成改动方案报告 |
| 7 | workflows/step-07-learn.md | 案例沉淀（被动闭环声明） |
| - | workflows/feedback-loop.md | 反馈闭环（用户触发） |

## 参考资料速查

| 文件 | 用途 |
|------|------|
| references/fingerprint-library.md | 降频后三种死机指纹判别表 |
| references/cross-firmware-checklist.md | 三层联动 checklist + SMEM ABI 原则 |
| references/platform-paths.md | MT582/Divar 三层源码路径速查 |
| data/patterns.json | 已验证模式库（confidence 评分） |
| data/cases/ | 历史降频案例 |
