# 平台→Pkg→代码路径映射

## 平台识别方法

从 UART 日志第 5 行识别：
```
S - IMAGE_VARIANT_STRING=DivarPkgLAA
```

格式：`{Platform}Pkg{Config}`，其中 `{Platform}` 为 Divar/Kamorta/KamortaPro/Agatti。

## 平台映射表

| IMAGE_VARIANT_STRING | 平台 | Chipset | 代码相对路径 |
|---------------------|------|---------|------------|
| `DivarPkgLAA` | Divar (SM6225) | divar | `SocPkg/DivarPkg/` |
| `DivarPkgLAB` | Divar (SM6225) | divar | `SocPkg/DivarPkg/` |
| `KamortaPkgLAA` | Kamorta | kamorta | `SocPkg/KamortaPkg/` |
| `KamortaProPkgLAA` | Kamorta Pro | kamortapro | `SocPkg/KamortaProPkg/` |
| `AgattiPkgLAA` | Agatti | agatti | `SocPkg/AgattiPkg/` |

## 平台特定文件路径模板

```
SocPkg/{Platform}Pkg/
├── Include/Target_cust.h                    # 平台全局配置
├── Library/
│   ├── DDRTargetLib/
│   │   ├── ddr_external_api.c               # ddr_abort() 实现
│   │   └── ddr_target.c                     # DDR 目标平台适配
│   ├── DSFTargetLib/                        # DSF DDR 训练库
│   │   └── boot/ddrss/src/
│   │       ├── lpddr4/                      # LPDDR4 训练代码
│   │       │   ├── ddrss_boot_training_init_lpddr4.c
│   │       │   ├── ddrss_rd_dqdqs_lpddr4.c
│   │       │   ├── ddrss_wr_dqdqs_lpddr4.c
│   │       │   ├── ddrss_rcw_lpddr4.c
│   │       │   └── ddrss_wrlvl_lpddr4.c
│   │       └── common/
│   │           ├── ddrss_dcc.c              # DCC 校准
│   │           └── ddrss_common.c           # 通用函数
│   └── DDITargetLib/
│       └── DDITargetLib_a.inf               # DDI 构建配置
└── Settings/DSF/boot/
    ├── common/ddr_training_params.c          # abort 阈值配置
    └── lpddr4/target_config_lpddr4.h        # DSF 训练开关
```

## LPDDR3 vs LPDDR4 判断

- 日志中 `Max Frequency = 2092 MHz` 或更高 → LPDDR4
- `Max Frequency < 1800 MHz` → 可能是 LPDDR3
- 构建时 `DSFTargetLib_a` = LPDDR4, `DSFTargetLib_b` = LPDDR3

## 构建输出路径

```
Build/{Platform}{Config}/{ImageType}/RELEASE_CLANG40LINUX/AARCH64/
├── ddi.elf / ddi_merged.elf          # DDI 镜像
├── xbl.elf / xbl_merged.elf          # SBL 镜像
└── {ModulePath}/GNUmakefile          # 各模块 Makefile
```
