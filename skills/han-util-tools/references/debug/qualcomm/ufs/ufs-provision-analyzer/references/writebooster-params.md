# WriteBooster 参数详解

WriteBooster (WB) 是 UFS 3.0 引入的特性：UFS 内部划一块 **SLC 模式** NAND 作高速写缓存，写入先落 SLC（快），后台 GC 搬到主 TLC/QLC，提升顺序/随机写性能。

## 三个参数

### `bWriteBoosterBufferType` — WB 缓冲类型

| 值 | 名称 | 说明 |
|---:|:---|:---|
| 0 | Disable | 不启用 WB |
| 1 | Shared Buffer | 全局共享，所有 LU 共用一块 SLC 缓冲 |
| 2 | LU Buffer | 每个 LU 独享 WB 缓冲 |

### `bWriteBoosterBufferPreserveUserSpaceEn` — 保护 User LU 空间（仅 Shared 有效）

| 值 | 说明 |
|---:|:---|
| 0 | WB 缓冲从 LUN 0 容量里**扣**，LUN 0 实际可用 = 声明容量 − WB 缓冲 |
| 1 | WB 缓冲从 UFS **额外保留空间**出，不挤占 LUN 0；要求总容量 ≥ 各 LU 之和 + WB 缓冲 |

### `shared_wb_buffer_size_in_kb` — 共享 WB 缓冲大小（KB）

- 仅 `bWriteBoosterBufferType=1` 时有效
- 必须 ≤ UFS 支持的最大 WB 缓冲（`wWriteBoosterBufferMaxNAllocUnits × AllocationUnitSize`）
- 必须按 Allocation Unit 对齐
- Per-LU 的 `wb_buffer_size_in_kb` 仅 `bWriteBoosterBufferType=2` 时有效

## 跨厂家风险（最容易不兼容的项）

按风险从高到低：

1. **WB 最大尺寸差异极大**：从几十 MB 到几 GB，4GB 在很多 UFS 上远超上限
2. **Shared + Preserve 组合**：要求厂家同时支持 Shared Buffer 和 Preserve 模式
3. **有的 UFS 不支持 WB**：`bWriteBoosterBufferType` 字段为 0
4. **Allocation Unit 对齐**：不同厂家 AllocUnit 不同，未对齐会被拒绝

## 兼容性建议

| 兼容级别 | 配置 | 说明 |
|:---|:---|:---|
| 最高 | `bWriteBoosterBufferType=0`, `shared_wb_buffer_size_in_kb=0` | 禁用 WB，最保险 |
| 次高 | Shared + 小尺寸（如 256MB）+ `PreserveUserSpaceEn=0` | 从 LUN 0 扣，多数 UFS 支持 |
| 最低 | LU Buffer + 大尺寸 | 仅高端 UFS 支持 |

## 容量计算

启用 WB Preserve 模式时，UFS 总容量需求：

```
总容量 ≥ Σ(各启用 LU size_in_kb) + shared_wb_buffer_size_in_kb + LUN0 最小值
```

例：LUN4=6GB + WB=4GB + 其他LU=80MB + LUN0 剩余 → 至少 10GB+

## 查询支持

读 Device Descriptor（Query ID 0x00）：
- `bWriteBoosterBufferType`：bit0=支持 Shared，bit1=支持 LU Buffer，0=不支持
- `bWriteBoosterBufferPreserveUserSpaceEn`：1=支持 Preserve
- `wWriteBoosterBufferMaxNAllocUnits`：WB 最大尺寸（× AllocUnit 换算字节）

详见 `capability-descriptors.md`。
