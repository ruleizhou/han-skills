# Step 2: 事件切分与 RescueParty 定级

把异常重启切成**独立事件**,给每个事件定 RescueParty mitigation 级别。机制详见
`references/rescue-party-mechanism.md`(先读它)。

## 2.1 事件切分判据

对每条 'RescueParty'/'recovery' 命令:
1. 找它所在轮(Step 1.3 轮界)
2. **看它的下一轮怎么结束**:
   - 下一轮以 `command ''` 结束(正常测试节奏)→ 本事件**已自愈**
   - 下一轮又是 'RescueParty'/'recovery' → 同一事件的**延续升级**
3. 两条 'RescueParty' 之间隔着大量正常轮(数千行/数千轮)→ **两个独立事件**

实例(95916):3×'RescueParty' 是 3 个独立事件(前两次均自愈),
第 3 次+'recovery' 才是连续升级对。

## 2.2 mitigationCount 推算

规则:每 10 分钟内 system_server 起动 5 次 = 一次 mitigation(count+1,持久化
/metadata);count 1/2/3 静默重置设置(无打印),4='RescueParty',≥5='recovery'。

推算模板:
- 单轮 ~140s 打出 'RescueParty' → 进入时 count 已是 3 → 此前必有 3 次静默事件
  → 去 Step 1.2 的时长排行榜找静默卡顿轮对号
- 单轮 30min(如 1797s)打出 'RescueParty' → 可能轮内 4 个窗口 4 次 mitigation
  (1797/4≈450s/次,时间自洽)
- 'recovery' 前一轮是 'RescueParty' → warm reboot 后 count 继承 +1=5,顶格
- 事件间 count 会被清零:清零条件是同一内核会话 1h 无动作 → 找 **>1h 的超长轮**
  (实例:14346s 轮)。压测节奏(90s/轮)下永不满足,故 count 跨事件只增不减

## 2.3 logcat 佐证(有 events buffer 时)

```bash
grep -a "rescue_note" <logcat文件>
```

`rescue_note(uid): [0, count, window_ms]` — count 是本轮第几次 system_server
启动计数。正常轮恒 count=1(永不触发);**找到 count≥2 即 system_server 反复
重启的直接证据**。注意:异常轮若 adbd 未起则无 logcat(盲区),找不到≠没发生。

**完成后,读取 `workflows/step-03-fingerprint.md` 继续。**
