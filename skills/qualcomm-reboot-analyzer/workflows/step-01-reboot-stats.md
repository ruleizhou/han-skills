# Step 1: reboot command 全量分布统计 + 轮次时长排行榜

对整份串口 log 做两个统计,建立异常轮的粗定位。**这是全流程最重要的一刀。**

## 1.1 reboot command 分布

```bash
grep -a "Restarting system with command" <串口log> | awk '{gsub(/[\[\]]/,"",$2); print $2, $NF}' | sort -n
```

输出每轮的 (uptime, command)。看三件事:
- **命令种类分布**:正常轮 `''`(测试脚本驱动);`'RescueParty'` = 自愈 L4;
  `'recovery'` = L5 顶格;其他命令(如 `'kernelpanic'`、`'oem-xxx'`)单独归类
- **每种命令的出现次数与行号**(配合 `grep -an` 拿行号)
- **异常命令前后的 uptime**(用于 Step 2 事件切分)

实例(95916):5003 次 = 4999 空 + 3×'RescueParty' + 1×'recovery',概率与票面吻合。

## 1.2 轮次时长排行榜

```bash
grep -a "Restarting system with command" <串口log> | awk '{gsub(/[\[\]]/,"",$2); print $2+0, $NF}' | sort -n | tail -20
```

正常轮时长 = 测试节奏(如 80~96s)。**异常长 + `command ''` 结尾的轮 =
boot 曾卡顿但最终完成(静默 mitigation 候选,串口无痕的自愈事件)**。
阈值取测试节奏的 2.5~3 倍(如 >230s)。注意可能漏大数(rtk 管道问题),
对最大值用行号交叉验证:

```bash
grep -an "Restarting system with command" <log> | awk -F'[][]' '{u=$2+0; if(u>THRESH) print}'
```

实例(95916):588s/240s/255s 的 `''` 轮 = L1-L3 静默事件藏身处;14346s(4h)轮 =
de-escalation 清零点。

## 1.3 轮界建立

```bash
grep -an "Booting Linux on physical" <log>
```

每个异常命令的行号回溯到最近 `Booting Linux` = 该轮起点,[轮起点, 重启行] 即轮窗口,
后续步骤都按窗口取证。

**完成后,读取 `workflows/step-02-event-split.md` 继续。**
