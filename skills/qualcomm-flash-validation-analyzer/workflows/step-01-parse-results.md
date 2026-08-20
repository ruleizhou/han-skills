# Step 1: 结果解析与失败面定位

## 任务

对齐解析 CSV，把失败面收敛到具体类别。

## 1.1 CSV 解析注意

- 格式：`version,description,test_id,result_id,units,minimum,maximum,value,stdev,num_samples,test_ran,duration_sec,status`
- **description 含逗号**，`cut -d','` 会错位——用 awk 时以固定列（$3=test_id、$13=status 需验证）或直接读原文件
- `test_ran=0` + `value=-1` = 测试未执行（前置失败），与数值不达标是两类问题
- duration_sec 异常短 = 测试提前终止（黑盒内部超时/前置失败），比数值本身更有信息量

## 1.2 失败项分类路由

| 失败类别 | 典型 test_id | 特征 | 去向 |
|---|---|---|---|
| **clock scaling 计数类** | 2.x / 10.x | Transitions < 要求；duration 异常短 | Step 2 路径 A（主武器库） |
| **性能类** | 5.x（读写速率/IOPS） | 数值低于 minimum | Step 2 路径 B |
| **错误计数类** | 0.x / 8.7 / 9.7 | err count 非零 | Step 2 路径 C |
| **RPMB/WB 类** | 1.x / 11.x | Runs/GiBytes 不足 | Step 2 路径 D（按 pylog 逐案） |

**有多台对照时**：对齐两边 status，只关注差异项；PASS 项的旁证价值同样重要（如 gating/suspend 过 = 变频链路的独立开关正常，问题范围收窄）。

## 1.3 pylog 精读（失败项对应的时段）

搜失败测试的进度日志（如 `clkscale_core_test` / `clkgate_core_test`），提取：
- 进度节奏（`count X/1000` 多久 +1）
- WARN/ERROR 原文（如 "Clocks have not scaled after 10s. Did N operations" = 等待切换超时）
- 测试前置等待失败的痕迹（对应 -1/test_ran=0）

**完成后，读取 `workflows/step-02-route.md` 继续。**
