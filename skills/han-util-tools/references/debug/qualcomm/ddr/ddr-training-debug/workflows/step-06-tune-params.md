# Step 6: 参数调优建议与风险评估

## 6.1 定位需调整的参数

根据 Step 5 的根因分类，找到对应参数：

| 根因标签 | 参数 | 配置文件行 |
|---------|------|-----------|
| `RD_DQDQS_DCC` | `max_rd_dqs_dcc` | `ddr_training_params.c:136` |
| `RD_DQDQS_EYE_WIDTH` | `min_rd_eye_width` | `ddr_training_params.c:138` |
| `RD_DQDQS_SETUP_HOLD` | `min_rd_setup` / `min_rd_hold` | `ddr_training_params.c:148/150` |
| `RD_DQDQS_HP_EYE_HEIGHT` | `min_rd_eye_height_HP` | `ddr_training_params.c:143` |
| `WR_DQDQS` | `min_wr_eye_width` / 等 | `ddr_training_params.c:151-162` |
| `DCC` | `max_dqs_cm_dcc` / 等 | `ddr_training_params.c:128-134` |
| `RCW` | `min_tDQSCK` / `max_tDQSCK` | `ddr_training_params.c:120-121` |

## 6.2 确定调整幅度

读取 `references/threshold-guide.md` 中的范围判断标准。

**通用规则**：
1. 先确认当前触发值（从 DDI 日志或 HW 寄存器读取）
2. 新阈值 = 触发值 + 4~6 步余量
3. 如果无法获取触发值 → 逐次放宽 5~10 步，二分查找

**DCC 类参数范围参考**：
```
<14   → 优秀
14-20 → 正常范围
20-30 → 偏高但可接受（需高低温验证）
>30   → 信号质量有问题，不建议量产
```

## 6.3 风险评估

对每个参数调整，输出风险评估：

### 模板

```markdown
## 参数调优建议

**参数**：[参数名]
**当前值**：[X]
**建议值**：[Y]（触发值 + 余量）
**修改文件**：`SocPkg/{Platform}Pkg/Settings/DSF/boot/common/ddr_training_params.c`

### 风险评估

| 风险项 | 评估 |
|--------|------|
| 温漂 | 高低温可能漂移 2-4 步，余量 [Y-X] 步 [充足/不足] |
| 电压敏感性 | VDDQ ±5% 下 DCC 变化需验证 |
| 批次差异 | 不同颗粒/PCB 间差异 [评估] |
| 量产风险 | [低/中/高] — [理由] |

### 建议验证

1. 高低温测试 (-20°C ~ 60°C)
2. VDDQ 拉偏测试 (±5%)
3. 至少 3 块板子验证批次一致性
```

## 6.4 ODM 条件编译（可选）

如果修改只针对特定项目（如 MT582），可以添加 ODM 宏保护：

```c
#ifdef ODM_PROJECT_MT582
  training_params_ptr->ddr_abort.max_rd_dqs_dcc = 24;
#else
  training_params_ptr->ddr_abort.max_rd_dqs_dcc = 14;
#endif
```

## 6.5 验证步骤

1. 修改参数后重新编译 DDI
2. 烧录测试，确认不再触发 `SMALL_EYE_ABORT`
3. 确认 DDR 训练完整通过（`do_ddr_training` 后有 `Delta` 日志）

## 下一步

- 参数调优完成、修复已验证 → 读取 `workflows/step-07-learn.md` 沉淀案例
- 修复未生效 → 回到 Step 5 重新分析

> **边界提示**：若训练失败的根因是**频率上限被调整**（降训练频点/band 降档后新 band
> 训练开关未联动、或 RPM 切频越界），阈值调优治标不治本——转走
> `featdev/qualcomm/ddr/ddr-freq-cap`（XBL/RPM/Kernel 三层跨固件联动清单）。
