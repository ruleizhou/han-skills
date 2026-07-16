# Step 4: 注入 DDR_UART_LOG 诊断日志

当无法区分具体 small_eye_abort 触发点时，添加 UART 诊断日志。

## 4.1 宏准备

首先确认 `Library/DDRLib/common/ddr_log.h` 中已有 `DDR_UART_LOG` 宏：

```c
#if defined( DDI_BUILD  ) || defined( BUILD_BOOT_CHAIN )
#define DDR_UART_LOG(msg) boot_log_message(msg)
#else
#define DDR_UART_LOG(msg)
#endif
```

**如果没有**，添加此宏（放在 `ddr_printf` 宏定义之前）。

## 4.2 批量注入日志

在每个 `training_params_ptr->small_eye_abort = 1;` 前插入 `DDR_UART_LOG(...)`：

### 策略：分阶段注入

**第一轮 — 粗分类（按训练阶段）**：

| 文件 | 替换内容 | 日志标签 |
|------|---------|---------|
| `ddrss_rcw_lpddr4.c` | 所有 `small_eye_abort = 1` 行前加 | `SMALL_EYE_ABORT: RCW` |
| `ddrss_wrlvl_lpddr4.c` | 同上 | `SMALL_EYE_ABORT: WRLVL` |
| `ddrss_dcc.c` | 同上 | `SMALL_EYE_ABORT: DCC` |
| `ddrss_rd_dqdqs_lpddr4.c` | 同上 | `SMALL_EYE_ABORT: RD_DQDQS` |
| `ddrss_wr_dqdqs_lpddr4.c` | 同上 | `SMALL_EYE_ABORT: WR_DQDQS` |
| `ddrss_boot_training_init_lpddr4.c` | `ddr_abort()` 前加 | `SMALL_EYE_FINAL: aborting boot` |

使用 `sed` 批量替换：
```bash
sed -i 's/training_params_ptr->small_eye_abort = 1;/DDR_UART_LOG("SMALL_EYE_ABORT: TAG"); &/g' file.c
```

**第二轮 — 细分类（按检查维度）**：

如果第一轮确定了训练阶段（如 RD_DQDQS），将日志进一步细分为：
- `RD_DQDQS_DCC` — DCC 校准阶段（3 处）
- `RD_DQDQS_EYE_WIDTH` — SCREEN1 眼宽检查（2 处）
- `RD_DQDQS_SETUP_HOLD` — Setup/Hold 检查（2 处）
- `RD_DQDQS_VREF_EYE` — VREF 多 pass 眼图（7 处）
- `RD_DQDQS_HP_EYE_HEIGHT` — HP VREF 眼高（1 处）
- `RD_DQDQS_EYE_HEIGHT_SCREEN2` — SCREEN2 眼高
- `RD_DQDQS_EYE_HEIGHT_MP` — MP VREF 眼高

用 `sed` 行号精确替换：
```bash
sed -i '574s/DDR_UART_LOG("SMALL_EYE_ABORT: RD_DQDQS")/DDR_UART_LOG("SMALL_EYE_ABORT: RD_DQDQS_DCC")/' ddrss_rd_dqdqs_lpddr4.c
```

## 4.3 常见编译陷阱

添加 `DDR_UART_LOG` 后可能遇到：

| 错误 | 原因 | 修复 |
|------|------|------|
| `use of undeclared identifier 'pll'` | `ddrss_common.c` 中 `pll` 声明被注释 | 取消注释 `// uint8 pll = 0;`，加 `(void)pll;` 静默 |
| `unused variable 'pll'` | `pll` 只在 no-op `ddr_printf` 中使用 | 加 `(void)pll;` |
| LibSizeCheck 失败 | `snprintf` 导致代码尺寸超限 | **`DDR_UART_LOG` 必须用纯字符串版本**（不加格式化参数） |

**关键原则**：`DDR_UART_LOG` 只接受一个字符串参数，不接收格式化参数。避免引入 `snprintf` 增加代码尺寸。

## 4.4 验证

- 重新编译 DDI Loader 目标
- 烧录并收集 UART 日志
- 确认出现 `SMALL_EYE_ABORT: XXX` 日志行

## 下一步

编译通过、收集到分类日志后 → 读取 `workflows/step-05-classify-rootcause.md`
