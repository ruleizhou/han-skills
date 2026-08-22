# qualcomm-current-consumption

> Agent 执行本 skill 时勿读本文件。

## [1.1.0] - 2026-08-22

> 本版部分机制借鉴自 MeigExpertTeam `power-current-debug`（底驱匠）。

- 新增 `scripts/capture_sleep_baseline.sh`：一键采集 step-01/03/04 全部读节点（拔 USB 前必跑），SUMMARY 含睡眠分层自动初判，UFS 路径自动探测
- `workflows/step-06-report.md` 新增验证契约 VERIFY_RESULT：pass/fail/skipped 三态判定（fail 仅限谎报类），防"仅 s2idle 谎称深睡 / 无复测声称达标"假 PASS
- `workflows/step-01-sleep-baseline.md` 接线一键采集提示
- `workflows/step-00-collect.md` 测量纪律联动验证契约说明
- `workflows/feedback-loop.md` `result_assessment` 细分 `success_unverified`（达标未复测）
- `SKILL.md` 核心原则 5→8 条：新增锚定前验真编译 / 修复后更糟停手 / 不早锚定
- `workflows/step-00-collect.md` + `SKILL.md` 原则 5：`AskUserQuestion` 字面绑定改为跨平台结构化提问（OpenCode `ask` / Gemini CLI `ask_user` / Cursor `AskQuestion` / 编号选项兜底）

（1.0.0：初始 8 步工作流 + patterns 自学习闭环）
