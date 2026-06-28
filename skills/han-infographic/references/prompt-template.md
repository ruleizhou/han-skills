# Prompt Template

用本模板生成 `prompts/infographic.md`。

```markdown
---
references:
  - ref_id: 01
    filename: 01-ref.png
    usage: style
---

Create a polished infographic in {language}.

## Image Specs

- Type: infographic
- Layout: {layout}
- Style: {style}
- Aspect ratio: {aspect}
- Language: {language}

## Visual Direction

{style guidance —— 从 layouts-and-styles.md 对应 style 的 Guidance 复制}

## Layout Structure

{layout guidance —— 从 layouts-and-styles.md 对应 layout 的 Guidance 复制}

## Character Reference (可选 —— 仅当 assets/ 下有参考图时)

若 `refs/01-ref.png` 存在(来自 `assets/`,由用户自行放入),将其作为风格/角色锚点:

- 描述参考图本身的视觉特征(从图直接读出:色调、线条、角色造型等)
- 让它作为解说员 / 贴纸 / 指针 / 标注主持人出现
- 辅助信息层级,**不得主导版面**
- 表情与内容含义匹配:关键见解用惊讶,风险用汗滴,机会用闪亮,行动项用速度线

若没有参考图,**跳过本段**,信息图不绑定任何角色,保持中立。

## Content

{structured-content.md 的各模块,逐条带入}

## Required Text Labels

{所有要显示在图上的文字标签,原样保留,逐条列出}

## Rendering Requirements

- {language} 文本必须清晰、分组正确(详见 text-legibility.md)
- 所有重要数字原样保留,不得改动
- 清晰的视觉层级
- 密集但有序
- 像一张完成度高的信息图,而非海报或漫画页
```

## Prompt Checklist

生成提示词后核对:

- 若 `assets/` 有参考图 → frontmatter 引用 `refs/01-ref.png`,正文含「Character Reference」段;没有则两处都不出现角色内容。
- 提示词包含选定的 layout / style / aspect / language。
- 提示词包含 `structured-content.md` 的全部模块与 Required Text Labels。
- 提示词明确要求:目标语言文字清晰可读、关键数字原样保留。
- 中文清晰度约束(标准黑体类字体、禁装饰字体)写进 Rendering Requirements。
