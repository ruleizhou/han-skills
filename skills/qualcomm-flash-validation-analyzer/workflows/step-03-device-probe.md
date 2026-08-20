# Step 3: 设备实验采集

## 前提

adb 设备在手（Step 0 确认）。**没有设备则跳过本步**，在 Step 4 结论中标注"静态分析，待设备验证"。

命令与脚本模板全部在 `references/device-commands.md`，此处只讲实验设计与判读。

## adb 环境注意（rmt-adb 代理）

- push 不带 `-s`；复杂命令写成脚本 push 到 `/data/local/tmp/` 执行；长输出会截断
- 详见 `references/device-commands.md` 第 0 节

## 实验序列（路径 A：clock scaling）

按序执行，每步都有明确判读——**这是因果链验证矩阵，不是走过场**：

| # | 实验 | 判读 | 结论指向 |
|---|---|---|---|
| 1 | **状态快照**（governor/cur_freq/trans_stat/器件id/power_mode/runtime_status） | 器件定性 + 当前态基线 | 确认 2.x/3.x、quirk 命中、挂起态 |
| 2 | **负载行为刻画**（idle→持续负载→停止→burst，每秒采样） | 负载停 20s 不降 = 降频链问题；burst 0 切换 = 死区或挂起 | 缩小范围 |
| 3 | **userspace 强制变频二分** | 挂起态 set_freq 纹丝不动 = is_allowed=false 吞请求 | 挂起吞降频实锤 |
| 4 | **禁挂起对照**（echo on + 重跑 burst，做完恢复 auto） | 每轮恢复 +2 次 = runtime suspend 是主因之一 | 挂起归因 |
| 5 | **ftrace load 序列**（devfreq_monitor） | load 长期 5~70 徘徊 = governor 死区；仅 >70 升 / ≤5 降 | 死区归因（最有力证据） |

**实验纪律**：
- 每个实验做完**恢复现场**（governor 切回 simple_ondemand、control 恢复 auto、tracing_off）
- 不跑生产负载外的破坏性写测试（userdata 分区读可以，写谨慎）
- 有 flashval 正在跑时**不要干扰**（trace 里看到 flashval 进程就等它跑完）

## 交叉归因逻辑

- 实验 4 有效 + 实验 5 死区 → **双层根因**（挂起 + 死区），修复两者都要覆盖
- 实验 4 无效 + 实验 5 死区 → 纯 governor 参数问题
- 实验 4 有效 + 实验 5 正常穿越 → 纯挂起问题（quirk/PM 参数）

**完成后，读取 `workflows/step-04-conclude.md` 继续。**
