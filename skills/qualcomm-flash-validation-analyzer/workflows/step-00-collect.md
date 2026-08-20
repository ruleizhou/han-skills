# Step 0: 收集测试结果与环境信息

## 任务

收集排查所需的三类输入，缺哪样问哪样（用 AskUserQuestion，一次问齐）：

1. **测试结果目录**：QMVS 输出（通常 `<项目>/QMVS/<平台>/<n>/`），确认有：
   - `fv_c_test_result_*.csv`（45 项结果，必需）
   - `adbid_*/report_*.csv`（含环境头：uname、build description）
   - `adbid_*/all_test_pylog_*.log`（flashval 实时进度日志）
   - 串口 log（可选，boot 段 pwr mode 证据）
2. **对照组**：是否有 PASS 的参照机结果（同平台不同料/同料不同环境）——对比是定位失败面的最快路径
3. **设备可用性**：adb 设备是否在手（`adb devices`）——手上有设备才能做实验层排查；没有则只做静态分析并告知用户局限

## 环境变量核查（防"环境一致"假象）

从 report 头部提取并对比（若有多台）：
- `uname`：内核 commit 是否相同？**本地 dirty build vs CI build 是隐形变量**，diff 两个 commit（`git log A..B` + `git diff --stat`）核对是否涉 UFS/存储
- `build description`：编译者/时间
- board temperature（温差过大影响性能项）

## 预检输出

```
- 失败项列表（来自 CSV，Step 1 精读）
- 环境差异清单（内核/DT/温度）
- 设备状态：可用（adb -s <sn>）/ 不可用
```

**完成后，读取 `workflows/step-01-parse-results.md` 继续。**
