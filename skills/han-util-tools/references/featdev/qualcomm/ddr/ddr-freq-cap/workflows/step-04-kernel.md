# Step 4: Kernel 层 BIMC 投票封顶（双保险）

## 4.1 投票路径全景（共四条，都要 cap）

kernel 侧 DDR 频率投票不止一条路，**只堵 probe 的 INT_MAX 是不够的**：

| # | 路径 | 位置 | 触发时机 | 未 cap 的后果 |
|---|------|------|----------|--------------|
| 1 | `rpm_smd_clk_probe` / `clk_smd_rpm_resume` 的 `clk_vote_bimc(INT_MAX)` | clk-smd-rpm.c | 模块加载 ~6s / suspend 恢复 | RPM 收极大值切到未训练频点 → kernel 卡 `msm_rpm_wait_for_ack` |
| 2 | **`clk_smd_rpm_set_rate`**（icc 带宽换算） | clk-smd-rpm.c | display probe ~5.5s 等 | `qcom,bengal-bimc` interconnect 用 `RPM_SMD_BIMC_CLK` 时钟，util-factor 把带宽换算成频率，**不查 ddr_freq_table** → DDR 数据腐烂 |
| 3 | `clk_smd_rpm_round_rate` | clk-smd-rpm.c | 框架一致性 | round 与 set 不一致 |
| 4 | prepare/unprepare | clk-smd-rpm.c | — | 用 `r->rate` 缓存（set_rate 已 clamp，天然安全，无需改） |

## 4.2 推荐实现（可选 dts 属性，缺省原行为）

```c
/* 文件级变量（定义放在 set_rate 之前，编译器才认） */
static u32 clk_smd_rpm_bimc_max_rate = INT_MAX;

/* probe 里读可选属性（of_property_read_u32 失败不修改变量 → 缺省 INT_MAX） */
of_property_read_u32(pdev->dev.of_node, "qcom,bimc-max-rate",
                     &clk_smd_rpm_bimc_max_rate);

/* set_rate / round_rate 入口 clamp（判 BIMC：MEM_CLK && clk_id==0）*/
if (r->rpm_res_type == QCOM_SMD_RPM_MEM_CLK && !r->rpm_clk_id &&
    rate > clk_smd_rpm_bimc_max_rate)
    rate = clk_smd_rpm_bimc_max_rate;
```

**vote 单位是 Hz 不是 kHz**（kernel clk 框架一路原样传给 RPM）：1804800 kHz = `1804800000`。

## 4.3 dts 侧配套

板级 overlay（如 `khaje-idp-pm7250b-overlay-mt582-ddr-fmax.dtsi`）：

```dts
&rpmcc {
    qcom,bimc-max-rate = <1804800000>;
};

&ddr_freq_table {           /* memlat governor 的表：删掉超限档 */
    qcom,freq-tbl = < 200000 >, ... < 1804000 >;
};
&qcom_memlat { ... }        /* cpufreq-memfreq 映射表同步封顶 */
```

## 4.4 验证 dtbo 是否真生效

不信任刷机结果时，在 ramdump 的 DDRCS 里搜 freq-tbl 字节序列（前几个频率值的 LE 模式），直接看到 kernel 实际用的表内容。

## 下一步

完成后，读取 `workflows/step-05-verify.md` 继续。
