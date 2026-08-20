# 设备命令与实验脚本模板

> 排查用的 adb 命令速查与可直接 push 的实验脚本。全部经 MC5616 案例实锤。

## 0. adb 环境注意事项（rmt-adb 代理）

本环境 `adb` 是 `rmt-adb` alias（SSH 透传 Windows 工位机）：
- `adb push` **必须不带 `-s`** 才走 SCP 上传分支
- 复杂命令（管道/引号）会被 Windows cmd 弄坏 → **写成脚本 push 到 /data/local/tmp/ 执行**
- 长输出中段截断（`[N more lines]`）→ 别信一次拉取，分段或只拉需要的段
- 简单单命令（cat 无空格路径）透传 OK

## 1. 状态快照（sysfs）

```bash
# governor 状态与切换统计
adb -s <sn> shell su 0 cat /sys/class/devfreq/1d84000.ufshc/governor
adb -s <sn> shell su 0 cat /sys/class/devfreq/1d84000.ufshc/cur_freq      # 75000000 / 300000000
adb -s <sn> shell su 0 cat /sys/class/devfreq/1d84000.ufshc/trans_stat   # Total transition
# 器件识别
adb -s <sn> shell su 0 cat /sys/devices/platform/soc/1d84000.ufshc/string_descriptors/manufacturer_name
adb -s <sn> shell su 0 cat /sys/devices/platform/soc/1d84000.ufshc/string_descriptors/product_name
adb -s <sn> shell su 0 cat /sys/devices/platform/soc/1d84000.ufshc/device_descriptor/specification_version   # 0x0220=UFS2.2 0x0310=3.1
adb -s <sn> shell su 0 cat /sys/devices/platform/soc/1d84000.ufshc/device_descriptor/manufacturer_id        # 0x1AD=SKHynix 0x12C=Micron 0x0CD6=Hynix UFS2.2(白名单外!)
# power/clk mode
adb -s <sn> shell su 0 cat /sys/devices/platform/soc/1d84000.ufshc/qcom/power_mode     # Gear/lane/PWR
adb -s <sn> shell su 0 cat /sys/devices/platform/soc/1d84000.ufshc/qcom/clk_mode       # NORM/TURBO + 各 clk 频率
adb -s <sn> shell su 0 cat /sys/devices/platform/soc/1d84000.ufshc/qcom/turbo_support  # ml_scale 是否开
# runtime PM（吞降频元凶）
adb -s <sn> shell su 0 cat /sys/devices/platform/soc/1d84000.ufshc/power/runtime_status   # suspended?
adb -s <sn> shell su 0 cat /sys/devices/platform/soc/1d84000.ufshc/power/control          # auto/on
```

## 2. ftrace 抓 governor 决策输入（最有力的证据）

```bash
# 设备端执行（写成脚本 push）：
echo 0 > /sys/kernel/tracing/tracing_on
echo > /sys/kernel/tracing/trace
echo 1 > /sys/kernel/tracing/events/devfreq/enable
echo 1 > /sys/kernel/tracing/tracing_on
# ...跑负载 10-15 秒...
echo 0 > /sys/kernel/tracing/tracing_on
grep -a 'devfreq_monitor:' /sys/kernel/tracing/trace
```

输出形如 `devfreq_monitor: dev_name=1d84000.ufshc freq=300000000 polling_ms=60 load=42`——**load 时间序列直接对照 governor 三分支**（>70 升 / >5 保持 / ≤5 降）。

## 3. 实验脚本模板

### 3.1 负载行为刻画（idle → 持续负载 → 停止 → burst）

```sh
#!/system/bin/sh
DF=/sys/class/devfreq/1d84000.ufshc
RD=/dev/block/bootdevice/by-name/userdata
snap() { echo "$1 cur=$(cat $DF/cur_freq) trans=$(cat $DF/trans_stat | grep -i total | tr -dc '0-9') rt=$(cat /sys/devices/platform/soc/1d84000.ufshc/power/runtime_status)"; }
# idle 10s → load4k 30s → post 20s → burst(读2s停4s)×8
# load: dd if=$RD of=/dev/null bs=4k count=2000000 skip=10000 2>/dev/null &
# burst: dd if=$RD of=/dev/null bs=1M count=500 skip=... &
```

**判读**：负载停后 20s 不降频 = 降频链有问题；burst 每轮 ±0 次 = 死区或挂起。

### 3.2 userspace 强制变频二分（区分"不决策" vs "动作失败"）

```sh
#!/system/bin/sh
DF=/sys/class/devfreq/1d84000.ufshc
echo userspace > $DF/governor
echo 75000000 > $DF/userspace/set_freq; sleep 3; cat $DF/cur_freq   # 降频是否成功
echo 300000000 > $DF/userspace/set_freq; sleep 3; cat $DF/cur_freq  # 升频是否成功（挂起态会 EBUSY 不动）
echo simple_ondemand > $DF/governor   # 恢复
```

**判读**：强制设置纹丝不动 = runtime suspend 吞请求（is_allowed=false）。

### 3.3 禁挂起对照（runtime PM 归因）

```sh
echo on > /sys/devices/platform/soc/1d84000.ufshc/power/control    # 禁挂起
# ...重跑 3.1 burst...
echo auto > /sys/devices/platform/soc/1d84000.ufshc/power/control  # 恢复
```

**判读**：禁挂起后 burst 每轮恢复 +2 次（一升一降）→ runtime suspend 是降频缺失主因之一。
**警告**：禁挂起会让依赖 suspend 前置的测试项（flashval test10）-1 未执行——只做对照实验，不做规避方案。

## 4. 交叉验证矩阵模板

| 实验 | runtime suspend | 负载模式 | 观测点 | 结论指向 |
|---|---|---|---|---|
| 默认负载 | 允许 | burst | 每轮切换数 | 基线 |
| 强制变频 | 挂起中 | 无 | set_freq 生效否 | is_allowed 路径 |
| 禁挂起+burst | 禁止 | burst | 每轮切换数 | suspend 归因 |
| 禁挂起+微IO | 禁止 | 180ms+4KB | load 序列 | governor 死区归因 |
