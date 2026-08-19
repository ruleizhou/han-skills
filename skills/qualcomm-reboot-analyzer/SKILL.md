---
name: qualcomm-reboot-analyzer
description: >
  高通平台「无 dump 的重启行为异常」根因分析:[分析模式] 排查无法正常重启、
  重启后不开机、开关机压测异常(5000 次开关机进 recovery 界面)、boot 静默卡死、
  开机卡住、压测挂死但无 ramdump/panic、软重启异常、RescueParty 自愈升级、
  重启命令异常(reboot command 'RescueParty'/'recovery')、ABL 误入 Recovery、
  misc BCB 异常类问题。触发词:无法正常重启、重启后不开机、开关机测试失败、
  进 recovery、recovery 界面、开机卡死、挂死无 dump、RescueParty、重启挂死、
  开关机压力测试异常、boot 未完成、软重启不开机、重启行为异常。
  方法论:reboot command 全量分布统计 → RescueParty L1-L5 事件定级 → 死因指纹
  采集(-22 try_module_get 铁证 / PMIC mfd 兄弟驱动齐挂归因)→ ABL/recovery
  判定链 → 时序测谎与物证核验 → 分层结论。
  [反馈闭环模式] 问题解决/根因确认/修好了时触发,回顾案例、更新 patterns.json
  置信度。有 panic/ramdump/KASAN/parser_out 的崩溃交给 han-kernel-crash-analyzer;
  功耗问题交 qualcomm-current-consumption;闪存速率交 han-flash-test。
---

# Qualcomm 重启行为异常分析(无 dump 线)

排查高通 Android 平台**没有崩溃 dump** 的重启类异常:开关机压测进 recovery、
重启后不开机、boot 静默卡死、RescueParty 自愈升级等。核心武器是把「重启行为」
当作可统计的信号,而不是逐行翻日志。

## 核心原则

1. **先统计后细读** — 任何串口大文本第一刀永远是 `reboot: Restarting system
   with command 'X'` 的全量分布统计(如 4999 空 + 3×'RescueParty' + 1×'recovery'),
   一眼锁定异常轮,再进细节。禁止上来就逐行读 886M 日志。
2. **稀有指纹优先于海量噪音** — `-517`(EPROBE_DEFER)、defer timeout、SPMI
   错误刷屏都是常态噪音(全文几十万次);`could not increase module refcount`(-22)
   是「模块正在死去」的铁证(10 次即可圈定异常轮)。先数稀有指纹的分布。
3. **事件切分优先于升级链叙事** — 多次 RescueParty 不等于一条升级链;用
   「下一轮是否 `command ''`(正常自愈)」把独立事件切开,再谈 mitigationCount
   累计(它是持久化计数器,跨事件只增不减)。
4. **物证优于推理** — 分析「谁拉起了 X」前先找物证:采集脚本(collect_log.bat
   类)全文必读、USB 枚举时序不等式(1.77s < 6.5s 即可排除人工/adb)。猜动机
   之前先验物理时序。
5. **串口有盲区,诚实分层** — printk ratelimit 会吞掉 userspace 证据(曾见
   51348 lines suppressed);boot 静默卡死在串口上零指纹是常态。结论必须分层:
   L1 实证 / L2 强推断 / L3 开放缺口+复测取证清单。没有证据就说没有,不编根因。

## 模式判断

| 触发信号 | 模式 | 动作 |
|----------|------|------|
| 无法正常重启/重启后不开机/开关机压测异常/进 recovery/boot 卡死/挂死无 dump/RescueParty/重启命令异常 | 分析模式 | Read `workflows/step-00-intake.md` 开始 |
| 搞定了/修好了/根因确认了/不再复现/复测通过 | 反馈闭环模式 | Read `workflows/feedback-loop.md` 执行 |
| 日志里有 panic/ramdump/KASAN/parser_out/tombstone 崩溃 dump | 转交 | 提示改走 han-kernel-crash-analyzer |
| 待机电流/功耗偏高 | 转交 | 提示改走 qualcomm-current-consumption |

## 预检清单

- 证据类型:串口 log(jpp/IPOP 大文本)/ logcat 包 / 两者皆有 / 什么都没有?
- 有崩溃 dump(panic/ramdump/KASAN)吗?有 → 转交,不属本 skill
- 是重启**行为**异常(不开机/进 recovery/卡死)而非崩溃?是 → 继续
- 多块单板/多次复测?分清「票面原始复现」与「复测板」,以原始复现为准绳

## Workflow

本 skill 使用 7 步工作流(Step 0 ~ Step 6),按顺序执行。**每个步骤开始时,先 Read 对应的详细指令文件:**

| Step | 文件 | 做什么 |
|------|------|--------|
| 0 | `workflows/step-00-intake.md` | 输入收集与证据分流(证据类型/单板/轮次规模) |
| 1 | `workflows/step-01-reboot-stats.md` | reboot command 全量分布统计 + 轮次时长排行榜 |
| 2 | `workflows/step-02-event-split.md` | 事件切分与 RescueParty 定级(独立事件 vs 升级链) |
| 3 | `workflows/step-03-fingerprint.md` | 死因指纹采集(-22/-517/apexd/init 点名/PMIC mfd) |
| 4 | `workflows/step-04-abl-recovery.md` | bootloader/recovery 判定链(ABL 标志/UI 状态机) |
| 5 | `workflows/step-05-forensic-timing.md` | 时序测谎与物证核验(脚本物证/USB 不等式/ratelimit 盲区) |
| 6 | `workflows/step-06-report.md` | 分层结论输出与报告落盘(塔台 schema v2) |

**反馈闭环由用户主动触发,不在主流程中自动弹出。触发后读取 `workflows/feedback-loop.md`。**

**开始执行时,首先读取 `workflows/step-00-intake.md`。**

## 参考资料速查

- `references/rescue-party-mechanism.md` — RescueParty L1-L5 机制表、计数规则、rescue_note 语义、源码行号
- `references/fingerprint-library.md` — 死因指纹库与归因启发式(何时上溯 mfd/总线层)
- `references/log-recipes.md` — grep 配方集(统计/轮界/指纹/对照组)
- `data/patterns.json` — 自学习模式库(症状→根因类,置信度)
- `data/cases/` — 历史案例卡(95916 三事件结构、96299 UEFI pwrkey)
- 最佳实践 live reference:`~/.claude/skills/han-kernel-crash-analyzer/(同款拆分+自学习架构)
