# Step 0: 收集信息

用 `AskUserQuestion` 逐步收集 DDR 训练失败的必要信息，一次一问。

## 0.1 收集 UART 日志

询问用户提供 UART 启动日志（完整或关键片段）。最低要求：
- `IMAGE_VARIANT_STRING` 行（平台识别）
- `Error code` 行
- 最近的 `SMALL_EYE_*` 日志（如有）
- `do_ddr_training, Start` 到 `Error code` 之间的所有行

**如果用户没有日志**：询问设备型号（如 MT582），根据 platform-mapping.md 推断平台。

## 0.2 确认场景

用 `AskUserQuestion` 确认测试场景：

```
question: "当前是什么测试场景？"
header: "测试场景"
options:
  - label: "QDUTT DDI DDR 测试"
    description: "通过 QDUTT 工具加载 ddi.elf 测试 DDR"
  - label: "正常冷启动"
    description: "普通开机启动，未加载 DDI"
  - label: "其他场景"
    description: "用户自定义描述"
```

## 0.3 确认已尝试的修复

询问用户是否已经尝试过修改（如改过阈值、加过日志等），避免重复工作。

## 下一步

完成后，读取 `workflows/step-01-parse-error.md` 继续。
