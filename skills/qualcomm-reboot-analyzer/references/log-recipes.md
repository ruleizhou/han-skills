# grep 配方集(串口大文本取证)

约定:`<log>` = 串口大文本(几百 MB 级);禁止整读,只允许 grep/sed 窗口。
rtk grep 注意:管道尾 head/tail 可能触发 signal 13 截断,统计数字要交叉验证。

## 统计类

```bash
# reboot command 全量分布(按 uptime 排序)
grep -a "Restarting system with command" <log> | awk '{gsub(/[\[\]]/,"",$2); print $2, $NF}' | sort -n

# 轮次时长排行榜(取尾部)
grep -a "Restarting system with command" <log> | awk '{gsub(/[\[\]]/,"",$2); print $2+0, $NF}' | sort -n | tail -20

# 指纹总分布(哪些轮有:拿行号)
grep -an "could not increase module refcount" <log>
grep -an "command 'RescueParty'\|command 'recovery'" <log>

# 轮界
grep -an "Booting Linux on physical" <log>
```

## 窗口取证类

```bash
# 异常轮窗口内指纹扫描(轮起点/终点来自轮界)
sed -n '<start>,<end>p' <log> | grep -acE "rc=-517|module refcount|is crashing"

# init 点名统计(哪些服务、多少次)
grep -an 'times before boot completed' <log> | sed "s/.*components '//; s/'.*//" | sort | uniq -c

# ABL 判定链
grep -an -E "KeyPress:|BootReason:|Fastboot=|Recovery:|Booting into Recovery Mode" <log> | head

# recovery UI 状态机
grep -an "recovery: Brightness" <log>

# 正常轮对照(取一个正常轮窗口跑同样指纹)
```

## 大文件技巧

- 含 NUL 字节被 grep 判 binary → 加 `-a`
- 886M 文件全量 grep 一次 ~10s 级,可接受;避免 cat 管道
- uptime 时间戳在 `[  143.877978]` 里,`awk -F'[][]'` 或 gsub 提取
- 行号↔uptime 换算:同轮内行号连续增长、uptime 单调增;跨轮以
  `Booting Linux` 归零为界

## logcat 侧

```bash
# rescue 计数(events buffer,-b all 才有)
grep -a "rescue_note" <logcat文件>

# 主机采集脚本物证(必读全文)
cat <dir>/collect_log.bat
```
