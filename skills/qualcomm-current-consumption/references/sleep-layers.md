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

## Hypervisor / guest VM 层（票的隐藏委托人）

睡眠判定链在"内核 → AOP"之外还有一层**委托投票**：Gunyah hypervisor 代 guest VM 投票
（`reqs_by_master` 里 **HYP** master）、SCMI 共享轨经 VM 转发。排障时：

- **HYP 死票 = 某 guest VM 的资源残留**，hypervisor 本身几乎不主动投票。
  盘 dts 全部 `qcom,guestvm_loader` 节点（pas-id / vmid / firmware-name / memory-region），
  用固件 strings 判断该 VM 管什么资源（管 CPU 电源 ⇒ 必持 CX/MX 票）。
- **apss=0 且 s2idle**：apss 计数不涨不能单独证"没睡"（s2idle freeze 不走 AOSS 计数），
  须 cycles 差佐证真实睡眠（见 ptrn-009）。
- 常驻 guest VM 清单参考（parrot）：`trustedvm`（pas-id=28，trust_ui）、`cpusys_vm`
  （pas-id=35，CPU 电源管理，MC5616 概率待机 27mA 终因）。

## 睡眠时长与占比（权重判断前置）

- printk 时间戳 suspend 冻结：`PM: suspend entry→exit` 差**只是流程开销**。
- 真睡眠 = 同轮 `resume cycles − suspend cycles` ÷ 19.2MHz。
- **占比定权重**：睡满窗口（如 91%）电流仍高 ⇒ 主因在档位浅（AOP 不塌缩），
  唤醒源循环降级次要噪声；占比低 ⇒ 唤醒源/碎片化才是主账。
