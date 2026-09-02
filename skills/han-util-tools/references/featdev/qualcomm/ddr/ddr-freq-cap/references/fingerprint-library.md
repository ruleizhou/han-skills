# 降频后死机指纹库（三态判别）

> 同一根源（RPM/固件层频率数据错位）的三种死相。先分诊再动手。

## 指纹一：kernel ~5.5-6s DDR 数据腐烂（最常见）

**死点**：`qcom_dma_heap_probe`（qseecom-ta heap）附近，display/icc 投票刚触发

**ramdump 特征**：
- kernel logbuf 损坏（`kernel boot log support is not present`）或 dmesg 截断
- ipc 链表/zone 解析 exception（parser 崩溃 5+ 次）
- task 栈全是垃圾地址（`0xb6b6b6b6b6...` 模式）、垃圾 PID
- Core0 PC = `0xdeaddeaddeaddead`、寄存器全垃圾
- modules_table 里 `clk_smd_rpm` 可能尚未加载（死得更早时）

**根因**：RPM 切频查表越界（或切到未训练频点），每次切频把垃圾训练数据写进 PHY → DDR 读写持续出错 → 内存慢慢烂掉

**去向**：RPM 层 clamp（workflows/step-03-rpm.md）

## 指纹二：kernel 卡 D 状态等 RPM ACK

**死点**：`clk_smd_rpm` 模块 probe（~6s），栈：`msm_rpm_wait_for_ack → msm_rpm_send_message → clk_vote_bimc`

**特征**：**数据结构完好**（parser 正常出全部结果），init 干净地卡在 D 状态；watchdog PS_HOLD 复位

**根因**：kernel 的 INT_MAX vote（或超限 vote）让 RPM 处理时挂死不回 ACK——典型如越界吃到清零槽（PLL 参数全 0）

**去向**：kernel 四路径 cap（step-04）+ RPM clamp（step-03）

## 指纹三：boot 训练 ABORT / 训练中卡死

**死点 A（ABORT）**：`DDR ABORT: RD 1D CF ZERO EYE WIDTH, Frequency = <目标频率>` → `Error code 84` → dump 模式

**死点 B（卡死）**：RCW 完成后无输出（卡 `ddr_external_set_clk_speed` 切频）或 Read Training 中无输出（retimer 查 band 越界）

**根因**：XBL 降频联动缺失——switchboard 未给新 band 开全套（无 DCC/WRLVL 打底 → 零眼）、或 num_levels 截表导致训练内部查 band 越界

**去向**：XBL 联动清单（step-02）；ABORT 的深挖（错误码表/阈值调优）→ `debug/qualcomm/ddr/ddr-training-debug`

## 取证注意

- **QUTS 导出的 boot log 是多段 ring buffer 拼接**：段落①上次启动尾部、②本次主体、③crash 后 dump boot。先分段再定位死点，别把接缝当死点
- logbuf 损坏时以 tasks_highlight/tasks.txt 为准（dmesg 不可信）
- `modules_table` 的 srcversion 字段可确认 kernel 版本真伪（对比 commit hash）
