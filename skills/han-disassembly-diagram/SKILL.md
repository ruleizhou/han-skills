---
name: han-disassembly-diagram
description: >
  生成高质量中文教学拆解图:物体拆解、爆炸图、剖面图、内部结构图、产品解剖卡、部件标注、
  材料说明、工作原理流程图。支持 hybrid(默认混合)/ exploded(爆炸)/ cutaway(剖面)/ auto 四种模式,
  统一输出到 ~/Downloads/han-skill-imagen/。具备自学习:沉淀「对象类型→模式/画幅」经验。
  当用户说「拆解图、爆炸图、剖面图、半剖视图、产品结构说明图、科普海报、知识卡片、
  某东西的内部结构、原理结构图」时使用本 skill。
  想要手绘知识卡用 han-hand-write-pic;想要信息图用 han-infographic。
---

# Han Disassembly Diagram

中文教学拆解图 / 产品解剖卡。中立技术科普,不绑角色。

## 核心原则

1. **清晰中文教学图** —— 像精致的科技解说海报/产品解剖卡,标准简体黑体类字体,层级清晰。
2. **先防幻觉分析再出图** —— 先产出 analysis + structured-content;**不确定的内部结构必须标注为「示意图」而非精确工程拆解**。
3. **模式可控** —— `hybrid`(默认,混合外观/爆炸/剖面/细节/原理)/ `exploded`(爆炸图)/ `cutaway`(剖面)/ `auto`(按对象自动选)。
4. **材料标注** —— 区分金属/塑料/玻璃/橡胶/陶瓷/织物/复合/流体/电路板/电池等。
5. **走 han-imagen** —— 有 key 调 han-imagen,无 key fallback 运行时生图工具,产物落 `~/Downloads/han-skill-imagen/{slug}-disassembly-diagram.png`。

## 模式判断

| 触发信号 | 模式 | 动作 |
|----------|------|------|
| 拆解图 / 爆炸图 / 剖面图 / 产品结构说明图 / 科普海报 | 正常生成 | 从 Step 0 |
| 这版不错 / 就用这版 / 搞定了 | 反馈闭环 | 读 [workflows/feedback-loop.md](workflows/feedback-loop.md) |

## 预检清单

- 目标对象明确吗?从请求识别(替换 `{……}` 占位符)。
- 高价值对象(品牌产品/医疗器械/安全设备)?→ 结构须基于用户提供的权威资料,否则标注示意图。

## Workflow

5 步主流程(Step 0~4),每步先 Read 对应指令:

| Step | 文件 | 做什么 |
|------|------|--------|
| 0 | [step-00-analyze.md](workflows/step-00-analyze.md) | 分析对象结构:analysis.md(外观/内部/材料/原理)+ structured-content.md(标签+原理流程) |
| 1 | [step-01-confirm.md](workflows/step-01-confirm.md) | 读 patterns 推荐 + 确认 aspect/**mode** + 精确写实 vs 海报沟通 |
| 2 | [step-02-generate.md](workflows/step-02-generate.md) | 套拆解图模板生成 prompts/disassembly-diagram.md + 调 han-imagen 出图 |
| 3 | [step-03-report.md](workflows/step-03-report.md) | 输出报告(对象、mode、参数、本地路径、产物清单) |
| 4 | [step-04-learn.md](workflows/step-04-learn.md) | 收录新 对象类型/模式 组合到 patterns.json |

反馈闭环由用户主动触发,不在主流程弹出。

默认:`hybrid` mode + `landscape` + `zh`。

## 参考资料速查

- 拆解图提示词模板:[references/prompt-template.md](references/prompt-template.md)
- 中文清晰度:[references/text-legibility.md](references/text-legibility.md)
- 自学习:[data/patterns.json](data/patterns.json) · [data/cases/](data/cases/)

**开始执行时,首先读取 [workflows/step-00-analyze.md](workflows/step-00-analyze.md)。**
