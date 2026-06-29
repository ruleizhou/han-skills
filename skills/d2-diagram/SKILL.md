---
name: d2-diagram
description: 当用户希望使用D2声明式图表语言创建图表、从D2代码生成图像、应用草图/手绘风格，或需要D2语法及最佳实践帮助时，应使用此技能.
---

# D2 Diagram Generator V2

使用 D2 声明式语言创建专业图表，支持多种图表类型和手绘风格。

## 核心原则

- **先选形再编码**：Step 1 必须先确定图表类型 → 选择合适的 shape
- **中文优先**：所有标签和说明文字使用中文，技术术语保留英文
- **双格式输出**：每次编译同时生成 PNG 和 SVG
- **类图专用语法**：UML 类图必须用 `shape: class`，禁止用 rectangle 拼接
- **布局适中**：图表宽高应适中，优先采用多行多列布局（通过容器分组），拒绝单行超宽或单列超长

## 模式判断

| 触发信号 | 模式 | 动作 |
|----------|------|------|
| "画个流程图/架构图/ER图/类图" | 快速创建 | 直接进入 Step 1 选择对应模板 |
| "把这段文字转成图表" | 需求理解 | 先执行 Step 0 诊断需求 |
| "帮我改下这个 D2 代码" | 代码优化 | 跳到 Step 2-4 |
| "D2 怎么画 XXX" / "shape 语法" | 语法查询 | 查阅 references/，不进入工作流 |
| "生成手绘风格" / "sketch" | 样式定制 | Step 3 应用 sketch |
| "完成/搞定了/问题解决" | 反馈闭环 | 读取 workflows/feedback-loop.md |

## Workflow

本 skill 使用 7 步工作流（Step 0 ~ Step 6），按需执行。**每个步骤开始时，先 Read 对应的详细指令文件：**

| Step | 文件 | 做什么 |
|------|------|--------|
| 0 | workflows/step-00-diagnose.md | 诊断用户需求（快速创建 vs 需求理解） |
| 1 | workflows/step-01-select-objects.md | 选择图表类型和 D2 shapes（MANDATORY） |
| 2 | workflows/step-02-write-code.md | 编写 D2 代码（可选使用模板） |
| 3 | workflows/step-03-apply-styling.md | 应用样式（主题/颜色/sketch） |
| 4 | workflows/step-04-validate-compile.md | 验证语法并编译为 PNG+SVG |
| 5 | workflows/step-05-iterate-optimize.md | 根据反馈迭代优化 |
| 6 | workflows/step-06-learn.md | 自主学习与收录（任务完成后） |

**反馈闭环由用户主动触发，不在主流程中自动弹出。触发后读取 `workflows/feedback-loop.md`。**

**开始执行时，首先读取 `workflows/step-00-diagnose.md`。**

## 参考资料速查

- `references/d2-cheatsheet.md`：快速语法参考
- `references/d2-themes.md`：可用主题和样式选项
- `references/d2-shapes-guide.md`：详细形状语法指南
- `data/patterns.json`：自学习模式库（图表类型识别/样式偏好/错误避免）
- `assets/templates/*.d2`：8 种即用模板（流程图/ER图/架构图/拓扑图/序列图/状态机/甘特图/类图）
