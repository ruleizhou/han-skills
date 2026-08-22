# 反馈闭环：沉淀经验

用户说"搞定了"/"provision 成功了"/"问题解决了"/"修好了" 时触发。回顾本次分析，沉淀"厂家×容量→参数组合"经验到 `data/patterns.json`。

## 触发信号

- "搞定了" / "修好了" / "provision 成功了" / "问题解决了" / "修复生效了" / "不再复现"

## 沉淀流程

### 1. 回顾本次案例

确认以下信息（从对话上下文 + memory-bank 提取）：
- UFS 厂家
- UFS 总容量
- 原 XML 失败原因（WB 超限 / 容量不足 / Thin 不支持 / 逻辑块 / 其他）
- 最终生效的参数组合（WB 类型/尺寸、ProvisioningType、LUN 4 是否启用、逻辑块大小）

### 2. 用 结构化提问 确认

```
question: "本次成功的配置是？"
options:
  - label: "WB 禁用 + ProvisioningType=0 + LUN4 禁用（最保守）"
  - label: "WB 禁用 + ProvisioningType=1 + LUN4 启用"
  - label: "WB 启用（Shared）+ ProvisioningType=1 + LUN4 启用"
  - label: "其他（请描述）"
```

### 3. 更新 patterns.json

读 `data/patterns.json`，按厂家+容量维度更新或新增条目：

```json
{
  "patterns": [
    {
      "vendor": "Samsung",
      "capacity_gb": 64,
      "config": {
        "bWriteBoosterBufferType": 0,
        "shared_wb_buffer_size_in_kb": 0,
        "bProvisioningType": 0,
        "lun4_enabled": false,
        "bLogicalBlockSize": "0x0c"
      },
      "root_cause": "WB Preserve 模式不支持",
      "confidence": 1,
      "last_used": "2026-07-20",
      "case_count": 1
    }
  ]
}
```

- 已有相同厂家+容量条目 → `case_count += 1`，`confidence` 按比例上调（最高 5）
- 新厂家+容量 → 新增条目，`confidence: 1`
- 若新案例与已有条目参数冲突 → 保留两条，标注 `note` 说明差异

### 4. 反哺 Step 3

下次同厂家+容量设备 provision 时，Step 3 优先查 `patterns.json`：
- 命中且 confidence ≥ 3 → 直接用历史参数组合生成 XML，跳过逐步调参
- 命中但 confidence < 3 → 用历史参数作起点，但仍按风险排序验证
- 未命中 → 从最保守模板开始

## 输出

- 更新后的 `data/patterns.json`
- 告知用户：经验已沉淀，下次同厂家同容量设备可直接复用

**反馈闭环完成。如需重新执行分析从 Step 0 开始。**
