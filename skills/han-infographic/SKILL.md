---
name: han-infographic
description: >
  把任意内容(链接 / 文档 / 对话 / 主题)做成高密度信息图。采用两阶段法——先做防幻觉的结构化
  简报(analysis + structured-content,锁定精确数据点与文本标签),再套模板生成提示词并出图;
  自带布局×风格模板库,支持中文,统一输出到 ~/Downloads/han-skill-imagen/。具备自学习:每次
  生成后沉淀「内容类型→布局/风格组合」经验,越用越懂哪种参数出图最好。
  当用户说「生成信息图、把内容转成图、把这篇文章做成大图、高密度信息大图、可视化摘要、
  infographic、画张图总结一下、给这段配个信息图、知识卡片图」时使用本 skill。
  想要纯文字配图/单张插图,用 han-imagen;想要可编辑图表,用 han-d2-diagram。
---

# Han Infographic

中立通用的信息图生成 skill。两阶段法防幻觉出图 + 自学习越用越准。

## 核心原则

1. **先防幻觉分析,再出图** —— 先产出 `analysis.md` + `structured-content.md`(每个视觉模块含精确数据点和文本标签),锁定内容后再生成提示词。绝不直接拿原文喂模型。
2. **中文必须清晰可读** —— 所有中文用标准黑体类字体(思源黑体/PingFang/微软雅黑),禁装饰/手写/艺术/超细字体。详见 [text-legibility.md](references/text-legibility.md)。
3. **出图走 han-imagen** —— 有 han 作用域 key 时调 `han-imagen` Python 后端;无 key 时 fallback 运行时内置生图工具。产物统一落 `~/Downloads/han-skill-imagen/{slug}-infographic.png`。
4. **角色参考图可选** —— `assets/` 下放图则作为风格锚点,不放则不绑角色。skill 本身中立,不绑定任何专属角色。

## 模式判断

| 触发信号 | 模式 | 动作 |
|----------|------|------|
| 生成信息图 / 把内容转图 / 高密度信息大图 / 可视化摘要 / 配个信息图 | 正常生成 | 从 Step 0 开始 |
| 这版不错 / 就用这版 / 这张图可以 / 搞定了 | 反馈闭环 | 读 [workflows/feedback-loop.md](workflows/feedback-loop.md) |

## 预检清单

- 有源内容吗?(链接 / 文档 / 对话)→ 没有就先问用户要。
- 有可用的生图后端吗?(han 作用域 key 或运行时工具)→ 都没有就在 Step 2 说明并只输出提示词。

## Workflow

本 skill 用 5 步主流程(Step 0 ~ Step 4),按序执行。**每步开始先 Read 对应指令文件:**

| Step | 文件 | 做什么 |
|------|------|--------|
| 0 | [workflows/step-00-analyze.md](workflows/step-00-analyze.md) | 防幻觉分析:建工作目录,写 `analysis.md` + `structured-content.md` |
| 1 | [workflows/step-01-confirm.md](workflows/step-01-confirm.md) | 读 `data/patterns.json` 给推荐,确认布局/风格/画幅/语言 |
| 2 | [workflows/step-02-generate.md](workflows/step-02-generate.md) | 套模板生成 `prompts/infographic.md`,调 han-imagen 出图 |
| 3 | [workflows/step-03-report.md](workflows/step-03-report.md) | 输出最终报告(主题、参数、本地路径、产物清单) |
| 4 | [workflows/step-04-learn.md](workflows/step-04-learn.md) | 收录新内容类型 / 新布局风格组合到 patterns.json |

反馈闭环由用户主动触发,不在主流程自动弹出。

默认参数:`dense-modules`(密集模块)+ `journal`(手账风)+ `landscape`(16:9)+ `zh`(中文)。

## 参考资料速查

- 模板库:[references/layouts-and-styles.md](references/layouts-and-styles.md)
- 提示词模板:[references/prompt-template.md](references/prompt-template.md)
- 中文清晰度约束:[references/text-legibility.md](references/text-legibility.md)
- 自学习经验库:[data/patterns.json](data/patterns.json) · 历史案例 [data/cases/](data/cases/)

**开始执行时,首先读取 [workflows/step-00-analyze.md](workflows/step-00-analyze.md)。**
