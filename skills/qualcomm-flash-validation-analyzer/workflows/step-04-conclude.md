# Step 4: 根因定论与修复输出

## 任务

汇总证据 → 分层结论 → 修复 patch → 验证清单 → 排查报告。

## 4.1 分层结论格式

```
根因一（主因）：[机制] × [器件特性] 因果链，每环附实测证据
根因二（次因）：同上（无则省略）
因果链验证矩阵：实验 × 结果对照表
```

**纪律**：每个结论必须有对应实验/代码证据；静态推理部分明确标注"待设备验证"。不确定就说不确定。

## 4.2 修复输出（按根因选）

| 根因 | 修复 | 位置 |
|---|---|---|
| governor 死区（慢料） | downdifferential 按 SDAM 位分流（2.x=45 / 3.x=65） | msm-kernel `ufs_qcom_config_scaling_param` |
| quirk miss | `UFS_FIX(<实际id>, ANY, DELAY_BEFORE_LPM)` | msm-kernel `ufs_qcom_dev_fixups[]` |
| 挂起过快（非 quirk 原因） | 评估 autosuspend_delay / AHIT 调整，case-by-case | - |
| 环境差异 | 交叉刷机排除内核变量后重测 | - |

**patch 要求**：unified diff 完整可 apply；声明放函数块首（内核 C89）；注释写清依据（ftrace 实测数据）；附 commit message 草稿。参考格式见 `data/cases/` 首案例对应的 `/home5/zhourulei/issue/modules/flash/ufs-clkscale-fix.patch`。

## 4.3 验证清单（随报告交付）

1. 编 `ufs_qcom.ko`（vendor 模块，无需整编）→ 替换 → 重启
2. 重跑 flashval——**不要加 echo on**（会弄死依赖 suspend 前置的测试项，见 ptrn-003）
3. 预期目标 + 回归项（gating/suspend/性能）
4. 提交前 patch 占位 index 换真实 hash

## 4.4 排查报告

输出独立 .md 到问题工作目录（用户指定或当前目录），结构：
问题描述（含两料对照表）→ 背景机制 → 排查过程（实验全数据）→ 根因结论（因果链+验证矩阵）→ 修复 patch → 方法学沉淀 → 遗留事项 → 附录（代码位置表 + 命令速查）。

**同时向高通开 case 的场景**：根因落在 Qualcomm 参考代码行为（governor 参数/测试判据/quirk 表缺项）时，建议用户附报告开 case。

**完成后，读取 `workflows/step-05-learn.md` 继续。**
