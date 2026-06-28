# Step 1: 确认参数

读自学习经验库给推荐,确认 layout / style / aspect / lang / **density**。

## 1.1 查 patterns.json

读取 [data/patterns.json](../data/patterns.json),按 `analysis.md` 的内容类型匹配 `keywords`:

- 高置信度(≥3)→ 强推荐;有匹配但低 → 弱推荐;无匹配 → 用默认。

## 1.2 展示选项

- **layout**:`auto`(默认)/ `flow` / `comparison` / `grouped-cards` / `cycle` / `timeline` / `matrix` / `pyramid` / `dense-modules`
- **style**:`hand-drawn-edu`(默认暖手账)/ `chubby-sketch`(圆角海报)/ 或复用 han-infographic 风格词(`lab-notes`/`kawaii`/`chalkboard` 等,仅取视觉处理)
- **aspect**:`landscape`(16:9)/ `portrait`(9:16)/ `square`(1:1)
- **density**:`normal`(3-6 模块留白足)/ `high`(6-8 紧凑高信息)
- **lang**:`zh` / `en` / 其他

## 1.3 用 AskUserQuestion 确认

给推荐默认,让用户选。注意这几条联动规则:

- 选 `chubby-sketch` → 默认 `portrait` + `high`
- `--layout dense-modules` → 默认 `high` 密度(除非显式 `--density normal`)
- 用户说「默认」→ `auto` + `hand-drawn-edu` + `landscape` + `zh` + `normal`

## 1.4 记录选择

把最终 layout/style/aspect/lang/density 追加写到 `analysis.md`。

**完成后,读取 [step-02-generate.md](step-02-generate.md) 继续。**
