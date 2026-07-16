# 评估用例

## Case 1: MT582 QDUTT DDI 启动失败

**输入日志**：`DDI_V1.txt`（错误码 84，无 Small Eye 诊断）

**期望**：
- Step 1 正确解析 Error code 84 → BL_ERR_CORE_VERIFY
- Step 3 定位 ddr_external_api.c:335 → ddr_abort()
- Step 4 建议添加 DDR_UART_LOG（ddr_log.h + DSF 训练文件修改方案）

## Case 2: Small Eye 分类诊断

**输入日志**：`DDI_V3.txt`（有 SMALL_EYE_ABORT: RD_DQDQS_DCC 日志）

**期望**：
- Step 5 识别 RD_DQDQS_DCC 子分类
- Step 6 定位参数 max_rd_dqs_dcc，给出调优建议（14→24）
- 包含风险评估（建议高低温验证）

## Case 3: 参数调优咨询

**输入**："max_rd_dqs_dcc 从 14 改到 24 有什么影响？"

**期望**：
- Step 6 触发，读取 threshold-guide.md
- 输出 DCC 值范围判断（14-20 正常，20-30 偏高可接受）
- 给出风险评估（温漂、电压拉偏、批次差异）

## Case 4: 反馈闭环

**输入**："问题解决了，max_rd_dqs_dcc 改成 24 通过了"

**期望**：
- 触发 feedback-loop.md
- 确认根因和修复方案
- 更新 patterns.json 中 RD_DQDQS_DCC 的 confidence
- 沉淀案例到 data/cases/
