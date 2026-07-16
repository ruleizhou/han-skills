---
name: ddr-training-debug
description: >
  Qualcomm 启动链 DDR PHY 训练调试。当用户提到 DDR 训练失败、错误码 84 (BL_ERR_CORE_VERIFY)、
  ddr_abort、small_eye_abort、DDI/QDUTT 启动失败、DDR 眼图不达标、DCC 校准超限、
  或提供 DDR 训练 UART 日志时触发。覆盖 SBL1/DDI 阶段 DSF 框架下的 DDR 训练问题。
  支持分析模式和反馈闭环模式。
---

# DDR Training Debug

Qualcomm SBL1/DDI 阶段 DDR PHY 训练调试导航。系统化定位 small_eye_abort 触发点并给出参数调优建议。

## 核心原则

1. **先解析错误码，再定位代码** — 绝不猜测，必须追溯触发链
2. **每次只改一个变量** — 日志注入或参数调整，验证后再下一步
3. **阈值调优必须评估余量** — 高低温/电压拉偏至少留 4-6 步余量
4. **问题解决必须沉淀案例** — 存档到 data/cases/，更新 patterns.json

## 模式判断

| 触发信号 | 模式 | 动作 |
|----------|------|------|
| UART 日志 + 错误码/DDR 启动失败 | 分析模式 | Step 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 |
| "加诊断日志"/"定位触发点"/"分类 small_eye" | 诊断注入 | Step 2 → 4 → 5 |
| "改阈值"/"调优"/"DCC 调整"/"放宽容限" | 参数调优 | Step 2 → 6 |
| "问题解决"/"修复生效"/"搞定了"/"不再复现" | 反馈闭环 | feedback-loop.md |

## 预检清单

- 用户是否提供了 UART 日志？没有 → 必须从 Step 0 开始收集
- 日志中是否有 `Error code` 行？有 → 直接跳到 Step 1 解析
- 用户是否已确认具体平台（如 MT582/DivarPkg）？没有 → Step 0 确认
- **用户是否已提供 `{boot_images}` 源码根目录路径？** 没有 → Step 0 收集（源码路径用于读取 `boot_error_if.h`、`ddr_external_api.c`、`ddr_training_params.c` 等）

## Workflow

| Step | 文件 | 做什么 |
|------|------|--------|
| 0 | workflows/step-00-collect-info.md | 收集 UART 日志、平台信息、错误现象 |
| 1 | workflows/step-01-parse-error.md | 解析错误码，定位触发函数 |
| 2 | workflows/step-02-load-platform.md | 根据平台加载对应代码路径 |
| 3 | workflows/step-03-trace-abort.md | 追溯 small_eye_abort / ddr_abort 触发链 |
| 4 | workflows/step-04-inject-diag.md | 注入 DDR_UART_LOG 诊断日志 |
| 5 | workflows/step-05-classify-rootcause.md | 日志分类→定位具体根因维度 |
| 6 | workflows/step-06-tune-params.md | 参数调优建议与风险评估 |
| 7 | workflows/step-07-learn.md | 案例沉淀 + 更新模式库 |
| - | workflows/feedback-loop.md | 修复验证闭环 |

## 参考资料速查

| 文件 | 用途 |
|------|------|
| references/error-codes.md | 常见错误码速查表 |
| references/code-locations.md | 关键代码文件路径映射 |
| references/ddr-training-flow.md | DDR Training 流程与数据结构 |
| references/threshold-guide.md | abort 阈值含义与调优指南 |
| references/platform-mapping.md | 平台→Pkg→代码路径映射 |
| data/patterns.json | 历史错误模式库（confidence 评分） |
| data/cases/ | 已解决案例存档 |
