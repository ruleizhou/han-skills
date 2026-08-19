# RescueParty 机制速查(源码实证版)

源码基准:LA.QSSI.14.0.R1(Android 14 QSSI)。行号以 MT5825 树为准,其他版本
可能微移,按函数名定位。

## 等级响应表

`RescueParty.java:350-363` getRescueLevel(mitigationCount):

| count | 等级 | 动作 | 串口可见性 |
|-------|------|------|-----------|
| 1 | RESET_SETTINGS_UNTRUSTED_DEFAULTS | 重置不可信设置 | **零痕迹** |
| 2 | RESET_SETTINGS_UNTRUSTED_CHANGES | 重置不可信变更 | **零痕迹** |
| 3 | RESET_SETTINGS_TRUSTED_DEFAULTS | 重置可信设置 | **零痕迹** |
| 4 | WARM_REBOOT | `pm.reboot(TAG)` → `reboot: Restarting system with command 'RescueParty'` | ✅ |
| ≥5 | FACTORY_RESET | `RecoverySystem.rebootPromptAndWipeUserData` → 写 misc BCB(`boot-recovery --prompt_and_wipe_data --reason=RescueParty`)+ `pm.reboot("recovery")` → `command 'recovery'` → ABL `Recovery:1` | ✅ |

## 计数规则

`PackageWatchdog.java:122-131,480-510,1692-1790`:

- `noteBoot()` 在 **system_server 每次启动**时调用(SystemServer.java:1197,
  boot 早期)——system_server crash 后 zygote 重启它,会再次走到
- **10 分钟窗口内起动 5 次**(`TRIGGER_COUNT=5 / WINDOW=10min`)= 一次
  mitigation,count+1(BootThreshold.incrementAndTest)
- count **持久化 /metadata**(saveMitigationCountToMetadata),跨内核重启保留
- 降级清零:**同一内核会话 1 小时无 mitigation**(`DEESCALATION=1h`)——
  压测节奏(90s/轮)下单轮永远活不过 1h,**count 只增不减**(压测特有放大器);
  清零点出现在 >1h 的超长轮
- boot loop 计数(PROP_RESCUE_BOOT_COUNT)是 sys. 属性,重启清零——
  所以跨轮正常重启**不**累计;触发必须靠单轮内 system_server 反复重启

## 观测证据

- events log:`rescue_note(uid): [0, count, window_ms]`(incrementAndTest 每次写)。
  正常轮恒 count=1;**count≥2 = system_server 反复重启直接证据**
- FACTORY_RESET 前置防竞态:`sys.attempting_reboot` 属性(isRebootPropertySet,
  RescueParty.java:449-452)
- L4/L5 重启都走 PowerManager——**system_server 半死时 reboot 调用可能失败**
  (logRescueException 走 logcat,串口不可见),这是「卡住却没重启」的机制出口

## 推论(排障用)

1. 串口第一条 'RescueParty' 出现时,系统已经历 ≥3 次静默 mitigation——
   **完整故障史比串口可见的多**
2. 独立事件间 count 会被 >1h 长会话清零;单轮 30min 的卡死可轮内连升多级
3. 想看全貌:查 /metadata rescue 计数或 events log;串口只给了高潮没给前传
