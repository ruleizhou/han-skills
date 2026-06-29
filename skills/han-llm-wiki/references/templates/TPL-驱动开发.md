---
title: 驱动开发模板
type: template
tags: [模板, 驱动开发]
---

# ⚙️ 驱动开发 — {{驱动名称}}

## 驱动概览

| 字段 | 内容 |
|------|------|
| **驱动名称** | |
| **驱动类型** | 字符设备 / 块设备 / 网络设备 / 平台设备 / I2C / SPI / USB / 其他 |
| **内核版本** | |
| **平台/SoC** | |
| **源码路径** | `drivers/...` |
| **设备树节点** | `dts 路径` |
| **状态** | 🔄 开发中 / 🧪 测试中 / ✅ 已合入 |
| **存放位置** | `note/10-Domains/BSP/` |

---

## 硬件基础

### 硬件连接

```
SoC 引脚 ←→ 驱动芯片/设备
  - GPIO_xx  →  RESET
  - I2C/SPI  →  DATA
  - IRQ_xx   →  INT
```

### 关键参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 通信协议 | | |
| 地址/片选 | | |
| 时钟频率 | | |
| 工作电压 | | |
| 中断号 | | |

### 参考文档

| 文档 | 路径/链接 |
|------|-----------|
| Datasheet | |
| Reference Manual | |
| Application Note | |

---

## 驱动架构

### 软件框图

```
┌─────────────┐
│   用户空间    │  HAL / 测试工具
├─────────────┤
│  VFS / 框架   │  sysfs / char / misc / input ...
├─────────────┤
│  驱动核心层   │  probe / remove / suspend / resume
├─────────────┤
│  硬件操作层   │  regmap / i2c_transfer / spi_sync
├─────────────┤
│    硬件       │
└─────────────┘
```

### 核心数据结构

```c
// 驱动私有数据（示例）
struct xxx_priv {
    struct device *dev;
    struct regmap *regmap;
    // ...
};
```

### 核心流程

#### 初始化流程（probe）

```
probe()
  ├─ devm_kzalloc()          // 分配私有数据
  ├─ parse_dt()              // 解析设备树
  ├─ regulator_get()         // 电源
  ├─ clk_get() / clk_prepare_enable()
  ├─ gpio_request()          // GPIO
  ├─ request_irq()           // 中断注册
  ├─ regmap_init()           // 寄存器访问
  ├─ xxx_hw_init()           // 硬件初始化序列
  ├─ device_register()       // 注册设备节点
  └─ sysfs_create_group()    // 创建 sysfs 属性
```

#### 数据流

```
用户 read/write / ioctl
  → vfs 调用
    → 驱动 xxx_read/xxx_write/xxx_ioctl
      → 硬件操作
```

---

## 设备树配置

```dts
// {{驱动名称}} 设备树节点
xxx@00 {
    compatible = "vendor,xxx";
    reg = <0x00>;
    // ...
};
```

### 必填属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `compatible` | string | 匹配驱动 |
| `reg` | u32 | I2C/SPI 地址 |
| | | |

### 可选属性

| 属性 | 默认值 | 说明 |
|------|--------|------|
| | | |

---

## 关键寄存器

| 偏移 | 名称 | 位域 | 说明 |
|------|------|------|------|
| 0x00 | | | |
| 0x01 | | | |
| 0x04 | | | |

---

## 开发日志

### Phase 1：基础框架搭建

- [ ] 设备树节点添加
- [ ] 驱动骨架（probe/remove）
- [ ] 基础寄存器读写验证
- [ ] 设备节点创建

**备注：**

### Phase 2：功能实现

- [ ] 核心功能实现
- [ ] 中断处理
- [ ] 电源管理（suspend/resume）
- [ ] sysfs 调试接口

**备注：**

### Phase 3：测试与优化

- [ ] 功能测试
- [ ] 稳定性测试（长时间运行）
- [ ] 性能优化
- [ ] 代码审查与合入

**备注：**

---

## 已知问题

| # | 问题 | 状态 | 备注 |
|---|------|------|------|
| 1 | | 🔄/✅ | |
| 2 | | | |

---

## 调试技巧

### 常用命令

```bash
# 查看设备树节点
ls /sys/firmware/devicetree/base/xxx@00/

# 查看驱动绑定
ls /sys/bus/i2c/drivers/xxx/

# 寄存器dump
cat /sys/kernel/debug/regmap/xxx/registers

# 中断统计
cat /proc/interrupts | grep xxx

# dmesg 过滤
dmesg | grep -i xxx
```

### 常见问题速查

| 现象 | 可能原因 | 排查方法 |
|------|----------|----------|
| probe 失败 | 设备树/电源/时钟 | dmesg + 电源测量 |
| 通信超时 | 地址错/总线忙 | i2cdetect / 逻辑分析仪 |
| 中断不上报 | 触发模式/引脚复用 | /proc/interrupts + gpio |
| 数据异常 | 时序/位序 | 示波器/逻辑分析仪 |

---

> [!tip] 使用说明
> - 按驱动创建，文件名格式：`驱动名称-驱动.md`（如 `LP8556-背光驱动.md`）
> - 存放位置：`note/10-Domains/BSP/`
> - 开发过程中持续更新，合入后做最终整理
