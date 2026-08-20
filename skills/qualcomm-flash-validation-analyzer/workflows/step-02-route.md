# Step 2: 根因路径决策树

## 任务

按 Step 1 的失败类别路由到对应排查路径，并先查模式库找历史线索。

## 0. 先查模式库

读 `data/patterns.json`，按 keywords 匹配当前症状（如 "transitions 不足" → ptrn-001/002）。命中的模式作为**优先假设**带入实验设计（仍需设备证据确认，不直接跳结论）。

## 路径 A：clock scaling 计数类（主武器库，本次案例实锤）

先读 `references/ufs-clkscale-mechanism.md` 补齐机制，然后按序做**静态确认**（无设备也行）：

1. **确认驱动树**：defconfig 查 `CONFIG_SCSI_UFS_QCOM`，=m → msm-kernel 树（downdifferential=65）；读对应树的 `ufs_qcom_config_scaling_param` 核实参数
2. **核 quirks 表**：从 report/设备拿 manufacturer_id，对照 `ufs_qcom_dev_fixups[]`（注意 Hynix UFS2.2 报 0x0CD6 ≠ SKHYNIX 0x1AD）
3. **flashval 黑盒**：设备上 `strings /data/fv_test/flashval` 搜 sysfs 路径/错误串 + pylog 进度日志，确认测试负载与判定逻辑
4. **flash 定性**：specification_version（0x0220=2.2 / 0x0310=3.1）+ 4K randread IOPS 对照（慢料延迟×2 是死区主因）

静态确认后进 Step 3 做设备实验实锤。

## 路径 B：性能类（5.x 速率/IOPS 不达标）

1. 区分料本身慢 vs 环境压制（热降频、后台负载、文件系统碎片）
2. 板温（report 头）+ 串口/温度日志核查
3. 有设备时用 fio/dd 复测隔离（storage 性能测试细节调 han-flash-test skill）
4. 同料跨机对比归因料 vs 板

## 路径 C：错误计数类（err/pa_err/dl_err 非零）

1. `qcom/err_count`、`qcom/err_state`、dmesg 的 UIC/DME 错误
2. link 训练问题查 PHY（vdda 供电、lane 配置、gear 协商）
3. 疑似硬件（位翻转/链路不稳）转 DDR/硬件排查方法论

## 路径 D：RPMB / Write Booster 类

1. RPMB：pylog 里 TZ sample app 输出（key provision 状态、replay 保护）
2. WB：`attributes/wb_avail_buf`、`wb_cur_buf`、descriptor 的 wb_type/共享配额
3. 按具体报错逐案，无固定流程时坦诚告知需 case-by-case

**完成后，读取 `workflows/step-03-device-probe.md` 继续。**
