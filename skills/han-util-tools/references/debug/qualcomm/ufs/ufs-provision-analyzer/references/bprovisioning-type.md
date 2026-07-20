# bProvisioningType 详解

`bProvisioningType` 决定 LU 物理资源如何分配。取值参考 JEDEC UFS 规范（与 SBC-4 对齐）。

## 4 种类型

| 值 | 名称 | 物理资源分配 | 逻辑 vs 物理 | TRIM 行为 |
|---:|:---|:---|:---|:---|
| 0 | Default / Not Provisioned | 不预分配（占位） | 逻辑=0 | N/A |
| 1 | Conventional（全量预分配） | commit 时一次性分配全部 block | 逻辑=物理（满） | 不释放 |
| 2 | Thin（瘦配置） | 按需分配，首次写时分配 | 逻辑≥物理（可超分） | 不主动回收 |
| 3 | Space Efficient（空间高效） | 按需分配 + TRIM 回收 | 逻辑≥物理（可超分） | 回收到共享池 |

## 详细说明

### 0 — Default / Not Provisioned
- LU 存在但不分配物理资源，仅占槽位
- 用途：占位 LU、内部测试 LU、禁用 LU
- 配合 `bLUEnable="0"` + `size_in_kb="0"`

### 1 — Conventional（全量预分配）
- commit 时 Device FW 一次性划走全部声明容量
- 优点：空间 100% 保障，性能稳定，无按需分配延迟
- 缺点：未用空间被独占
- 适用：Boot LUN、OTP、固定尺寸 Protected RO/RW

### 2 — Thin（瘦配置）
- 只声明逻辑容量，物理 block 首次写时从共享池分配
- 优点：可超分，空间利用率高
- 缺点：首次写有开销；共享池耗尽写失败
- 适用：User LUN、可变增长 RW 分区
- **跨厂家风险**：部分厂家不支持 Thin，或对 Boot/OTP LUN 用 Thin 直接拒绝

### 3 — Space Efficient（空间高效）
- Thin + TRIM 回收：trim 的 block 物理资源归还共享池
- 优点：长期写删场景空间利用率最高
- 缺点：实现最复杂，厂家支持度最低
- 适用：频繁写删分区（cache、tmp、日志）

## 选择指南

### 按 LU 用途

| LU 类型 | 推荐值 | 理由 |
|:---|:---:|:---|
| Boot LUN A/B | **1** | 启动必须保证空间 |
| OTP LUN | **1** | 一次性写满 |
| Protected RO LUN | **1** | 只读固定内容 |
| Protected RW LUN | **1** 或 **2** | 小尺寸选 1，弹性选 2 |
| User LUN（"Rest of device"） | **2** 或 **1** | Thin 可超分，要稳选 1 |
| 禁用 LU | **0** | 不分配 |

### 按兼容性优先级

1. **最高兼容**：全部用 `1`（Conventional）——所有 UFS 都支持，只要容量够就能 commit
2. **次高兼容**：固定小 LU 用 `1`，User LUN 用 `2`——大多数现代 UFS 支持
3. **最低兼容**：用 `3`（Space Efficient）——仅高端 UFS 支持

## 常见问题

- **Boot LUN 用 Thin 不合理**：启动时共享池未分配 block，读 boot 镜像失败
- **部分厂家不允许 Boot/OTP 用 Thin**：commit 直接拒绝
- **commit 报 EINVAL 且 ProvisioningType=2**：优先改为 `0` 或 `1` 重试
