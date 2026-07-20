# 错误码速查

UFS Provisioning commit 阶段常见错误码。

## 错误码表

| 错误码 | 含义 | 可能原因 | 处理 |
|:---|:---|:---|:---|
| `-22` (EINVAL) | Invalid argument | Config Descriptor 参数不支持/超限/容量不足 | 按风险排序调参（见 step-03） |
| `-1` (EPERM) | Operation not permitted | Config Descriptor 已锁（`bConfigDescrLock=1`） | 无法再 provision，需换设备或解锁 |
| `-5` (EIO) | I/O error | UFS 硬件故障 / 通信错误 | 检查硬件，非配置问题 |
| `-12` (ENOMEM) | Out of memory | Device FW 内存不足 | 重试，或减少 LU 数 |
| `-28` (ENOSPC) | No space left on device | 总容量不足 | 缩小固定 LU 或禁用 LUN 4 |

## 典型报错文本

### `UFS Error -22 (3)`
- 最常见，commit 阶段 Config Descriptor 校验失败
- `(3)` 是子码，指 UFS 控制器 slot 0
- 配套报错：`Configure Failed slot 0` / `Failed to configure device, type:UFS, slot:0`

### `Configure Failed slot 0`
- UFS 控制器 slot 0 配置失败
- 通常与 `UFS Error -22` 同时出现

### `NAK` (vs `ACK`)
- target 拒绝主机的 XML 包
- commit 包 NAK = 配置未生效
- 前 N-1 个包 NAK 罕见（多为 XML 语法错误）

## 排查流程

```
commit NAK (-22)
├─ 查 Device Descriptor 能力
│  ├─ 不支持 WB → 禁用 WB
│  ├─ WB 尺寸超限 → 缩小或禁用
│  └─ 不支持 Preserve → PreserveUserSpaceEn=0
├─ 仍 NAK
│  ├─ Boot/OTP 用 Thin → 改 Conventional
│  └─ 仍 NAK → 全部 ProvisioningType=0
├─ 仍 NAK
│  └─ bLogicalBlockSize 改 0x09 (512B)
├─ 仍 NAK
│  └─ LUN 4 固定大尺寸 → 缩小或禁用
└─ 仍 NAK
   └─ 查 wTotalDeviceCapacity < 固定预留（容量不足）
```

## 非 commit 阶段错误

| 阶段 | 现象 | 原因 |
|:---|:---|:---|
| configure 包 NAK | P0000 即 NAK | UFS 未进入 firehose / DA 不匹配 / 端口错误 |
| LU 标签 NAK | P0002~P0009 NAK | XML 语法错误 / LU 编号超 7 |
| 通信超时 | 无响应 | USB 线 / 端口 / 设备未连接 |
