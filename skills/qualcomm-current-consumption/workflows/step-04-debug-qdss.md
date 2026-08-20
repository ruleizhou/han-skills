# Step 4: Debug / QDSS / Coresight

## 4.1 必查

```bash
cat /sys/kernel/debug/debug_enabled                    # 期望 N
cat /sys/devices/platform/soc/100ff000.dcc_v2/enable   # 期望 0（路径以机型为准）
cat /sys/bus/coresight/devices/coresight-stm/enable_source
cat /sys/bus/coresight/devices/coresight-tmc-etr/enable_sink
getprop persist.debug.coresight.config                 # 勿为 stm-events
getprop sys.usb.config                                 # 测流宜去掉 diag
```

列出仍开启的 source/sink：

```bash
for d in /sys/bus/coresight/devices/*; do
  e=""; s=""
  [ -f "$d/enable_source" ] && e=$(cat "$d/enable_source")
  [ -f "$d/enable_sink" ] && s=$(cat "$d/enable_sink")
  if [ "$e" = "1" ] || [ "$s" = "1" ]; then
    echo "$(basename $d) source=$e sink=$s"
  fi
done
```

## 4.2 清理（验证用）

```bash
echo N > /sys/kernel/debug/debug_enabled
echo 0 > /sys/bus/coresight/devices/coresight-stm/enable_source
echo 0 > /sys/bus/coresight/devices/coresight-tmc-etr/enable_sink
echo 0 > /sys/devices/platform/soc/100ff000.dcc_v2/enable
setprop persist.debug.coresight.config none
```

**陷阱**：`persist.debug.coresight.config=stm-events` 会让 STM 再次打开；关完必须回读确认 `enable_source=0` 再测流。

## 4.3 预期

此类清理通常仅 **~1mA** 量级；**不一定**使 `aosd` 变非 0。无 `aosd` 改善时不要停在本步当主因。

**完成后，读取 `workflows/step-05-triage.md` 继续。**
