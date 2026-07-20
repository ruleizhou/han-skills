---
name: ufs-provision-analyzer
description: >
  分析高通 QFIL / fh_loader 的 UFS Provisioning 失败（典型如 UFS Error -22 EINVAL），
  定位 commit 阶段根因，按跨厂家风险排序调整 provision_ufs.xml 参数，生成定制 XML，
  并通过 getstorageinfo 查询 UFS 能力 descriptor。覆盖 trace 对比、参数详解、故障排查、
  能力查询、模板生成与厂家×容量经验自学习。
  Trigger when: 用户提到 QFIL provision 失败、UFS Error -22、provision_ufs.xml、
  UFS provision 配置、跨厂家 UFS provision、QFIL UFS 配置参数、fh_loader provision、
  UFS provisioning commit NAK、bProvisioningType、WriteBooster buffer、UFS Config Descriptor。
---

# UFS Provisioning 跨厂家兼容性分析与调优

针对高通 QFIL / fh_loader 的 UFS Provisioning 场景，定位 commit 阶段失败根因（典型 `UFS Error -22 (3)` EINVAL），按跨厂家风险排序调整 `provision_ufs.xml` 参数，生成定制 XML，并沉淀"厂家×容量→参数组合"经验。

## 核心原则

1. **先定位 commit 阶段** — provision 失败时，先对比 trace 确认错误是否发生在 `commit="1"` 包；前面 LU 标签的 ACK 只代表参数被接收，不代表能力校验通过。
2. **按风险排序调参** — 跨厂家不兼容风险从高到低：WB 缓冲尺寸 → WB 类型+Preserve → Thin Provisioning 用于 Boot/OTP → 逻辑块大小 → 固定大尺寸 LU。一次只改一项复跑验证。
3. **先查能力再调参** — 调参前优先用 `getstorageinfo` 读 Device Descriptor，确认 UFS 实际支持的 WB 类型/尺寸/Provisioning/逻辑块，避免盲调。
4. **最保守优先** — 不确认设备能力时，先用最保守配置（WB 禁用、ProvisioningType=0、LUN 4 禁用）跑通，再逐步放开。
5. **沉淀经验** — 每次成功 provision 后，把"厂家+容量→可用参数组合"写入 `data/patterns.json`，越用越准。

## 模式判断

**先判断用户意图属于哪种模式**：

| 触发信号 | 模式 | 动作 |
|----------|------|------|
| 提供 `port_trace*.txt` + 报错（UFS Error -22 / NAK / provision 失败） | 分析模式 | Step 0 → Step 1 → Step 2 → Step 3 |
| 只问参数含义 / bProvisioningType / WriteBooster / XML 字段 | 问答模式 | 直接读 `references/` 下对应文件回答 |
| 要求生成 provision XML / 定制 XML / 模板 | 生成模式 | Step 0 → Step 3（跳过 trace 分析） |
| 用户说"搞定了"/"修好了"/"provision 成功了"/"问题解决了" | 反馈闭环模式 | 读 `workflows/feedback-loop.md` 沉淀经验 |

## 预检清单

在进入工作流之前快速判断：
- 是否高通平台 + QFIL/fh_loader 工具链？否 → 说明本 skill 仅覆盖高通 QFIL UFS provision
- 是否 UFS 存储？eMMC → 说明本 skill 不覆盖 eMMC provision
- 是否 commit 阶段失败（UFS Error -22 / Configure Failed slot 0）？是 → 进入分析模式
- 是否已有 `port_trace*.txt`？否 → 引导用户用 fh_loader 跑一次并保存 port_trace.txt

## Workflow

本 skill 使用 4 步主工作流（Step 0 ~ Step 3），按顺序执行。**每个步骤开始时，先 Read 对应的详细指令文件：**

| Step | 文件 | 做什么 |
|------|------|--------|
| 0 | `workflows/step-00-collect-context.md` | 收集 trace/XML/设备容量/厂家信息 |
| 1 | `workflows/step-01-trace-analysis.md` | trace 对比 + 定位 commit 阶段失败 |
| 2 | `workflows/step-02-capability-query.md` | UFS 能力查询（getstorageinfo / Descriptor） |
| 3 | `workflows/step-03-param-tuning.md` | 按风险排序调参 + 生成定制 XML |

**反馈闭环由用户主动触发，不在主流程中自动弹出。触发后读取 `workflows/feedback-loop.md`。**

**开始执行时，首先读取 `workflows/step-00-collect-context.md`。**

## 参考资料速查

- XML 全参数详解：`references/xml-params.md`
- bProvisioningType 4 种类型：`references/bprovisioning-type.md`
- WriteBooster 三参数 + 跨厂家风险：`references/writebooster-params.md`
- 错误码速查：`references/error-codes.md`
- UFS 能力 Descriptor 字段：`references/capability-descriptors.md`
- 最保守通用 XML 模板：`templates/provision_ufs_template.xml`
- 自学习经验库：`data/patterns.json`
