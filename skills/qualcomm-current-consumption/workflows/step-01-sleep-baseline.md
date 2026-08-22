# Step 1: 睡眠基线（adb / 已有 stats）

在 **USB 仍连接** 时采集（或使用用户已粘贴的 stats）。测流会拔 USB，本步必须先完成。

> **一键采集**：adb 在线时优先跑 `scripts/capture_sleep_baseline.sh [OUTDIR]`——
> 一次打包本步 + step-03/04 全部读节点，产出 `SUMMARY.md`（含分层自动初判），
> 拔 USB 测流前必跑；电流表读数稳定后以 `MEASURED_MA=<mA>` 复跑补填。
> 手动逐条采集按下方 1.1–1.3 执行。

## 1.1 必读

```bash
ls /sys/kernel/debug/qcom_sleep_stats/
cat /sys/kernel/debug/qcom_sleep_stats/aosd
cat /sys/kernel/debug/qcom_sleep_stats/cxsd
cat /sys/kernel/debug/qcom_sleep_stats/ddr
cat /sys/kernel/debug/qcom_sleep_stats/apss
# 按平台存在性读取 adsp/cdsp/wpss/modem
cat /sys/power/mem_sleep
```

## 1.2 UFS（若节点存在）

```bash
UFS=/sys/devices/platform/soc/1d84000.ufshc   # 路径以机型为准
cat $UFS/spm_lvl $UFS/spm_target_dev_state $UFS/spm_target_link_state
cat $UFS/rpm_lvl $UFS/rpm_target_dev_state $UFS/rpm_target_link_state
cat $UFS/auto_hibern8
```

`spm_lvl`：3=SLEEP+HIBERN8；5=POWERDOWN+OFF（通常最深）。

## 1.3 分层判定（写入上下文）

| 条件 | 结论标签 |
|:---|:---|
| aosd=0 且 cxsd>0 且 ddr>0 | `CLASS_AOSS_STUCK` |
| cxsd=0 或 ddr=0 | `CLASS_CX_DDR_BLOCKED` |
| 子系统 Count 全 0 | `CLASS_SS_AWAKE` |
| mem_sleep 非 deep / 仅 s2idle 测流 | `WARN_NOT_DEEP` |

累计时长约：`AccumulatedDuration / 19.2e6` 秒（qtimer）。

无 adb 时：若用户粘贴了 stats，直接填表；否则标记 `BASELINE_MISSING`，后续依赖 AOP dump。

**完成后，读取 `workflows/step-02-aop-hansei.md` 继续。**
