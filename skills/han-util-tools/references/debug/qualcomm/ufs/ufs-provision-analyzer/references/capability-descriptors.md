# UFS 能力 Descriptor 字段

UFS 能力通过 Query Descriptor 读取。关键 descriptor 和字段。

## Device Descriptor（Query ID = 0x00）— 最关键

| 字段 | 含义 | 判断依据 |
|:---|:---|:---|
| `bNumberLU` | 支持的最大 LU 数 | — |
| `bBootEnable` | 是否支持 Boot LUN | 1=支持 |
| `bDescrAccessEn` | Descriptor 访问 | 0=只读，1=可改 |
| `bInitActivePowerMode` | 初始 Active 电源模式 | — |
| `bInitInactivePowerMode` | 初始 Inactive 电源模式 | — |
| `bHighPriorityLUN` | 高优先级 LU | — |
| `bSecureRemovalType` | 安全擦除类型 | — |
| `bInitActiveICCLevel` | 初始电流等级 | — |
| `wPeriodicRTCUpdate` | RTC 周期更新 | — |
| `bWriteBoosterBufferType` | 支持的 WB 类型 | bit0=Shared，bit1=LU Buffer，0=不支持 WB |
| `bWriteBoosterBufferPreserveUserSpaceEn` | 是否支持 Preserve | 1=支持 |
| `wWriteBoosterBufferMaxNAllocUnits` | WB 最大尺寸（alloc unit 计） | × AllocUnit = 实际字节 |
| `dWriteBoosterBufferMaxAllocUnitId` | WB 最大 alloc unit ID | — |
| `bProvisioningType` | 各 LU 支持的 Provisioning | 按 LU bit 位 |
| `bSupportedReliabilityLevels` | 支持的可靠性级别 | bit 位图 |

## Geometry Descriptor（Query ID = 0x01）

| 字段 | 含义 |
|:---|:---|
| `wTotalRawCapacity` | UFS 总原始容量 |
| `wTotalDeviceCapacity` | UFS 总设备容量（扣出厂保留后） |
| `dSegmentSize` | Segment 大小 |
| `AllocationUnitSize` | Allocation Unit 大小（WB 对齐基准） |
| `bMinAddrBlockSize` | 最小可寻址块大小 |
| `bMaxInBufferSize` | 最大缓冲大小 |

## Configuration Descriptor（Query ID = 0x05）

| 字段 | 含义 |
|:---|:---|
| `bConfigDescrLock` | 是否已锁（1=已锁，不可再 provision） |
| 各 LU Unit Descriptor | 当前各 LU 配置 |

## Unit Descriptor（Query ID = 0x02 + LU 编号）

单个 LU 当前配置（size、memory type、provisioning type 等）。

## 查询方法

### 方法 A：fh_loader getstorageinfo（最简单）

```xml
<?xml version="1.0" ?>
<data>
<getstorageinfo />
</data>
```

```bash
fh_loader.exe --port=\\.\COMx --sendxml=getstorageinfo.xml \
  --search_path=<DA> --memoryname=UFS --skipstorageinit --noprompt
```

### 方法 B：QFIL GUI

QFIL → "UFS Provisioning" 对话框 → 自动读 Device Descriptor，不支持项灰掉。

### 方法 C：UPIU Query Request

Firehose shell 发 `Query Descriptor`，Descriptor ID：
- `0x00` = Device Descriptor
- `0x01` = Geometry Descriptor
- `0x02` = Unit Descriptor
- `0x05` = Configuration Descriptor

## 关键能力速查

| 想确认 | 看哪个字段 |
|:---|:---|
| 是否支持 WB | Device `bWriteBoosterBufferType` ≠ 0 |
| WB 最大尺寸 | Device `wWriteBoosterBufferMaxNAllocUnits` × Geometry AllocUnit |
| 是否支持 Preserve | Device `bWriteBoosterBufferPreserveUserSpaceEn` = 1 |
| 是否支持 Boot | Device `bBootEnable` = 1 |
| Thin Provisioning 支持 | Device `bProvisioningType` 对应 LU bit |
| 逻辑块范围 | Geometry `bMinAddrBlockSize` / `bMaxInBufferSize` |
| 总容量 | Geometry `wTotalDeviceCapacity` |
| 是否已锁 Config | Configuration `bConfigDescrLock` |
