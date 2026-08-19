# Step 5: 时序测谎与物证核验

对任何「谁触发了 X」的候选假说,先过本步骤的测谎三件套,再谈采信。

## 5.1 物证必查

- **主机侧采集/驱动脚本全文必读**(collect_log.bat/sh、apk 驱动脚本)。
  只认命令清单里的实际行为:`adb wait-for-device` + `adb logcat` 就是纯被动
  采集,无 reboot/recovery/shell 即无嫌疑。1.4K 的脚本推翻过一整条假说链。
- 主机侧若有 shell 历史/操作记录,一并核。

## 5.2 物理时序不等式

用系统自身的物理时序做测谎仪:
- **USB 枚举不等式**:`USB_STATE=CONNECTED` → `CONFIGURED` 的完整枚举需秒级
  (如 6.5s);若某事件在 CONNECTED 后 <枚举时长 内发生(如 1.77s)且依赖
  adb 通道 → **人工和脚本都来不及,假说死**
- **进程启动时延**:UI 首帧距进程 exec 有初始化时延(秒级);若「事件 A →
  UI 首帧」间隔 < 该时延,则进程启动与 A 无因果或早已启动
- **状态机精确性**:真实进程的状态机节拍精确(如 Brightness 127→63 恰 120.0s);
  节拍乱的「UI」是日志混排,不是活进程

## 5.3 ratelimit 盲区意识

- 查 `N lines suppressed due to ratelimiting`:被吞量级(95916 见 51348 行)
  决定串口证据的可见度下限——**串口上「没有」≠「没发生」**
- userspace 的 system_server/zygote 重启、framework 卡死,printk 通道基本不可见;
  这类「静默卡死」的串口特征就是「开机流程正常 + 长时间零输出 + adbd 未上线」
- 异常轮无 log_round_N+1(主机阻塞在 wait-for-device)= adbd 从未上线的旁证

## 5.4 输出

把每个候选假说标注为:物证排除 / 时序排除 / 存活(进结论)/ 待复测定谳。
**测试员/工具链有嫌疑的假说,没有物证或时序支持,禁止写进结论**——
这是对测试团队的基本公平。

**完成后,读取 `workflows/step-06-report.md` 继续。**
