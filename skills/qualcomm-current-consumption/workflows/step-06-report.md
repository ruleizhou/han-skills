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

**完成后,读取 `workflows/step-07-learn.md` 继续。**
