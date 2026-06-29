# 反馈闭环

用户已发出"完成/解决"信号，现在回顾历史、整理链路、存档案例、更新模式库。

## 步骤 1：回顾本次过程

从当前对话历史中提取关键信息：

- 问题描述（传输方向、文件大小、速度差异）
- 日志提取的精确耗时数据
- 协议判断（BOT/UAS、USB 速度等级）
- 内核参数检查结果
- 根因分析结论
- 修复方案及效果
- 相关的代码路径

如果对话历史中找不到完整信息，用 `AskUserQuestion` 向用户确认关键细节。

## 步骤 2：呈现回顾

将所有分析轮次按时间排序，呈现给用户：

```markdown
## 回顾

| # | 阶段 | 关键发现 |
|---|------|---------|
| 1 | 数据提取 | <从 logcat 提取的精确耗时> |
| 2 | 协议检查 | <BOT/UAS, 速度等级> |
| 3 | 参数检查 | <max_sectors, can_queue, IMOD 等> |
| 4 | 根因分析 | <结论> |
| 5 | 修复方案 | <采用方案及效果> |
```

## 步骤 3：确认最终结果

用 `AskUserQuestion` 让用户确认哪些部分是有效的：

```
question: "以上分析过程中，哪部分的结果是正确的/有效的？"
header: "闭环确认"
options:
  - label: "全部正确"
    description: "整个过程的分析和结论都是正确的"
  - label: "部分正确"
    description: "有些步骤有效，有些需要调整"
  - label: "都不对"
    description: "实际结果与以上分析都不符"
```

## 步骤 4：存档案例（双格式）

同时生成 **JSON** (机器索引) 和 **Markdown** (人类阅读) 两份案例文件。

### 4.1 JSON 格式

写入 `data/cases/<YYYYMMDD-HHMMSS>-usb-transfer.json`：

```json
{
  "id": "<YYYYMMDD-HHMMSS>",
  "timestamp": "<ISO8601>",
  "platform": "qualcomm",
  "input_summary": "<传输方向、文件大小、速度差异>",
  "device_info": { "vid": "<如有>", "pid": "<如有>", "product": "<如有>" },
  "measurements": {
    "read_speed_mbps": 0,
    "write_speed_mbps": 0,
    "read_duration_ms": 0,
    "write_duration_ms": 0,
    "ratio": 0
  },
  "protocol": "BOT/UAS",
  "usb_speed": "SuperSpeed/HighSpeed",
  "key_findings": ["<发现1>", "<发现2>"],
  "root_cause": "<根因>",
  "fix_applied": "<修复方案>",
  "result_assessment": "success/partial/failed"
}
```

### 4.2 Markdown 格式（输出到当前工作路径）

写入**用户当前工作目录**下 `<YYYYMMDD-HHMMSS>-usb-transfer.md`（即发起调试的工程路径，而非 skill 内部的 `data/cases/`），使用以下模板结构：

```markdown
# USB 传输性能分析报告

> **案例 ID**：<YYYYMMDD-HHMMSS>
> **平台**：Qualcomm <chip> (msm-kernel <version>)
> **日期**：<YYYY-MM-DD>
> **结论**：<一句话总结>

---

## 1. 问题描述

<问题详述，包含 U盘容量、USB 速度等级、传输协议>

## 2. 传输性能数据

| 方向 | 耗时 (ms) | 速度 (MB/s) | 进度更新次数 | 操作时间段 |
|------|----------|-------------|-------------|-----------|
| **U盘 → 设备 (读)** | X,XXX | ~XX.X | XX | HH:MM:SS → HH:MM:SS |
| **设备 → U盘 (写)** | XX,XXX | ~XX.X | XX | HH:MM:SS → HH:MM:SS |

> **读写速度比：X.XX× | 写耗时 = 读耗时的 X.XX 倍**

## 3. 协议检查

<CONFIG_USB_UAS 配置 + 运行时协议判断>

## 4. 内核参数（代码验证）

| 参数 | 文件:行号 | 值 | 影响 |
|------|----------|-----|------|
| `can_queue` | scsiglue.c:631 | **1** | ... |
| `max_sectors` | scsiglue.c:661 | **240 (120KB)** | ... |
| `max_hw_sectors` | scsiglue.c:122 | **2048 (1MB)** | ... |
| `imod_interval` | xhci-plat.c:312 | **40,000ns** | ... |
| U1/U2 节能 | dwc3-msm-core.c:3186 | ... | ... |

## 5. 根因分析

### 五维排查

| 维度 | 状态 | 证据 |
|------|------|------|
| 问题细化 | ... | ... |
| 信息收集 | ... | ... |
| 定位范围 | ... | ... |
| 时间线 | ... | ... |
| 收敛 | ... | ... |

### 三重叠加模型

```
写速度 = f( NAND物理速度, SYNCHRONIZE_CACHE频率, I/O粒度 )
```

## 6. 修复建议

| 优先级 | 方案 | 操作 | 预期效果 |
|--------|------|------|----------|
| P0 | PC 验证 | fio ... | ... |
| P1 | 增大 I/O 粒度 | echo 2048 > ... | ... |
| P2 | 换调度器 | echo none > ... | ... |

## 7. 内核代码引用

\`\`\`
drivers/usb/storage/scsiglue.c:631   → can_queue = 1
drivers/usb/storage/scsiglue.c:661   → max_sectors = 240
...
\`\`\`
```

**JSON 写入 skill 内部 `data/cases/` 供模式库自动索引和匹配；Markdown 写入用户当前工作路径供阅读和团队分享。两者必须同时生成，内容一致。**

## 步骤 5：更新模式库

更新 `data/patterns.json`：

- **success 的结果**：提取有效模式，如果已有匹配 → `confidence += 1`, `frequency += 1`；如果是新模式 → 追加 `confidence: 1`
- **failed 的结果**：对应模式 `confidence -= 1`；confidence < 0 时从 patterns.json 中移除
- 更新前后展示 diff preview 让用户 review

模式分类 (category)：
- `protocol` — 协议相关（BOT/UAS 判断）
- `kernel_param` — 内核参数相关
- `hardware` — 硬件/U盘自身特性
- `method` — 分析方法/排查技巧

## 步骤 6：更新领域知识（如适用）

如果本次过程揭示了新的领域知识或经验规则，追加到对应 step 文件的参数表或判据矩阵中。

## 步骤 7：输出闭环总结

```markdown
## 反馈闭环总结

- **任务**：<描述>
- **关键发现**：<要点>
- **案例存档**：JSON → skill `data/cases/<case_id>.json` | Markdown → 当前工程 `<case_id>.md`
- **模式库更新**：<新增/更新了哪些模式, confidence 变化>
```

---

闭环完成。该问题的知识已沉淀到 `data/cases/` 和 `data/patterns.json`，后续相似任务将获得更精准的处理线索。
