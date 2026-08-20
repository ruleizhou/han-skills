# 命令速查

## Sleep

```bash
cat /sys/kernel/debug/qcom_sleep_stats/aosd
cat /sys/kernel/debug/qcom_sleep_stats/cxsd
cat /sys/kernel/debug/qcom_sleep_stats/ddr
cat /sys/power/mem_sleep
```

## UFS

```bash
UFS=/sys/devices/platform/soc/1d84000.ufshc
cat $UFS/spm_lvl $UFS/spm_target_dev_state $UFS/spm_target_link_state
echo 5 > $UFS/spm_lvl; echo 5 > $UFS/rpm_lvl   # 验证用
```

## QDSS / debug

```bash
cat /sys/kernel/debug/debug_enabled
cat /sys/bus/coresight/devices/coresight-stm/enable_source
getprop persist.debug.coresight.config
echo N > /sys/kernel/debug/debug_enabled
echo 0 > /sys/bus/coresight/devices/coresight-stm/enable_source
setprop persist.debug.coresight.config none
```

## NFC 驱动

- ko：`nfc_i2c.ko`  
- compatible：`qcom,sn-nci`
