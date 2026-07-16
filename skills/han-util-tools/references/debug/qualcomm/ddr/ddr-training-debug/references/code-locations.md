# 关键代码文件与路径映射

所有路径相对于 `boot_images/QcomPkg/`。

## 启动入口

| 文件 | 函数 | 作用 |
|------|------|------|
| `SocPkg/Library/XBLLoaderLib/sbl1_hw.c` | `sbl1_do_ddr_training()` | DDR 训练启动入口 |
| `SocPkg/Library/XBLLoaderLib/sbl1_ddr_training.c` | `ddr_training_entry()` | 调用 `boot_ddr_do_phy_training_init()` |

## 平台特定代码（以 DivarPkg 为例）

| 文件 | 作用 |
|------|------|
| `SocPkg/{Platform}Pkg/Library/DDRTargetLib/ddr_external_api.c` | `ddr_abort()` 函数，`ddr_external_send_data_to_ddi()` |
| `SocPkg/{Platform}Pkg/Settings/DSF/boot/common/ddr_training_params.c` | `DDRSS_set_training_params()` — 所有 abort 阈值配置 |
| `SocPkg/{Platform}Pkg/Settings/DSF/boot/lpddr4/target_config_lpddr4.h` | DSF 训练开关宏（`DSF_SMALL_EYE_DETECTION_LOG` 等） |
| `SocPkg/{Platform}Pkg/Include/Target_cust.h` | `BOOT_PROFILER_LEVEL` 等平台全局配置 |

## DSF 训练库

| 文件 | 关键行/函数 | 作用 |
|------|------------|------|
| `SocPkg/{Platform}Pkg/Library/DSFTargetLib/boot/ddrss/header/ddrss_training.h` | L323-370 `ddr_abort` 子结构 | 所有 spec-check 阈值定义 |
| `SocPkg/{Platform}Pkg/Library/DSFTargetLib/boot/ddrss/header/ddrss_training.h` | L372 `small_eye_abort` | 运行期标志 |
| `.../lpddr4/ddrss_boot_training_init_lpddr4.c` | L518-522 | **最终 small_eye_abort 检查** → 调用 `ddr_abort()` |
| `.../lpddr4/ddrss_rd_dqdqs_lpddr4.c` | L569-609 (DCC), L922-963 (眼图) | Read 训练 small_eye_abort 触发点（19处） |
| `.../lpddr4/ddrss_wr_dqdqs_lpddr4.c` | L1143-1964 | Write 训练 small_eye_abort 触发点（14处） |
| `.../lpddr4/ddrss_rcw_lpddr4.c` | L524 | RCW 训练 tDQSCK 范围检查 |
| `.../lpddr4/ddrss_wrlvl_lpddr4.c` | L765 | WRLVL delta 检查 |
| `.../common/ddrss_dcc.c` | L209-740 | DCC 校准 small_eye_abort 触发点（8处） |

## 诊断工具

| 文件 | 关键内容 |
|------|---------|
| `Library/DDRLib/common/ddr_log.h` | `DDR_UART_LOG(msg)` 宏 — 直连 UART 的诊断日志 |
| `Library/DDRLib/common/ddr_profiler.h` | `DDR_PROFILER_FEATURE` 控制 `ddr_printf` 路由 |
| `Include/api/boot/boot_error_if.h` | L233: `BL_ERR_CORE_VERIFY = 0x0084` |

## 相关构建文件

| 文件 | 作用 |
|------|------|
| `SocPkg/{Platform}Pkg/Library/DDITargetLib/DDITargetLib_a.inf` | DDI 库构建配置，含 `-DFEATURE_DDI_IMAGE -DDDI_BUILD` |
| `SocPkg/{Platform}Pkg/LAA/DDI.dsc` | DDI 镜像平台描述 |
