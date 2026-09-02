# Step 0: 收集需求与环境

## 0.1 必问四项

用 AskUserQuestion 或逐项确认，**缺一不可**：

| # | 问题 | 为什么关键 |
|---|------|-----------|
| 1 | **平台/芯片族**（如 MT582/Divar、MT5825/Bengal） | 决定 RPM 独立源码路径、switchboard 结构 |
| 2 | **目标频率**（如 1804800、1555200） | 决定新最高训练 band |
| 3 | **硬性要求边界**：仅运行时受限，还是训练过程也必须 ≤ 目标？ | 两种需求方案完全不同（后者是三层全改，前者 kernel cap 可能就够） |
| 4 | **当前状态**：未改 / 已改已死机 / 已改想验证 | 决定从 Step 1（分诊）还是 Step 2（改动清单）进入 |

## 0.2 现频率确认

若用户没说当前最大频率，从源码或历史 log 确认：
- XBL：`SocPkg/{Platform}Pkg/Settings/DSF/boot/lpddr4/target_config_lpddr4.h` 的 `DSF_MAX_SUPPORTED_DDR_TRAINING_FREQ`
- 开机 log：`Max Frequency = XXXX MHz` 行

## 0.3 Band 归属计算

用 F_RANGE 阈值表（`Library/DSFTargetLib/boot/target/{Chip}/header/ddr_phy_technology.h`）算目标频率落在哪个 band：
`F_RANGE_{n-1} < 目标频率 ≤ F_RANGE_n` → 属 band n-1（示例 Divar：1700000 < 1804800 < 2000000 → band6）

**新最高训练 band ≠ 原 band 时，后续每一步的联动项都会被触发。**

## 下一步

完成后，读取 `workflows/step-01-baseline.md` 继续。
