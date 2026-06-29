# Bringup Step 3: 通用器件 Bringup 框架

## 目标

当没有对应子 skill 时，通过 6 阶段框架引导完成内核器件 bringup。
完成后进入反馈闭环，生成经验文档并引导创建子 skill。

## 阶段 1 — 需求收集（不可跳过）

用 AskUserQuestion 收集器件信息：

- **问题 1 — header: "器件信息"**
  - 器件类型、型号、接口协议（I2C / SPI / UART / MIPI / platform）
- **问题 2 — header: "参考资料"**
  - Datasheet 路径、参考驱动路径、硬件原理图

收集后：
1. 读取用户提供的参考代码路径，了解技术上下文
2. 在内核源码中搜索 compatible string 或类似器件驱动：
   ```bash
   grep -r "compatible.*<关键字>" --include="*.dts*" -l
   grep -r "<driver_name>" --include="*.c" -l drivers/
   ```

## 阶段 2 — DTS 配置

根据收集的信息，协助配置 Device Tree：

1. **compatible 属性**：匹配驱动 of_device_id 表或创建新条目
2. **reg / #address-cells / #size-cells**：I2C/SPI 地址映射
3. **interrupts**：中断配置（GIC SPI、GPIO 中断等）
4. **pinctrl**：引脚复用配置（active / suspend 状态）
5. **clocks / clock-names**：时钟源和频率
6. **regulator**：供电配置（vdd / vddio）
7. **gpio**：控制引脚（reset / enable / irq）
8. **status = "okay"**：启用节点

验证 DTS 语法：
```bash
dtc -I dts -O dtb <dts_file> -o /dev/null
```

## 阶段 3 — 驱动开发

根据接口类型选择驱动框架：

| 接口 | 驱动框架 | 注册函数 |
|------|----------|----------|
| I2C | `i2c_driver` | `module_i2c_driver()` |
| SPI | `spi_driver` | `module_spi_driver()` |
| Platform | `platform_driver` | `module_platform_driver()` |
| USB | `usb_driver` | `module_usb_driver()` |
| MIPI-DSI | `mipi_dsi_driver` | `mipi_dsi_driver_register()` |

关键实现点：
1. **of_match_table**：compatible 匹配表
2. **probe()**：资源获取（devm_kzalloc、platform_get_irq、devm_regulator_get 等）
3. **remove()**：资源释放
4. **PM ops**：suspend/resume（如需要）
5. 参考同类器件驱动代码结构

## 阶段 4 — 编译集成

1. **Kconfig**：添加配置选项
   ```kconfig
   config DRIVER_XXX
       tristate "XXX driver support"
       depends on I2C
       help
         Say Y here to enable XXX driver support.
   ```

2. **Makefile**：添加编译规则
   ```makefile
   obj-$(CONFIG_DRIVER_XXX) += driver-xxx.o
   ```

3. **defconfig**：启用配置
   ```bash
   echo "CONFIG_DRIVER_XXX=y" >> arch/arm64/configs/<platform>_defconfig
   ```

4. 编译验证：
   ```bash
   make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
   ```

## 阶段 5 — 测试验证

1. **基本功能**：probe 是否成功、设备是否注册
   ```bash
   dmesg | grep -i "<driver_name>"
   cat /sys/bus/<bus>/devices/<device>/uevent
   ```

2. **功能测试**：读写、数据流、中断响应

3. **稳定性**：长时间运行、压测

4. **常见问题排查**：
   - probe 失败 → 检查 DTS、资源冲突、时钟/供电
   - 通信失败 → 检查引脚配置、上拉电阻、总线频率
   - 中断不触发 → 检查 IRQ 号、触发方式

## 阶段 6 — 学习归档

bringup 完成后，**等待用户反馈器件是否跑通**。

- 用户发出"跑通了/bringup 完成了/器件工作正常" → 读取 `workflows/feedback-loop.md`
- 用户发出其他信号 → 继续迭代排查

---

bringup 引导完成后等待用户反馈。用户发出"跑通/完成"信号时，读取 `workflows/feedback-loop.md` 进入反馈闭环。
