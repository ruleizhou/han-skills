# Step 3: RPM 层切频钳位（救命改动）

## 3.1 为什么必改

RPM 是 DCVS 裁决者（本架构无 AOP）。kernel 侧 cap 只堵 AP 投票，**RPM 自身（DCVS/NPA/init）仍可能发出超过训练上限的切频请求**。RPM 切频查表循环对越界请求**没有钳位**：

```c
for (new_clk_idx = 0; new_clk_idx < ddr->misc.ddr_num_clock_levels; new_clk_idx++)
    if (new_clk_khz <= ddr->misc.clock_plan[new_clk_idx].clk_freq_in_khz)
        break;   // 请求超顶格时 idx 越界，直接拿越界槽编程 PHY
```

越界后果：索引取到未训练/垃圾训练数据（如 `rcw.bimc_tDQSCK[越界]`）写进 PHY → **kernel ~5.6s DDR 数据腐烂**（每次切频都在写坏）。

## 3.2 修法（idx + 频率双钳 + misc 回写）

在查表循环后加：

```c
if (new_clk_idx >= ddr->misc.ddr_num_clock_levels)
{
    new_clk_idx = ddr->misc.ddr_num_clock_levels - 1;
    new_clk_khz = ddr->misc.clock_plan[new_clk_idx].clk_freq_in_khz;
    ddr->misc.new_clk_in_kHz = new_clk_khz;   /* Pre 路径必须回写，整条下游链一致 */
}
```

改动点（Divar 三个）：
- `{rpm_ddrs}/src/ddrss_freq_switch_rpm.c` — `HAL_DDR_Pre_Clock_Switch`（含 misc 回写）+ `HAL_DDR_Post_Clock_Switch`（只钳 idx）
- `{rpm_ddrs}/bimc/mc230/src/lpddr4/bimc_freq_switch_lpddr4_rpm.c` — `BIMC_Pre_Clock_Switch_lpddr4`（防御性）

## 3.3 ★ 独立源码路径陷阱（本案实际栽的坑）

**RPM 有平台专属源码副本，改通用目录不生效！**

- Divar 实际编译路径：`rpm_proc/core/boot/ddr/hw/hw_sequence/rpm/**divar**/ddrss/...`
- 通用路径（`rpm/ddrss/`，无平台名）：Divar **不编译**，改了白改、刷机照死
- 本案曾改通用路径后未验证产物，白烧一轮刷机

**验证产物的硬标准（反汇编）**：

```bash
arm-none-eabi-objdump -d {rpm.elf} --start-address=<HAL_DDR_Pre_Clock_Switch 地址> \
  --stop-address=<+0x100> | less
# 查表循环后应出现 num_levels-1 钳位分支；函数体长度应比改前增加
```

确认编译路径的辅助手段：`rpm_proc/core/boot/ddr/build/rpm/rpm/*/` 下的 `.o` 文件路径反映真实编译源。

## 3.4 RPM 侧不用改的

- `hw/Divar/ddr_automode.c` 的频率→PMIC NPA 模式表：旧频率行不可达，无害
- DIT/周期训练数据消费逻辑：XBL num_levels 截表后索引自动界内

## 下一步

完成后，读取 `workflows/step-04-kernel.md` 继续。
