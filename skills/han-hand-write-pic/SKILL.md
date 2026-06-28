---
name: han-hand-write-pic
description: >
  把内容做成一页暖色手账/手绘风知识卡(sketchnote)。视觉优先——用图标、涂鸦、简图、分组卡片、波浪箭头、
  短标签,而非密集段落。支持 normal/high 双密度(high=紧凑高信息手绘信息图)。自带手绘风格库
  (hand-drawn-edu 默认 / chubby-sketch)+ 复用 han-infographic 风格词汇,统一输出到
  ~/Downloads/han-skill-imagen/。具备自学习:沉淀「内容类型→布局/风格/密度」经验,越用越准。
  当用户说「手绘图、手写风图片、手绘知识图、sketchnote、手绘教育信息图、高密度手绘大图、
  把内容画成一页知识卡、暖色手账风总结」时使用本 skill。
  想要品牌角色信息图用 han-infographic;想要可编辑图表用 han-svg。
---

# Han Hand Write Pic

一页暖色手绘/手账风知识卡。中立通用,默认不绑任何角色。

## 核心原则

1. **视觉优先** —— 用图标、涂鸦、简图、波浪箭头、短标签(2-5 词)转化内容,不要密集段落。
2. **先防幻觉分析再出图** —— 先产出 analysis + structured-content,精确数据/引用必须来自源内容,编造的标「⚠ 待确认」。
3. **密度可控** —— normal(3-6 模块,留白足)/ high(6-8 紧凑模块,高信息);`--layout dense-modules` 默认等同 high 密度。
4. **中文清晰** —— 标准黑体类字体,禁装饰字体,见 [text-legibility.md](references/text-legibility.md)。
5. **走 han-imagen** —— 有 key 调 han-imagen,无 key fallback 运行时生图工具,产物落 `~/Downloads/han-skill-imagen/{slug}-hand-write-pic.png`。

## 模式判断

| 触发信号 | 模式 | 动作 |
|----------|------|------|
| 手绘图 / 手写风 / sketchnote / 手绘知识卡 / 暖色手账总结 | 正常生成 | 从 Step 0 |
| 这版不错 / 就用这版 / 搞定了 | 反馈闭环 | 读 [workflows/feedback-loop.md](workflows/feedback-loop.md) |

## 预检清单

- 有源内容吗?(链接/文档/对话)没有先问。
- 有生图后端吗?(han 作用域 key 或运行时工具)都没有就只输出提示词。

## Workflow

5 步主流程(Step 0~4),每步先 Read 对应指令:

| Step | 文件 | 做什么 |
|------|------|--------|
| 0 | [step-00-analyze.md](workflows/step-00-analyze.md) | 防幻觉分析:analysis.md + structured-content(normal/high 两套结构) |
| 1 | [step-01-confirm.md](workflows/step-01-confirm.md) | 读 patterns 推荐 + 确认 layout/style/aspect/lang/**density** |
| 2 | [step-02-generate.md](workflows/step-02-generate.md) | 套手绘模板生成 prompts/hand-write-pic.md + 调 han-imagen 出图 |
| 3 | [step-03-report.md](workflows/step-03-report.md) | 输出报告(主题、参数、本地路径、产物清单) |
| 4 | [step-04-learn.md](workflows/step-04-learn.md) | 收录新 内容类型/风格/密度 组合到 patterns.json |

反馈闭环由用户主动触发,不在主流程弹出。

默认:`auto` layout + `hand-drawn-edu` style + `landscape` + `zh` + `normal` density。选 `chubby-sketch` 风格时默认走 `portrait` + `high`。

## 参考资料速查

- 手绘提示词模板:[references/prompt-template.md](references/prompt-template.md)
- chubby-sketch 风格参考:[references/chubby-sketch-style.jpeg](references/chubby-sketch-style.jpeg)
- 中文清晰度:[references/text-legibility.md](references/text-legibility.md)
- 自学习:[data/patterns.json](data/patterns.json) · [data/cases/](data/cases/)

**开始执行时,首先读取 [workflows/step-00-analyze.md](workflows/step-00-analyze.md)。**
