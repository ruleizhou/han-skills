# Step 5: 联刷验证

## 5.1 刷机矩阵（三层同代际联刷）

| # | 镜像 | 分区 | 可否单独刷 |
|---|------|------|-----------|
| 1 | `xbl.elf` / `xbl_config.elf` | XBL | ✗（见下） |
| 2 | **`rpm.mbn`**（注意取平台目录如 `divar/sdm_ddr4/RF2K/`） | RPM | ✗ |
| 3 | `boot.img` / `dtbo.img`（含驱动 + overlay） | Boot | ✗ |

**只刷 XBL+kernel 不刷 RPM 仍会死机**（RPM clamp 是开机硬依赖）。

## 5.2 开机 log 判据

XBL 串口 log：
- `Max Frequency = 新值 MHz`
- 训练起点 = 新值（如 `Write DCC training PRFS 6 and Frequency 1804800`）
- 新 band 全套训练字样齐全（DCC / WRLVL / RD 2DVCF+HPVREF / WR 2D_vcf）
- `END: DDR training` → `DDR: End of HAL DDR Boot Training` → UEFI 走完

Kernel log：
- 通过 ~5.5-6s 的 `qcom_dma_heap_probe` / `clk_smd_rpm` 区域（历史死点）
- `clk_smd_rpm` 模块 probe 完成（ramdump 的 modules_table 不再是 `MODULE_STATE_COMING`）

## 5.3 异常时取证（若仍死机）

- 抓 ramdump，按 Step 1.3 清单取证
- `DDR_DATA.BIN` 与上次 dump 对比：差异 ~1.5%（如 178/12288 字节）= 训练数据健康基线
- Core0 PC 若为 `0xdeaddeaddeaddead`/垃圾 = 数据腐烂仍在 → 回 Step 3 查 RPM clamp 是否真编进产物

## 5.4 运行时频率达标验证（进系统后）

- devfreq/DDR 频率节点确认实际运行频率 ≤ 目标值
- 压力场景（display on / GPU / 多媒体）观察是否有瞬时超限（RPM clamp 应钳住）

## 下一步

验证通过 → `workflows/step-06-report.md`；失败 → 回分诊（Step 1）。
