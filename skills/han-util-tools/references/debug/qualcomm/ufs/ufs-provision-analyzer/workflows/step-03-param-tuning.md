# Step 3: 参数调整与 XML 生成

按跨厂家风险排序调整参数，生成定制 `provision_ufs_*.xml`。

## 调参风险排序（从高到低）

| 风险 | 参数 | 调整方向 | 保守值 |
|:---:|:---|:---|:---|
| 高 | `shared_wb_buffer_size_in_kb` | 缩小或禁用 | `0` |
| 高 | `bWriteBoosterBufferType` + `bWriteBoosterBufferPreserveUserSpaceEn` | 禁用 WB | `0` / `0` |
| 中 | `bProvisioningType`（Boot/OTP LU 用 Thin） | 改为 Conventional 或 Default | `1` 或 `0` |
| 中 | `bLogicalBlockSize` | 改为 512B | `0x09` |
| 低 | LUN 4 等固定大尺寸 LU `size_in_kb` | 缩小或禁用 | `0` + `bLUEnable="0"` |

**原则**：一次只改一项，复跑 `commit="1"` 验证，避免多变量混淆。

## 调参决策树

```
commit NAK (-22)
├─ 先查能力（Step 2）
│  ├─ 不支持 WB → bWriteBoosterBufferType=0, shared_wb_buffer_size_in_kb=0
│  ├─ WB 最大尺寸 < XML 值 → 缩小到最大尺寸，或禁用
│  └─ 不支持 Preserve → PreserveUserSpaceEn=0（从 LUN 0 扣）
├─ 仍 NAK
│  ├─ Boot/OTP LU 用 Thin → bProvisioningType 改 1 (Conventional)
│  └─ 仍 NAK → 全部 LU bProvisioningType 改 0 (Default)
├─ 仍 NAK
│  └─ bLogicalBlockSize 改 0x09 (512B)
├─ 仍 NAK
│  └─ LUN 4 固定大尺寸 → 缩小或 bLUEnable=0 禁用
└─ 仍 NAK
   └─ 查 wTotalDeviceCapacity 是否 < 固定预留合计（容量不足）
```

## 生成定制 XML

### 从模板生成

读 `templates/provision_ufs_template.xml`（最保守配置），按设备能力逐步放开参数：

1. 复制模板为新文件 `provision_ufs_<设备标识>.xml`
2. 按能力查询结果填入支持的参数
3. 计算 `LUNtoGrow` 的 LU 应吃多少剩余空间
4. 验证固定预留合计 ≤ UFS 总容量

### 模板默认值（最保守）

```xml
<!-- Header: WB 全禁用 -->
<ufs bWriteBoosterBufferType="0" shared_wb_buffer_size_in_kb="0"
     bWriteBoosterBufferPreserveUserSpaceEn="0" ... />

<!-- 所有 LU: bProvisioningType=0 (Default) -->
<ufs LUNum="x" bProvisioningType="0" ... />

<!-- LUN 4: 默认禁用（如不需要 Protected RO） -->
<ufs LUNum="4" bLUEnable="0" size_in_kb="0" ... />
```

## 使用方法

生成 XML 后，给用户 fh_loader 命令：

```bash
fh_loader.exe --port=\\.\COMx --sendxml=provision_ufs_<设备标识>.xml \
  --search_path=<DA 路径> --memoryname=UFS --skipstorageinit \
  --noprompt --showpercentagecomplete --zlpawarehost=1
```

## 验证

provision 成功后，trace 应显示：
- 最后一个 `commit="1"` 包返回 ACK
- 末尾 `All Finished Successfully`

## 输出

- 定制 `provision_ufs_<设备标识>.xml`
- 参数调整说明（改了哪些参数、为什么）
- fh_loader 使用命令

**若用户后续说"搞定了"/"provision 成功了"/"问题解决了" → 读取 `workflows/feedback-loop.md` 沉淀经验。**

**否则：所有步骤完成。如需重新执行从 Step 0 开始。**
