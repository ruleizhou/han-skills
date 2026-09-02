# Step 2: XBL 层联动清单（不可拆集）

## 2.1 核心认知

XBL 降训练频率是**联动集**：训练起点宏决定"最高训练 band"换人，新 band 必须完整接替原 band 的全套训练职责。只改宏会导致 WRLVL/perbit 静默缺失 → 训练 ABORT 或 DDR 不稳。

## 2.2 改动清单（以 DivarPkg 2092800→1804800 为例，band7→band6）

| 文件 | 改动 | 作用 |
|------|------|------|
| `Settings/DSF/boot/lpddr4/target_config_lpddr4.h` | `DSF_MAX_SUPPORTED_DDR_TRAINING_FREQ` → 新值 | 训练起点（靠 `==宏值` 在 `training_freq_in_khz[]` 数组里查索引定位）+ clock plan 上限 |
| `Settings/DSF/boot/lpddr4/switchboard_config_lpddr4.c` | 新 band 行接替原 band 全套：DCC/WRLVL=1，WR/RD 开 perbit+2D VREF 列 | 新最高点做全套训练（原最高 band 的配置照抄） |
| `Library/DSFTargetLib/boot/ddrss/header/ddrss_training.h` | `MAX_TRAINING_FREQ_INDEX` → 新 band 号 | DQS WRLVL 触发、RD DCC save/restore 寄存器组选择、SED abort 判定跟随新最高点 |
| `Library/DSFTargetLib/boot/target/{Chip}/header/ddr_phy_technology.h` | `MIN_DTTS_TRACKING_PRFS` 减 1 | DIT/周期训练数据在新最高 band 采集 |
| `Library/DDRTargetLib/ddr_target.c` | `DDR_MAX_FREQ` → 新值 | 运行时 DFS 天花板（SMEM `max_ddr_frequency`）+ `ddr_num_clock_levels` 截表 |
| `boot/ddrss/src/lpddr4/ddrss_wr_dqdqs_lpddr4.c` | 硬编码 `prfs_indx != 7` → `!= MAX_TRAINING_FREQ_INDEX` | 小 eye abort 豁免跟随新最高点（grep 确认唯一裸数字） |

## 2.3 不要做的事（实验已证）

- **版本号 bump**（如 16.0→16.1）：无收益。RPM/AOP 不校验该版本；且多数设备训练分区 checksum 恒 0（每次开机全量重训），"强制重训"保险无效
- **清零 SMEM clock_plan 尾部槽位**：boot 训练起点若仍指向旧 band 会查表越界吃到全 0 槽 → PLL 参数全 0 → 训练卡死
- **只改宏不动 switchboard**：新 band 无 WRLVL/DCC 打底 → RD 1D 训练零眼 ABORT（错误码 84）
- `target_config.c` 里的全局 `training_freq_in_khz` 数组：死代码（全库无引用），真正生效的是 `ddrss_boot_training_init_lpddr4.c` 的局部同名数组——**别改错地方**

## 2.4 保留不动的

- AC timing / RL-WL 频率区间表：目标频率落既有档（如 1804800 落 1600~1866 档）
- `ddrss_common.c` 的旧频率特判分支：变成不可达死代码，无害
- Clock 层 DFS 表的旧频率行：cap 后不可达，无害

## 下一步

完成后，读取 `workflows/step-03-rpm.md` 继续。
