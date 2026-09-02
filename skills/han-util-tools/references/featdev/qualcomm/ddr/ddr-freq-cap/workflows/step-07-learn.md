# Step 7: 案例沉淀（被动反馈闭环）

## 7.1 存档本轮案例

将本轮改动/排障过程写入 `data/cases/<YYYYMMDD>-<平台>-<目标频率>.json`：

- `id` / `timestamp` / `platform`
- `input_summary`：平台、原频率→目标频率、硬性要求边界、初始现象
- `process_steps`：按 Step 记录关键动作与发现
- `key_findings`：判别出的指纹、定位的根因层、验证结果
- `experiments`：实验对照表（含被证伪假说）
- `final_result`：终局三层组合 + 各仓库 commit
- `outcome`：success / partial / failed

## 7.2 更新 patterns.json

本轮验证有效的模式：confidence +1、frequency +1、last_seen 更新；
被证伪的观察如实记录（可作为新条目或降低置信度）。

## 7.3 领域知识追加

平台特定发现（如新平台的独立源码路径、switchboard 差异）追加到
`references/platform-paths.md` 与 `references/cross-firmware-checklist.md`。

## 7.4 反馈闭环（被动触发）

**本轮不主动询问反馈。** 跨固件降频通常需要多轮刷机验证，不应每次都弹出反馈。
当用户后续主动发出完成信号（如"能开机了"、"降频生效了"、"验证通过了"），
进入**反馈闭环模式**（读取 `workflows/feedback-loop.md`），届时回顾历史、
确认有效步骤、更新模式置信度。
