# Step 1: Trace 对比分析

对比 `port_trace_ok.txt` 与 `port_trace_error.txt`，定位失败发生在哪个 XML 包。

## 分析流程

### 1.1 确认 trace 一致性

用 `Read` 读两份 trace，确认：
- 是否用同一份 `provision_ufs.xml`（看 `--sendxml=` 和文件大小）
- 是否同一 fh_loader 版本
- 是否同一 search_path

若 XML/工具不同，先说明差异可能影响对比，再继续。

### 1.2 逐包对比 ACK/NAK

从 trace 里提取每个 `CHANNEL DATA (P00xx)` 包的响应：

| 包序 | 内容 | OK 设备 | ERROR 设备 |
|---:|:---|:---:|:---:|
| P0000 | `<configure>` | ACK/NAK | ACK/NAK |
| P0001 | `<ufs>` Header | ACK/NAK | ACK/NAK |
| P0002~P0009 | LUN 0~7 | ACK/NAK | ACK/NAK |
| P0010 | `<ufs LUNtoGrow commit="1"/>` | ACK/NAK | ACK/NAK ← 关键 |

**关键判断**：若前 N-1 个包都 ACK，只有最后一个 `commit="1"` 包 NAK，则失败发生在 **commit 阶段**（Device FW 校验整张 Config Descriptor 时拒绝）。

### 1.3 提取错误码

从 ERROR trace 里提取 `TARGET SAID: 'ERROR: ...'` 行，常见：
- `UFS Error -22 (3)` → EINVAL，参数不支持/超限/容量不足
- `Configure Failed slot 0` → UFS 控制器 slot 0 配置失败
- `Failed to configure device, type:UFS, slot:0` → 同上

查 `references/error-codes.md` 确认错误码含义。

### 1.4 计算原 XML 固定预留

从 XML 提取所有 LU 的 `size_in_kb` 和 Header 的 `shared_wb_buffer_size_in_kb`，计算固定预留合计：

```
固定预留 = Σ(各启用 LU size_in_kb) + shared_wb_buffer_size_in_kb
```

对比失败设备 UFS 总容量，若固定预留 + LUN0 最小值 > 总容量 → 容量不足是根因之一。

## 输出

形成根因假设（按概率排序），例如：
1. WB 缓冲尺寸超限（最可能）
2. 总容量不足
3. Thin Provisioning 不支持
4. 逻辑块大小不匹配

**完成后，读取 `workflows/step-02-capability-query.md` 继续（用 getstorageinfo 验证假设）。**
