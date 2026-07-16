# Step 0: 收集信息

用 **一次 `AskUserQuestion`（多问题）** 一次性收集 DDR 训练失败的全部必要信息，禁止分多次询问。

## 0.1 问题列表（合并为单次 AskUserQuestion）

| # | header | question | options |
|---|--------|----------|---------|
| 1 | 测试场景 | 当前是什么测试场景？ | QDUTT DDI DDR 测试 / 正常冷启动 / 其他场景 |
| 2 | 日志状态 | UART 启动日志情况？ | 已提供日志文件 / 设备连着可抓取 / 暂无日志 |
| 3 | 已尝试修复 | 是否已经改过参数或加过日志？ | 未做任何修改 / 已尝试调参 / 已有部分操作 |
| 4 | 源码路径 | boot_images 源码根目录路径？ | 已提供（请填写路径） / 需要帮助定位 / 暂无源码 |

> **多选规则**：四个问题合并为一次 `AskUserQuestion` 调用，`multiSelect: false`，四个问题各一个 `header`。注意 AskUserQuestion 最多 4 个选项，源码路径第 4 题需要拆分处理（见 0.1.1）。

### 0.1.1 源码路径用途

`{boot_images}` 用于后续 Step 读取：
- `{boot_images}/QcomPkg/Include/api/boot/boot_error_if.h` — 错误码定义
- `{boot_images}/QcomPkg/SocPkg/{Platform}Pkg/Library/DDRTargetLib/ddr_external_api.c` — ddr_abort()
- `{boot_images}/QcomPkg/SocPkg/{Platform}Pkg/Settings/DSF/boot/common/ddr_training_params.c` — 阈值配置
- `{boot_images}/QcomPkg/SocPkg/{Platform}Pkg/Library/DSFTargetLib/boot/ddrss/src/lpddr4/` — LPDDR4 训练代码

## 0.2 日志最低要求

如果用户已提供日志，确认是否包含以下关键行（缺少则提示补充）：
- `IMAGE_VARIANT_STRING` 行（平台识别）
- `Error code` 行
- `do_ddr_training, Start` 到 `Error code` 之间的内容

**如果用户没有日志**：询问设备型号（如 MT582），根据 platform-mapping.md 推断平台。

## 下一步

完成后，读取 `workflows/step-01-parse-error.md` 继续。
