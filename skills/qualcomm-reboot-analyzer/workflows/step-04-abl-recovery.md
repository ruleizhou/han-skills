# Step 4: bootloader/recovery 判定链

钉死「进 recovery」的执行链,区分三条路径。对每条 'recovery' 命令/异常轮:

## 4.1 ABL 判定证据(重启后的 bootloader 段)

```bash
grep -an -E "KeyPress:|BootReason:|Fastboot=|Recovery:|Booting into Recovery Mode|Load Image .* total time" <log>
```

- 完整 recovery 链:`Recovery:1` + `Booting into Recovery Mode via Boot` +
  **`Load Image recovery_a total time: N ms`(数百 ms 完整加载;正常轮只读
  4096B 首块头,1ms)** + kernel cmdline 带 recovery 参数
- `Recovery:0` + `Booting Into Mission Mode` = 该轮正常启动

## 4.2 recovery UI 存活证据

```bash
grep -an "recovery: Brightness" <log>
```

`127 (50%)` = UI 首帧;`63 (25%)` = 2 分钟屏保;`0 (off)` = 息屏;间隔精确
120.0s 说明 recovery 进程真实存活(ui.cpp 状态机)。测试员看到的「recovery
界面」以此为准。停留时长 = 界面无人处理的时长。

## 4.3 三条路径的判别表

| 路径 | 特征组合 | 结论 |
|------|----------|------|
| A. BCB 完整链(标准) | `reboot command 'recovery'` → 重启 → ABL `Recovery:1` → recovery UI | RescueParty L5 顶格,系统级 recovery |
| B. 用户空间出现(非标) | **内核未重启**(uptime 连续)+ ABL 该轮 `Recovery:0` + 无 BCB 写入打印,但 recovery UI 出现 | 拉起路径待查(见 Step 5),勿直接断言「工具/人工触发」 |
| C. 误判 | 有 recovery UI 打印但无 ABL 判定、无重启命令 | 就地执行或日志混淆,进 Step 5 测谎 |

**B 路径警示**(95916 的 0812 复测教训):内核未重启 ≠ 测试工具干的。
下结论前必须过 Step 5 的物证与时序测谎;过了仍无法定谳就标 L3 开放缺口。

**完成后,读取 `workflows/step-05-forensic-timing.md` 继续。**
