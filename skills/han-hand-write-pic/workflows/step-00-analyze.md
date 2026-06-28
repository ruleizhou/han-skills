# Step 0: 防幻觉分析

先建工作目录、锁定内容、决定密度。产物是提示词的「事实底座」。

## 0.1 建工作目录

- 从标题/主题派生 slug(kebab-case)。
- 在用户当前工作目录建:
  ```
  hand-write-pic/{slug}/
  ├── source-{slug}.md
  ├── analysis.md
  ├── structured-content.md
  ├── refs/        # 风格参考图(Step 2 用)
  └── prompts/     # 提示词
  ```

## 0.2 读取源内容

链接 → webReader 抓取;文档 → Read;对话 → 直接整理;只有主题 → 起草大纲并标「⚠ AI 草拟,需确认」。

## 0.3 写 analysis.md

- 主题、受众、**内容类型**(工具总结/概念科普/流程教程/对比/其他 → 决定 density 与风格推荐)
- 推荐参数(layout/style/aspect/density 初步,Step 1 确认)
- 1-3 个学习目标
- 关键事实/数字/实体/引用(**精确保留**,标出处)
- 推荐视觉隐喻(用什么图标/涂鸦表达)

## 0.4 写 structured-content.md(按密度)

**normal 密度**(默认):
- 标题 + 一行副标题
- 3-6 个视觉板块,每板块:核心点 + 2-5 个短标签(2-5 词)+ 建议图标/涂鸦
- 板块间用箭头 + 短连接标签
- 底部一句加粗居中的 takeaway

**high 密度**(`--density high` 或 `--layout dense-modules`):
- 标题 + 副标题 + 一行概览
- 6-8 个紧凑模块,每模块:核心概念 + 3-6 简洁标签 + 精确数字 + 视觉处理
- 可用 metric chips / quote strips / process boxes / 对比格 / 警告-takeaway 块
- takeaway 可选,不挤占内容空间

**防幻觉铁律**:源内容没有的数据点标「⚠ 待确认」,绝不进提示词。标签保持短(2-5 词),不要段落。

**完成后,读取 [step-01-confirm.md](step-01-confirm.md) 继续。**
