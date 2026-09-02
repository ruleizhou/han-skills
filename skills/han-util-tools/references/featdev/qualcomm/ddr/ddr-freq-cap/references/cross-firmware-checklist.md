# 跨固件三层联动 checklist

## SMEM ABI 原则（总纲）

XBL 写、RPM/Kernel 读的 `ddrsns_share_data`（misc.clock_plan / ddr_num_clock_levels /
max_ddr_frequency / flash_params.training_data）是**跨固件契约**：
- 任何字段语义/布局变化都是三方事件，不是 XBL 内部事务
- 下游对"越界请求"没有统一 clamp 约定——**截短共享表（清零尾槽）是危险操作**，
  越界者会拿到全 0 参数（PLL 全 0 → 挂死）
- 训练数据的字段与 band 绑定（如 rcw.bimc_tDQSCK 按 clock idx 存取、rd_dcc 按寄存器组），
  单边改"在哪训练"会错位

## 三层改动对照表

| 层 | 职责 | 关键改动 | 不改的后果 |
|----|------|----------|-----------|
| **XBL** | 训练上限 + SMEM 表内容 | 训练宏 / switchboard 新 band 全套 / MAX_TRAINING_FREQ_INDEX / MIN_DTTS / DDR_MAX_FREQ（联动集） | 训练 ABORT 或 WRLVL/perbit 缺失 |
| **RPM** | 切频执行的物理钳位 | 三处查表后 idx+频率双钳 + misc 回写（**平台独立源码路径**，产物反汇编验证） | kernel 阶段数据腐烂（AP 侧 cap 管不到 RPM 自身请求） |
| **Kernel** | AP 投票上限（双保险） | clk-smd-rpm 四路径 cap + dts `qcom,bimc-max-rate` + ddr_freq_table/memlat 表 | INT_MAX vote / icc 带宽换算路径打穿 |

## 判定"最小必改集"

- **训练硬性受限**（需求明确训练 ≤X）：三层全改，联刷缺一不可
- **仅运行时受限**（训练可照旧）：基线 XBL + kernel cap 即可（已验证可开机）；
  注意 RPM 理论上仍可自主升到旧最高档——该档有训练数据所以安全，只是频率达标看场景

## 联刷硬约束

1. `xbl.elf` + `rpm.mbn` + `boot.img/dtbo.img` **同一方案代际**
2. 只刷 XBL+kernel 不刷 RPM → 必死（数据腐烂）
3. RPM 镜像取**平台目录**产物（如 `build/ms/bin/divar/sdm_ddr4/RF2K/rpm.mbn`）

## 快速验证命令

```bash
# RPM 产物验证（确认 clamp 真编进去了）
arm-none-eabi-objdump -d {rpm.elf} --start-address={Pre_Clock_Switch addr} --stop-address={+0x100}

# kernel 版本验证（ramdump 里）
grep srcversion parser_out/Small/modules_table.txt

# dtbo 生效验证（DDRCS 内存搜 freq-tbl 字节序列，如前三个频率 LE 模式）
# 训练数据健康对比：两次 dump 的 DDR_DATA.BIN 差异 ~1.5% 属正常
```
