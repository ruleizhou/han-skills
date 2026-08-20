# 待机功耗领域知识

本文件通过反馈闭环积累；下列为 MC5616 实战种子（待更多案例加固）。

## 已验证的经验规则

1. **aosd=0 + cxsd/ddr>0** → 这是「现象」不是「根因」。根因分两类：(a) 真 STUCK（某 client 异常投 /sleep/aoss）；(b) **平台设计**（netrani 等 retention 分支，CX 注定到不了 OFF）。**先查平台 `sleep.scons` 分支再定性**，勿默认 STUCK——见规则 8。
2. **无 NFC 时 gpio VEN 常高** 可贡献约数 mA；DTS disable + 拉低有效。  
3. **UFS spm 3→5** 可使 suspend Enabled regulators 变空，但不一定降电流。  
4. **STM/debug/DCC** 关掉常仅 ~1mA，且未必抬起 aosd；`persist.debug.coresight.config=stm-events` 会把 STM 拉回来。  
5. Hansei **`-t` 必须匹配芯片**（netrani），误用 845 会导致地址错位。  
6. **测流条件核查是前置门而非根因**：s2idle/USB 在位可致 aosd 假阴性，必须先核 `mem_sleep` 括号项 + 拔 USB 窗口 delta；但门控通过后（如 MC5616 20260729，deep+拔 USB 窗口 aosd 仍 0）应果断转 AOSS 主线，勿反复纠缠条件。  
7. **AOSS_STUCK 的决胜数据是「休眠中」AOP ramdump**：休眠中签名 = `sleep_stats last_entered > last_exited` + DDR 日志终止于 Collapse D4 无 Restore（MC5616 ED8F6761 实证）。但注意 hansei 可能报 `No RPMH Binary recovery found in DDR`——**RPMH/ARC/BCM/XO 投票表恢复失败时本地不可见最终挡点**，勿臆造子系统投票，应升级平台 CE 用内部工具解析，并先做免 dump 判别实验（debug 干净化、关 WiFi）。

8. **netrani/clarence/fillmore 平台 CX 注定 retention（非故障）**：AOP `sleep.scons` 编译期把这几颗编进 `arc_assisted_cx_retention` 分支（waipio/8350/kailua 走 `arc_assisted_cx_collapse`）；`cx_ret` boot 期 `aop_cx_ret_init` **无条件永久投 `cx.lvl=16`**（`RAIL_VOLTAGE_LEVEL_RET`，`pwr_utils_lvl.h:32`），CX 到不了 OFF → 最深睡序列 `"ddr cxsdaosd"` 卡「CX off」环 → aosd 恒 0。反汇编坐实（netrani `aop_cx_ret_init@0x80820720`：`movs r1,#16; blx unpa_issue_request`）。**诊断信号**：npa-dump 见 `cx.lvl` 被 `cx_ret` 钉 retention 且 `adb_vote=0` → 即查 `sleep.scons` 的 `MSM_ID` 分支，而非当 STUCK 追。无 runtime 开关，改需高通动 scons。配套 errata：`AOSS_0C_ARC_MITIG`(QCTDD07042657)、`tme_vdu_wa`(QCTDD07464631)。

9. **adb 在线累计统计 ≠ 休眠快照**：`qcom_sleep_stats/*`（含 `ddr_stats` 的频率分布）是**开机累计全时段**值，非休眠快照。休眠诊断必须用「拔 USB 浸泡窗口 delta」，不能用绝对值/频率分布直接推断休眠态——曾误把 `ddr_stats` 的 2736MHz 占 46%（实为 active 亮屏跑应用的正常高频）当「休眠 DDR 高频空转」写进报告，被纠正。休眠态 DDR 实为 D4(off)，须由干净 dump 佐证。

10. **「USB 连着就进不了真深睡」——测流第一铁律**：USB 在位（adb / 充电 / 数据任一）→ USB 控制器 `ssusb` 全程 active（`active_since` 不释放）+ **持 XO 投票**（XO 时钟不关则进不了 deep suspend）→ aosd **必为 0**、底流抬高；且 adb 在线采的 sleep_stats / wakeup_sources / ddr_stats 全是「在线行为」，**不代表休眠态**。**测流 / 休眠诊断必须物理拔掉所有 USB**，只留串口 + 外接电流表；要读 adb stats，读完再拔，浸泡窗口必须无 USB。

## 待验证的观察

- 对标机同场景 aosd 是否非 0（区分策略 vs 硬件）。  
- **netrani `arc_assisted_cx_retention` 能否改 `arc_assisted_cx_collapse`**（让 CX 可 off → 进 aosd）？取决于 TME/VDU errata 是否允许（问高通 CE）。  
- AOSS 常开岛具体挡点（PDC/QMP/板级）。  

## 平台/环境特定知识

| 平台 | AOP -t | 备注 |
|:---|:---|:---|
| SM6450P / Parrot | netrani | MC5616 已验证 |
