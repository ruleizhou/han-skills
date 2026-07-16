# abort 阈值含义与调优指南

## 阈值分类

### DCC（Duty Cycle Correction）类

| 参数 | 默认值 | 含义 | 范围判断 |
|------|--------|------|---------|
| `max_rd_dqs_dcc` | 14 | Read DQS/DQ DCC 校准最大步数 | <14 优秀, 14-20 正常, 20-30 偏高可接受, >30 信号质量有问题 |
| `max_dqs_cm_dcc` | 12 | DQS Common-Mode DCC 校准上限 | 同上 |
| `max_dqs_io_dcc` | 12 | DQS IO DCC 校准上限 | 同上 |
| `max_ck_cm_dcc` | 12 | CK Common-Mode DCC 上限 | 同上 |
| `max_ck_io_dcc` | 12 | CK IO DCC 上限 | 同上 |

**DCC 值偏高常见原因**：
1. PCB 走线阻抗不匹配 / 不等长 → DQS 差分对占空比失真
2. VDDQ 电源纹波 → 影响 PHY 内部时钟质量
3. 温度变化 → 高温下 DCC 补偿量需求增大

**调优原则**：
- 确认当前值（如 24）后，至少留 4-6 步余量（如设 28-30）
- 高低温测试（-20°C ~ 60°C）确认不超限
- 电压拉偏测试（VDDQ ±5%）确认不超限

### 眼宽（Eye Width）类

| 参数 | 默认值 | 含义 |
|------|--------|------|
| `min_rd_eye_width` | 10 | Read 眼图最小宽度（fine step 单位） |
| `min_wr_eye_width` | 10 | Write 眼图最小宽度 |

### 眼高（Eye Height）类

| 参数 | 默认值 | 含义 |
|------|--------|------|
| `min_rd_eye_height_HP` | 5 | Read 眼图最小高度（HP VREF 模式） |
| `min_rd_eye_height_MP` | 8 | Read 眼图最小高度（MP VREF 模式） |
| `min_wr_eye_height` | 28 | Write 眼图最小高度 |

### Setup/Hold 时序类

| 参数 | 默认值 | 含义 |
|------|--------|------|
| `min_rd_setup` | 3 | Read Setup 最小时间（fine step 单位） |
| `min_rd_hold` | 3 | Read Hold 最小时间（fine step 单位） |
| `min_wr_setup` | 3 | Write Setup 最小时间 |
| `min_wr_hold` | 3 | Write Hold 最小时间 |

### RCW/WRLVL 类

| 参数 | 默认值 | 含义 |
|------|--------|------|
| `min_tDQSCK` | 1500 ps | RCW tDQSCK 最小延迟 |
| `max_tDQSCK` | 3500 ps | RCW tDQSCK 最大延迟 |
| `min_tdqs2dq` | 200 ps | TDQS2DQ 最小延迟 |
| `max_tdqs2dq` | 800 ps | TDQS2DQ 最大延迟 |

## 诊断子分类速查

| UART 日志标识 | 含义 | 对应参数 |
|--------------|------|---------|
| `SMALL_EYE_ABORT: RD_DQDQS_DCC` | Read DQS/DQ DCC 校准超限 | `max_rd_dqs_dcc` |
| `SMALL_EYE_ABORT: RD_DQDQS_EYE_WIDTH` | Read 眼宽不达标 | `min_rd_eye_width` |
| `SMALL_EYE_ABORT: RD_DQDQS_SETUP_HOLD` | Read Setup/Hold 不达标 | `min_rd_setup` / `min_rd_hold` |
| `SMALL_EYE_ABORT: RD_DQDQS_VREF_EYE` | Read VREF 多 pass 眼图不达标 | `min_rd_eye_height` 等 |
| `SMALL_EYE_ABORT: RD_DQDQS_HP_EYE_HEIGHT` | Read HP VREF 眼高不达标 | `min_rd_eye_height_HP` |
| `SMALL_EYE_ABORT: WR_DQDQS` | Write 训练不达标 | `min_wr_eye_width` / `min_wr_setup` 等 |
| `SMALL_EYE_ABORT: RCW` | RCW tDQSCK 范围超限 | `min_tDQSCK` / `max_tDQSCK` |
| `SMALL_EYE_ABORT: WRLVL` | Write Leveling delta 超限 | WRLVL delta enable |
| `SMALL_EYE_ABORT: DCC` | DCC 校准超限 | `max_dqs_cm_dcc` 等 |
| `SMALL_EYE_FINAL` | 最终 abort 检查触发 | — |

## 风险评估框架

每次参数调优必须评估：

1. **温漂余量**：当前值到上限的步数差异，高低温可能漂移 2-4 步
2. **电压敏感性**：VDDQ ±5% 下的 DCC 变化
3. **批次差异**：不同 DRAM 颗粒/PCB 批次间的差异
4. **量产风险**：如果当前值已经接近新阈值，建议排查硬件根因而非仅放宽阈值
