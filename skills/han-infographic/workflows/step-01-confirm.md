# Step 1: 确认参数

读自学习经验库给推荐,再让用户拍板布局 / 风格 / 画幅 / 语言。

## 1.1 查 patterns.json

读取 [data/patterns.json](../data/patterns.json),按 `analysis.md` 的内容类型匹配 `keywords`:

- **高置信度**(confidence ≥ 3)的组合 → 强推荐(直接作为默认)
- **有匹配但置信度低** → 弱推荐(标注「尝试过 N 次」)
- **无匹配** → 用 skill 默认 `dense-modules` + `journal` + `landscape` + `zh`

## 1.2 展示选项

读取 [references/layouts-and-styles.md](../references/layouts-and-styles.md),向用户呈现:
- 布局清单(带中文说明与适用场景)
- 风格清单
- 画幅:`landscape`(16:9)/ `portrait`(9:16,移动长图)/ `square`(1:1)
- 语言:`zh` / `en` / 双语

## 1.3 用 AskUserQuestion 确认

把「patterns 推荐 + analysis 判断」综合成一个默认选项,让用户:

- 选推荐默认,或
- 回复编号组合,如 `layout=dense-modules style=journal aspect=landscape lang=zh`,或
- 直接给 CLI 风格的参数覆盖

## 1.4 记录选择

把最终确认的 layout / style / aspect / lang 追加写到 `analysis.md`,供 Step 2、Step 3 使用。

**完成后,读取 [step-02-generate.md](step-02-generate.md) 继续。**
