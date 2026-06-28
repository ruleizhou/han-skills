# 中文清晰度约束(防乱码)

生图模型在中文上最容易翻车的就是**乱码、变形字、不可读标签**。这套约束是 han-infographic 解决中文乱码的核心,生成提示词时必须把以下要点写进 Rendering Requirements。

## 字体要求

所有可见中文文本必须使用**清晰、整洁的标准简体中文字体**,优先级:

- 思源黑体(Source Han Sans)
- PingFang SC
- 微软雅黑
- 黑体 / 苹方

## 排版要求

- **标题**:醒目、粗体、易读,字号最大。
- **标签 / 数据**:中大号、高对比度,海报/卡片尺寸下仍可读。
- **说明文字**:简洁,紧贴相关部件,不悬空。
- 数字与术语**原样保留**,不得四舍五入或改写。

## 禁止项(negative prompt)

提示词里显式声明**避免**:

- 装饰字体、艺术字体
- 手写字体(除非风格本身就是手绘系,且仍需保证可读)
- 超细字体、描边过细
- 变形字形、拉伸/扭曲的文字
- 乱码、无意义符号串
- 微小标签、密集到重叠的文本
- 难以辨认的注释

## 建议写法

在提示词的 Rendering Requirements 段落里,可这样写:

```
All Chinese text must use clean standard sans-serif fonts (Source Han Sans /
PingFang SC). Titles are bold and prominent; labels are large, high-contrast
and poster-readable; captions are concise and sit next to their related parts.
Preserve all numbers exactly. Avoid decorative fonts, artistic fonts, ultra-thin
strokes, deformed glyphs, garbled characters, tiny labels, overlapping text,
and illegible annotations.
```
