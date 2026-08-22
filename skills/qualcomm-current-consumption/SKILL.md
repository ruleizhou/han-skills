---
name: qualcomm-current-consumption
version: "1.1.0"
description: >
  排查高通 Android 待机/休眠电流偏高：aosd=0、cxsd/ddr 正常但功耗高、AOP dump/hansei 解析、
  UFS spm_lvl、GPIO/NFC 常开脚、STM/QDSS/debug_enabled、qcom_sleep_stats 分层定位。
  输出分层结论、命令清单与下一步（对标机/AOP 投票/板级漏电）。具备自学习：沉淀「症状→档位→根因类」模式。
  当用户提到功耗偏高、待机电流大、灭屏电流、aosd、cxsd、ddr sleep、解析 aop dump、hansei、
  netrani/parrot/SM6450 功耗、UFS VCCQ、hub_3v3、NFC VEN、STM/coresight 挡深睡时使用。
  修好了/根因确认了/电流达标了 → 反馈闭环。内核 panic 用 han-kernel-crash-analyzer；闪存性能用 han-flash-test。
---

# Qualcomm Current Consumption

高通平台待机电流偏高的分层排查 skill：先定睡眠档位（aosd/cxsd/ddr），再下钻 UFS/GPIO/QDSS/AOP。

## 核心原则

1. **先分层再下钻** — 先读 `qcom_sleep_stats`（aosd/cxsd/ddr）与 `mem_sleep`，再动 UFS/GPIO/QDSS
2. **拔 USB 前采基线** — 测流需断 USB；spm/stats/debug 状态必须在 adb 仍连时读完
3. **Target 要对** — AOP hansei 用芯片代号（如 netrani），勿照抄文档 `-t 845`
4. **小改验证收益** — NFC/STM 等单项改完要记 mA；无收益则升级主线（多为 aosd）
5. **交互优先** — Step 0 必须先用结构化提问收集场景（平台映射见 step-00），禁止先翻目录再提问
6. **锚定前验真编译** — 引源码行号/驱动结论前先查 `CONFIG_*=y/m`、`/proc/kallsyms` 或 `strings` 验 KO，防锚 dead code
7. **修复后更糟立刻停手** — 下沉一层重诊，绝不在同层叠补丁
8. **不早锚定** — 见供电轨/GPIO 脚位 ON，先对标机或跨机同配置对比再判主因

## 模式判断

| 触发信号 | 模式 | 动作 |
|----------|------|------|
| 功耗偏高 / aosd=0 / 解析 aop dump / 待机电流 | 分析模式 | Step 0 → … → Step 7 |
| 修好了 / 电流达标了 / 根因确认了 / aosd 有 Count 了 | 反馈闭环 | 读 `workflows/feedback-loop.md` |

## 预检清单

- [ ] 平台/项目已知（或可从 dump/UART 推断）
- [ ] 有电流差（对标 mA）或至少有 sleep_stats / AOP dump / UART 之一
- [ ] 测流场景明确：deep 还是 s2idle；是否拔 USB
- [ ] 非「仅跑分/仅充电」类问题（那不走本 skill）

## Workflow

本 skill 使用 8 步工作流（Step 0 ~ Step 7）。**每步开始先 Read 对应文件：**

| Step | 文件 | 做什么 |
|------|------|--------|
| 0 | `workflows/step-00-collect.md` | 交互收集平台、材料、电流差、测流条件 |
| 1 | `workflows/step-01-sleep-baseline.md` | 读 sleep_stats / mem_sleep / UFS lvl（adb 基线） |
| 2 | `workflows/step-02-aop-hansei.md` | 有 dump 则 hansei 解析 AOP |
| 3 | `workflows/step-03-board-gpio.md` | GPIO/NFC/HUB 等板级常开 |
| 4 | `workflows/step-04-debug-qdss.md` | debug_enabled / STM / ETR / DCC / USB diag |
| 5 | `workflows/step-05-triage.md` | 定位矩阵 → 根因类与收益排序 |
| 6 | `workflows/step-06-report.md` | 输出 Debug 结论/手册式报告 |
| 7 | `workflows/step-07-learn.md` | 自学习收录 |

**反馈闭环由用户主动触发。** 开始时先读 `workflows/step-00-collect.md`。

## 参考资料速查

- 睡眠分层与矩阵：`references/sleep-layers.md`
- Hansei / AOP：`references/aop-hansei.md`
- UFS / GPIO / QDSS 命令：`references/commands-cheatsheet.md`
- 领域知识（闭环积累）：`references/domain-knowledge.md`
- 模式库：`data/patterns.json`
- 案例：`data/cases/`
