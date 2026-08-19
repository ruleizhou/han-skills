# Step 6: 分层结论输出与报告落盘

## 6.1 结论分层(强制结构)

| 层 | 定义 | 写法要求 |
|----|------|----------|
| L1 实证 | 每环都有 log 原文,环间因果时序咬合 | 附行号+uptime,链式呈现 |
| L2 强推断 | 多信号收敛但缺直接日志 | 列出收敛信号+未闭合点 |
| L3 开放缺口 | 现有证据无法定谳 | **必须给复测取证清单**,不编根因 |

表述模板:「核心缺陷 = X;症状 Y 是 Z 机制的下游表现;触发者证据指向 W」。
一个根因多条症状通路时,把主问题(如 boot 静默卡死)与下游表现(recovery
界面两条路径)分开写,避免用例按表象写导致漏测。

## 6.2 报告落盘(塔台体系)

- 路径:`$HET/analysis/reports/<project>/<bug_id>_<标题去【】前缀>.md`
- frontmatter:schema v2 英文字段;status 由 report close 状态机管理,不手改
- 必含章节:逐事件表(级别×原因×log)、排除项(全部带证据)、修复方向
  (按性价比排序)、复现与验证建议、可沉淀知识、证据索引(行号)
- 推翻前人结论时**显式记录推翻理由与新旧证据差**(哪份 log 当时没看到)

## 6.3 复测取证清单模板(有 L3 缺口时必附)

1. 复测带串口 + persist logcat 落盘(boot loop 轮 adbd 必断)
2. cmdline 加 `initcall_debug`(驱动 probe 停摆类);复现后抓 `/proc/modules`
   (模块 state 列)、`/proc/<pid>/cmdline` 与父进程(recovery 拉起类)
3. 监控 `sys.init.updatable_crashing`、`sys.rescue_boot_count`、events log
   `rescue_note` 的 count 爬升(count≥2 = system_server 反复重启直接证据)
4. 通过标准量化:重跑 N 次,无 'RescueParty' 命令、无特征指纹、无进 recovery、
   events log 无 count≥2

**本 skill 分析流程到此完成。所有步骤完成,如需重新执行从 Step 0 开始。
用户确认问题解决后,触发反馈闭环(读 `workflows/feedback-loop.md`)沉淀案例。**
