# Step 1: 确认参数

读自学习经验库给推荐,确认 aspect / **mode** / 取向。

## 1.1 查 patterns.json

读取 [data/patterns.json](../data/patterns.json),按 `analysis.md` 的对象类型匹配 `keywords`:高置信度强推荐,无匹配用默认 `hybrid`。

## 1.2 展示选项

- **aspect**:`landscape`(16:9,默认)/ `portrait`(9:16)/ `square`(1:1)/ `4:3` / 自定义
- **mode**:
  - `hybrid`(默认):外观 + 爆炸层 + 剖面 + 细节 + 原理流程,最全面
  - `exploded`:强调零件、装配顺序、连接关系
  - `cutaway`:强调内部布局、截面、通道、电路、流体路径
  - `auto`:按对象类型自动选最合适的

## 1.3 用 AskUserQuestion 确认

- aspect(默认 `landscape`)
- mode(默认 `hybrid`)
- **取向**:精确技术写实 vs 更像海报的沟通
- 必含 / 必避的部件

## 1.4 记录选择

把 aspect / mode / 取向追加写到 `analysis.md`。

**完成后,读取 [step-02-generate.md](step-02-generate.md) 继续。**
