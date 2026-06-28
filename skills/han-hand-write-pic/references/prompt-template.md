# Prompt Template

用本模板生成 `prompts/hand-write-pic.md`。

```markdown
Create a one-page educational visual summary.

Image settings:
- Layout: {layout}
- Style: {style}
- Aspect ratio: {aspect}
- Language: {language}
- Density: {density}

Style:
Use the selected visual style: {style}.
Style guidance: {style guidance}

If style is `hand-drawn-edu` or unspecified, use the default warm cream paper background (#F5F0E8), clean sketchnote style with slight hand-drawn wobble, pastel educational cards, and a high-quality slide summary feel.
If style is `chubby-sketch`, create a bright white rounded-card hand-drawn knowledge poster inspired by `references/chubby-sketch-style.jpeg`: oversized rounded black marker title, blue wavy underlines, compact stacked modules, dotted dividers, pastel numbered circles, pill labels, black-outline icons, sparkles/checkmarks/flowers, and optional unbranded cute cat helper doodles.
For other styles inherited from `han-infographic`, apply only the visual treatment while preserving the one-page educational-summary structure.
No bundled character mascot by default. This skill stays unbranded — no recurring narrator, mascot, or character unless the user explicitly provides a reference image in assets/.

Density:
Use the selected density: {density}.
Density guidance: {density guidance}

For `normal` density, create a clear sketchnote summary with 3-6 visual sections, short labels, visual metaphors, and generous whitespace.
For `high` density, create a compact high-information hand-drawn infographic: 6-8 modules in a tight modular grid, small but readable text, metric chips, quote strips, process boxes, comparison cells, warning/takeaway blocks, and minimal decorative whitespace.

Color:
For `hand-drawn-edu`, use pastel rounded cards for sections: light blue #A8D8EA, mint #B5E5CF, lavender #D5C6E0, peach #F4C7AB; coral red #E8655A for highlights; black text/outlines; warm gray #6B6B6B annotations.
For `chubby-sketch`, use a bright white or very light warm background (#FCFBF7), black marker outlines, blue #4A90E2 wavy underlines and borders, pastel chips in soft yellow #FFE89A, pale pink #F7C6D9, light blue #CFE8FF, mint #D7F2DD, and small warm accent marks in red/yellow.
For other styles, adapt the palette to the selected style while keeping high contrast and legible text.

Design:
Visual-first. Use icons, diagrams, symbolic objects, or style-appropriate visual metaphors instead of long text.
Clear structure at a glance (flow, comparison, grouped cards, etc.).
Separate sections with rounded boxes, bubbles, or dashed frames.
Connect sections with arrows, paths, lines, or other connectors + short labels.
If density is `high`, prioritize information architecture over decoration: compact modules, grouped labels, dense callouts, exact numbers, short copied quotes.

Typography:
Centered bold title on top, rendered in the selected style.
Inside sections: bold keywords + compact labels (2-5 words), annotation styling adapted to the style.
If density is `high`, labels may be longer for factual clarity but must remain concise and legible.

Details:
For `hand-drawn-edu`, use slightly imperfect color fill and small doodles (stars, arrows, underlines).
For `chubby-sketch`, use dotted horizontal separators, dashed vertical splits, rounded pill boxes, numbered circles, micro-bullets, playful speech bubbles, sparkle/flower/star doodles, and occasional cute cat helper doodles (unbranded).
If density is `normal`, keep plenty of whitespace and a clean layout.
If density is `high`, reduce oversized doodles, empty margins, and footer space.

Footer:
Add one bold centered takeaway sentence at the bottom.
If density is `high`, keep the footer optional and one line only; omit it when it would crowd content modules.

Content:
{structured content}
```

## Structuring Rules

- normal 密度:把源压缩成 3-6 个视觉板块;high 密度:6-8 个紧凑模块。
- 标签尽量 2-5 词;high 密度允许每模块 3-6 简洁标签。
- 重要数字原样保留。
- 图标/图示隐喻优先于解释文字。
- normal 密度 footer 一句加粗居中;high 密度可选。
- 避免照片级写实和 logo 式标记;黏土等风格允许程式化 3D。
- 中文必须清晰可读(标准黑体类字体),约束见 [text-legibility.md](text-legibility.md)。
- 默认不绑任何角色;`chubby-sketch` 允许无品牌可爱猫助教涂鸦,其他风格不主动加 mascot。
