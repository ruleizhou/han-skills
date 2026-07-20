# UFS Provisioning XML 参数详解

> 完整版见工作区 `UFS_Provisioning_参数说明.md`。本文件为 skill 内置速查。

## Header 全局参数

| 参数 | 类型 | 含义 | 取值 |
|:---|:---|:---|:---|
| `bNumberLU` | u8 | 声明 LU 数 | 0=由 LU 标签数决定；1~8=显式 |
| `bBootEnable` | u8 | 启用 Boot LUN | 0=禁用，1=启用 |
| `bDescrAccessEn` | u8 | Descriptor 访问 | 0=只读，1=可改写 |
| `bInitPowerMode` | u8 | 初始电源模式 | 0=Active，1=Sleep |
| `bHighPriorityLUN` | u8 | 高优先级 LU | 0x0~0x7 |
| `bSecureRemovalType` | u8 | 安全擦除类型 | 0=不强制，1~3 递增强度 |
| `bInitActiveICCLevel` | u8 | 初始电流等级 | 0=最低，值越大电流越大 |
| `wPeriodicRTCUpdate` | u16 | RTC 周期更新（秒） | 0=主机写，>0=周期秒数 |
| `bConfigDescrLock` | u8 | 锁 Config Descriptor | 0=未锁，1=锁定后不可再改 |
| `bWriteBoosterBufferPreserveUserSpaceEn` | u8 | WB 保护 User LU 空间 | 0=从 LUN0 扣，1=额外保留（见 writebooster-params.md） |
| `bWriteBoosterBufferType` | u8 | WB 类型 | 0=禁用，1=Shared，2=LU Buffer |
| `shared_wb_buffer_size_in_kb` | u32 | 共享 WB 缓冲（KB） | 仅 type=1 有效，≤ 最大 WB 缓冲 |

## Per-LU 参数

| 参数 | 类型 | 含义 | 取值 |
|:---|:---|:---|:---|
| `LUNum` | u8 | LU 编号 | 0~7 |
| `bLUEnable` | u8 | 启用 LU | 0=禁用，1=启用 |
| `bBootLunID` | u8 | Boot LU 标识 | 0=非 Boot，1=Boot A，2=Boot B |
| `size_in_kb` | u32 | LU 容量（KB） | LUN0 的 4096 是占位，实际由 LUNtoGrow 决定 |
| `bDataReliability` | u8 | 数据可靠性 | 0=不强制，1=掉电保护，2=更严格 |
| `bLUWriteProtect` | u8 | 写保护 | 0=RW，1=RO，2=永久 RO（FUSE） |
| `bMemoryType` | u8 | 内存类型 | 0=Normal，1=Code，2=OTP，3=Boot |
| `bLogicalBlockSize` | u8 | 逻辑块大小 | 0x09=512B，0x0a=1KB，0x0b=2KB，0x0c=4KB |
| `bProvisioningType` | u8 | Provisioning 类型 | 0=Default，1=Conventional，2=Thin，3=Space Efficient（见 bprovisioning-type.md） |
| `wContextCapabilities` | u16 | Context 位图 | 0=无特殊（一般保持） |
| `wb_buffer_size_in_kb` | u32 | LU 专属 WB 缓冲 | 仅 type=2 有效，0=不分配 |
| `desc` | string | 描述 | 不影响配置 |

## Commit 参数

| 参数 | 含义 | 取值 |
|:---|:---|:---|
| `LUNtoGrow` | 哪个 LU 吃剩余空间 | 0=LUN0（"Rest of device"） |
| `commit` | 提交配置 | 1=写入并生效，0=只校验 |

**关键**：commit="1" 触发 Device FW 校验整张 Config Descriptor，参数不支持的错误在此暴露（典型 EINVAL -22）。
