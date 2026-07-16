# Step 2: 加载平台代码

## 2.1 识别平台

从 UART 日志提取 `IMAGE_VARIANT_STRING`：

```
S - IMAGE_VARIANT_STRING=DivarPkgLAA
```

提取 `{Platform}Pkg` = `DivarPkg`。

详见 `references/platform-mapping.md` 获取完整平台→路径映射表。

## 2.2 读取关键文件

根据平台名称，加载以下文件（用 `Read` 工具）：

### 必读文件
1. **错误触发点**：`SocPkg/{Platform}Pkg/Library/DDRTargetLib/ddr_external_api.c`
2. **阈值配置**：`SocPkg/{Platform}Pkg/Settings/DSF/boot/common/ddr_training_params.c`
3. **DSF 开关**：`SocPkg/{Platform}Pkg/Settings/DSF/boot/lpddr4/target_config_lpddr4.h`

### 按需读取（取决于错误类型）
4. **训练入口**：`SocPkg/Library/XBLLoaderLib/sbl1_hw.c` — `sbl1_do_ddr_training()` 函数
5. **训练桥接**：`SocPkg/Library/XBLLoaderLib/sbl1_ddr_training.c`
6. **诊断日志宏**：`Library/DDRLib/common/ddr_log.h`

## 2.3 确认代码版本

对比 UART 日志中的版本号与代码：

```
S - QC_IMAGE_VERSION_STRING=BOOT.XF.4.1-00392-KAMORTALAZ-1
```

确保代码分支与日志版本匹配。不匹配时提醒用户可能存在差异。

## 2.4 确认 DDR 类型

从日志判断 LPDDR4/LPDDR3：
- `Max Frequency = 2092 MHz` → LPDDR4
- `Max Frequency < 1800 MHz` → LPDDR3

**LPDDR4 用 `DSFTargetLib_a`，LPDDR3 用 `DSFTargetLib_b`。**

## 下一步

- 如果日志中已有 `SMALL_EYE_*` 诊断 → 直接跳到 Step 5（分类根因）
- 如果无诊断日志 → 继续 Step 3（追溯 abort 触发链）
