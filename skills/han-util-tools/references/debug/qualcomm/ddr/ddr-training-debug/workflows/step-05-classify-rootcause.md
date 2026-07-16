# Step 5: 日志分类→根因定位

## 5.1 解析 UART 诊断日志

从新 UART 日志中提取所有 `SMALL_EYE_ABORT` 行：

```
SMALL_EYE_ABORT: RD_DQDQS_DCC        ← 仅此一条！
SMALL_EYE_FINAL: aborting boot
```

**关键判断**：
- **只有一条 SMALL_EYE_ABORT** → 第一个触发的就是根因
- **多条不同标签** → 按时间排序，最早触发的通常是根因（后续可能是连锁反应）

## 5.2 匹配训练阶段

| UART 标签 | 训练阶段 | 代码文件 |
|-----------|---------|---------|
| `RD_DQDQS_DCC` | Read DQS/DQ DCC 校准 | `ddrss_rd_dqdqs_lpddr4.c:574/588/609` |
| `RD_DQDQS_EYE_WIDTH` | Read 眼宽检查 | `ddrss_rd_dqdqs_lpddr4.c:922/938` |
| `RD_DQDQS_SETUP_HOLD` | Read Setup/Hold 检查 | `ddrss_rd_dqdqs_lpddr4.c:950/963` |
| `RD_DQDQS_VREF_EYE` | Read VREF 多pass 眼图 | `ddrss_rd_dqdqs_lpddr4.c:1838-1966` |
| `RD_DQDQS_HP_EYE_HEIGHT` | Read HP VREF 眼高 | `ddrss_rd_dqdqs_lpddr4.c:2379` |
| `WR_DQDQS` | Write DQ-DQS 训练 | `ddrss_wr_dqdqs_lpddr4.c` |
| `RCW` | RCW 训练 | `ddrss_rcw_lpddr4.c:524` |
| `WRLVL` | Write Leveling | `ddrss_wrlvl_lpddr4.c:765` |
| `DCC` | DCC 校准 | `ddrss_dcc.c` |

## 5.3 定位具体检查条件

根据标签读取对应代码行（前后 5 行），提取触发条件。

**示例：RD_DQDQS_DCC（行 574）**：
```c
if((dqsdcc_adj >= training_params_ptr->ddr_abort.max_rd_dqs_dcc) &&
   (prfs_index==MAX_TRAINING_FREQ_INDEX))
{
    // DQS DCC 校准值 >= 阈值
    // 且处于最高训练频率
}
```

## 5.4 读取当前阈值

读取 `ddr_training_params.c` 中对应参数的当前值：

```bash
grep -n "参数名" SocPkg/{Platform}Pkg/Settings/DSF/boot/common/ddr_training_params.c
```

对照 `references/threshold-guide.md` 理解该参数的含义和合理范围。

## 5.5 输出根因摘要

模板：

```markdown
## 根因分析

**触发阶段**：[RD_DQDQS / WR_DQDQS / RCW / WRLVL / DCC]
**具体检查**：[DCC 校准 / 眼宽 / 眼高 / Setup / Hold / tDQSCK]
**当前阈值**：[值]
**触发条件**：[从代码解析的条件]
**分析**：[为什么触发 — 硬件信号质量 / 阈值过紧 / 其他]
```

## 下一步

根因定位后 → 读取 `workflows/step-06-tune-params.md`
