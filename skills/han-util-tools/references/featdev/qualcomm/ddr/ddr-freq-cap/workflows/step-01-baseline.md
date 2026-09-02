# Step 1: 基线对照 + 死机指纹分诊

## 1.1 基线对照（强制项，跳过必踩坑）

**任何降频实验前，先刷"改动前原样"镜像确认基线健康。**

- 基线开机 → 环境健康，死机都是改动引发的，放心二分
- 基线也死 → 环境本身有问题（kernel 构建/其他固件），先排环境再谈降频

> 本案教训：烧了四版实验镜像后才补做基线对照，浪费两轮刷机。

## 1.2 死机指纹三态分诊（已改已死时）

若用户已带着死机现象/dump 来，先按 `references/fingerprint-library.md` 分诊：

| 指纹 | 死点 | 根因层 | 去向 |
|------|------|--------|------|
| kernel ~5-6s 数据腐烂（logbuf/链表损坏、垃圾栈、parser 崩溃） | `qcom_dma_heap_probe` 附近 | **RPM 切频写坏 PHY** | Step 3 |
| kernel 卡 D 状态 `msm_rpm_wait_for_ack`（数据结构完好） | clk_smd_rpm probe 时 | RPM 挂死不回 ACK | Step 3 + Step 4 |
| boot 训练 ABORT（`DDR ABORT: ... ZERO EYE WIDTH`、错误码 84）或训练中卡死 | XBL 训练循环内 | 训练配置层 | **转交 debug/ddr/ddr-training-debug**；若是降频联动缺失 → Step 2 |

## 1.3 dump 快速取证清单（有 ramdump 时）

- `parser_out/Small/modules_table.txt`：模块 srcversion 确认 kernel 版本是否真的换了
- `kernel_boot_log.txt` / `dmesg_TZ.txt`：死前最后一条（注意 logbuf 损坏时以 tasks_highlight 为准）
- `8A9CCF4A/DDR_DATA.BIN`（两次对比，差异 ~1.5% 属正常训练抖动 → 训练数据健康）
- DDRCS 内存搜 freq-tbl 字节序列（如 200000+547000+768000 的 LE 模式）→ 直接看 kernel 实际用的 dts 表是否生效
- 注意 QUTS 导出的 boot log 是**多段 ring buffer 拼接**（上一次启动尾部 + 本次主体 + 可能的 dump boot 段），别把段落接缝当成死点

## 下一步

分诊完成：改动指导 → `workflows/step-02-xbl.md`；仅排障 → 按 1.2 去向跳转对应 step。
