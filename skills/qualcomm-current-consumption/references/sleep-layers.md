# 睡眠分层

## 内核 `qcom_sleep_stats`

| 节点 | 含义 |
|:---|:---|
| `aosd` | AOSS deep sleep |
| `cxsd` | CX sleep / collapse |
| `ddr` | DDR power collapse |
| `apss` / `adsp` / `cdsp` / `wpss` | 各子系统睡眠统计 |

`mem_sleep` 含 `s2idle [deep]` 时，**方括号项才是当前生效档**（重启后默认回落 s2idle，勿凭用户口径）。

## 测流条件前置核对（先于一切根因判定）

1. **模式**：`cat /sys/power/mem_sleep` 必须为 `[deep]`；UART 里 `suspend entry (s2idle)` 即污染。
2. **USB**：USB 在位（如 `sys.usb.config=diag,adb`）会持 XO 投票，**AOSD 物理上必然进不去**，aosd=0 属预期，且 PHY/VBUS 抬高底流。干净条件 = deep + 拔 USB + 熄屏。
3. 条件不干净时得到的「13mA / aosd=0」不得直接下 `CLASS_AOSS_STUCK` 根因结论，先修条件复测。

## 典型判定

- **aosd=0 且 cxsd>0 且 ddr>0**：CX/DDR 通，AOSS 未进 → `CLASS_AOSS_STUCK`（前提：测流条件已干净）  
- 子系统都有 Count：不要再怀疑「子系统没睡」为主因  
- 时长：`AccumulatedDuration / 19.2e6` ≈ 秒（qtimer）

## AOP `sleep_stats.txt`

应与内核 aosd/cxsd/ddr **同故事**；NPA `/sleep/aoss=0` 强化 AOSS 未投票。
