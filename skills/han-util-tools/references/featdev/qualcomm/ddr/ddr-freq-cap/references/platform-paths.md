# 平台源码路径速查

## MT582 / Divar（已验证平台）

```
BP_claude/
├── BOOT.XF.4.1/boot_images/QcomPkg/SocPkg/DivarPkg/     # XBL
│   ├── Settings/DSF/boot/lpddr4/target_config_lpddr4.h        # 训练宏
│   ├── Settings/DSF/boot/lpddr4/switchboard_config_lpddr4.c   # 训练开关表
│   ├── Library/DSFTargetLib/boot/ddrss/header/ddrss_training.h        # MAX_TRAINING_FREQ_INDEX
│   ├── Library/DSFTargetLib/boot/target/Divar/header/ddr_phy_technology.h  # F_RANGE 表 / MIN_DTTS
│   └── Library/DDRTargetLib/ddr_target.c                      # DDR_MAX_FREQ / SMEM 填充
├── RPM.BF.1.10/rpm_proc/core/boot/ddr/
│   └── hw/hw_sequence/rpm/divar/ddrss/                  # ★ RPM Divar 真实编译路径
│       ├── src/ddrss_freq_switch_rpm.c                  #   HAL_DDR_Pre/Post_Clock_Switch
│       └── bimc/mc230/src/lpddr4/bimc_freq_switch_lpddr4_rpm.c
│       # ⚠ hw/hw_sequence/rpm/ddrss/（无平台名）为通用路径，Divar 不编译
│       # 确认法：build/rpm/rpm/*/ 下 .o 的路径 = 真实编译源
└── LA.VENDOR.13.2.1.R2/kernel_platform/
    ├── msm-kernel/drivers/clk/qcom/clk-smd-rpm.c        # BIMC 投票四路径
    └── qcom/proprietary/devicetree/qcom/
        ├── khaje.dtsi                                   # base：ddr_freq_table / rpmcc / bimc interconnect
        └── khaje-idp-pm7250b-overlay-mt582-ddr-fmax.dtsi # 板级 overlay（mt582/5820/5821 共用）
```

## 构建命令

| 层 | 命令 | 产物 |
|----|------|------|
| XBL | `./meig_build.sh MT582 BOOT CLEAN_BUILD` | `QcomPkg/SocPkg/DivarPkg/Bin/LAA/RELEASE/xbl.elf`（末尾 DDI Region Overflow 为已知可绕过） |
| RPM | `./meig_build.sh MT582 RPM` | `rpm_proc/build/ms/bin/divar/sdm_ddr4/RF2K/rpm.mbn` |
| Kernel | Android 常规流程 | `boot.img` / `dtbo.img` |

## 关键数据结构位置

- SMEM 共享表：`ddr_target.c` 的 `ddrsns_share_data`（RPM/Kernel 消费）
- RPM 消费的训练字段：仅 `dit.*`（周期训练）与 `rcw.bimc_tDQSCK[clock idx]`（切频写 PHY）——**rd_dcc 等 RPM 不读**
- F_RANGE 分档（Divar）：250000/600000/900000/1100000/1500000/1700000/2000000/2200000 → 1804800 落 band6

## 新平台接入

复制本 checklist 流程时优先确认：
1. RPM 独立源码路径（ls `core/boot/ddr/hw/hw_sequence/rpm/` 下有无平台目录）
2. switchboard 结构（`Settings/DSF/boot/lpddr4/`）
3. kernel 的 rpmcc 驱动（clk-smd-rpm vs clk-rpmh）与 interconnect compatible
