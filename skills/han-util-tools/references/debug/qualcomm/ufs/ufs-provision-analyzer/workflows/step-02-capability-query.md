# Step 2: UFS 能力查询

用 `getstorageinfo` 或 UPIU Query Request 读 UFS Device/Geometry Descriptor，验证 Step 1 的根因假设。

## 查询方法

### 方法 A：fh_loader 跑 getstorageinfo（最简单）

写一个只调 getstorageinfo 的 XML：

```xml
<?xml version="1.0" ?>
<data>
<getstorageinfo />
</data>
```

跑：
```bash
fh_loader.exe --port=\\.\COMx --sendxml=getstorageinfo.xml \
  --search_path=<DA 路径> --memoryname=UFS --skipstorageinit --noprompt
```

target 回包含 Device Descriptor + Geometry Descriptor。

### 方法 B：QFIL GUI

QFIL → "UFS Provisioning" 对话框 → 进入时自动读 Device Descriptor，WB 支持项会显示（不支持的灰掉）。

### 方法 C：UPIU Query Request

在 Firehose shell 发 `Query Descriptor` 命令，Descriptor ID：
- `0x00` = Device Descriptor
- `0x01` = Geometry Descriptor
- `0x05` = Configuration Descriptor

## 关键字段速查

读 `references/capability-descriptors.md` 获取完整字段表。关键确认项：

| 想确认 | 看哪个字段 | 判断 |
|:---|:---|:---|
| 是否支持 WB | Device `bWriteBoosterBufferType` | ≠ 0 即支持 |
| WB 最大尺寸 | Device `wWriteBoosterBufferMaxNAllocUnits` × Geometry AllocUnit | 对比 XML 的 `shared_wb_buffer_size_in_kb` |
| 是否支持 Preserve | Device `bWriteBoosterBufferPreserveUserSpaceEn` | =1 才能用 `PreserveUserSpaceEn="1"` |
| 是否支持 Boot | Device `bBootEnable` | =1 |
| Thin Provisioning 支持 | Device `bProvisioningType` per LU bit | 对应 LU bit 置位才支持 |
| 逻辑块范围 | Geometry `bMinAddrBlockSize` / `bMaxInBufferSize` | 对比 XML `bLogicalBlockSize` |
| 总容量 | Geometry `wTotalDeviceCapacity` | 对比固定预留合计 |
| 是否已锁 Config | Configuration `bConfigDescrLock` | =1 则不可再 provision |

## 验证 Step 1 假设

按 Step 1 的根因假设排序，逐项用 descriptor 字段验证：
1. WB 缓冲尺寸超限？→ 对比 `wWriteBoosterBufferMaxNAllocUnits × AllocUnit` vs XML `shared_wb_buffer_size_in_kb`
2. 总容量不足？→ 对比 `wTotalDeviceCapacity` vs 固定预留合计
3. Thin 不支持？→ 查 `bProvisioningType` 对应 LU bit
4. 逻辑块不匹配？→ 查 `bMinAddrBlockSize`

## 输出

确认根因（可能多项并存），列出哪些参数需要调整。

**完成后，读取 `workflows/step-03-param-tuning.md` 继续（按风险排序调参 + 生成 XML）。**
