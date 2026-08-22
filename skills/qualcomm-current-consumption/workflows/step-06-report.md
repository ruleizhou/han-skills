# Step 6: 输出报告

写报告到 `$HET/analysis/reports/<project>/<bug_id>.md`(业务 ID 主键;project 取 bug 的 project 字段或用户指定),并增量更新 debug 手册 `$HET/analysis/手册/<类别>/<主题>.md`(不存在则生成:排查步骤+根因模式+案例;已存在则追加新根因/案例)。

> `$HET` = `${HAN_EXPERT_HOME:-$HOME/backup/HanExpertTeams_New}`
> 模板:`$HET/references/report-template.md`(报告)、`$HET/references/manual-template.md`(手册)

## 报告结构
1. **结论摘要** — 主因类一句话 + 已验证 ΔmA
2. **睡眠分层表** — aosd/cxsd/ddr/apss/子系统
3. **UFS / Regulator** — spm 与 Enabled regulators
4. **GPIO / NFC** — 关键脚与 DTS
5. **QDSS / debug** — 开关状态与收益
6. **AOP hansei**(若有)— sleep_stats / NPA
7. **定位矩阵应用结果**
8. **下一步 Checklist** — 对标机 aosd、AOP dump、硬件
9. **命令附录** — 可复制(引用 `references/commands-cheatsheet.md`,勿整份粘贴手册)

## 验证契约 (VERIFY_RESULT)

报告写完后,必须基于以下上下文变量输出结构化结论,防"仅 s2idle 谎称深睡 / 声称达标无复测"两类假 PASS:

- `suspend_mode` — deep | s2idle | unknown(step-00)
- `usb_unplugged_for_measure` — yes | no | unknown(step-00)
- `measured_ma` / `target_ma` — 实测与对标(step-00/复测)
- `root_cause_class` — step-05 定位结论;是否对标机确认
- `retest_evidence` — 修复后是否同脚本复采 diff(无修复动作则记 n/a)

```json
{
  "skill": "qualcomm-current-consumption",
  "status": "<pass|fail|skipped>",
  "failed_step": null,
  "error_summary": null,
  "diagnosis": "<主因类 + 已验证 ΔmA,一句话>"
}
```

### status 判定规则

> 判定顺序:先抓谎报(fail) → 再验达标(pass) → 其余一律 skipped。
> 定位价值不因降级而灭——skipped 时 diagnosis 照常写定位产出。

1. **fail(仅限谎报类,结论与证据矛盾)**:
   `suspend_mode=s2idle` 但报告称"深睡"(failed_step=1);
   `retest_evidence=无` 但报告称"已达标"(failed_step=6);
   `usb_unplugged_for_measure=no` 却给出定量 mA 根因(failed_step=0)。
2. **pass(全满足才给)**: `suspend_mode=deep` 且 `usb_unplugged=yes` 且
   `root_cause_class` 经对标机确认 且 `measured_ma ≤ target_ma` 且
   (`retest_evidence=有` 或无修复动作)。
3. **skipped(其余全部)**: 条件 unknown/no、纯定位报告(如仅升级 CE 未闭环)、
   无对标无复测 — `failed_step=null`,diagnosis 保留定位结论与 ΔmA。

**完成后,读取 `workflows/step-07-learn.md` 继续。**
