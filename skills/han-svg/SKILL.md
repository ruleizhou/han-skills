---
name: han-svg
description: >
  从结构化 JSON 规范生成干净、可编辑的 SVG 图表。确定性 Python 渲染(非生图模型),
  支持 matrix(日程/对比表/周计划/分组卡片)、flowchart(流程步骤与决策)、
  timeline(时间事件)、architecture(系统/服务/数据流/分层图)。输出独立 .svg 文件,
  可选 PNG 导出。当用户说「SVG 图表、架构图、流程图、时间线、矩阵图、对比表、可视化日程、
  画个图表、editable SVG」时使用本 skill——它是生图模型之外确定性的图表方案。
  想要 AI 生成的信息图用 han-infographic;想要手绘卡用 han-hand-write-pic。
---

# Han SVG

从紧凑的 JSON 规范生成独立、可编辑的 SVG 图表。用确定性 Python 渲染器:准备结构化 spec,脚本负责渲染、校验、(可选)导出。纯标准库,无需第三方包。

## 默认值

| 设置 | 默认 |
|------|------|
| 工作目录 | `svg/{topic-slug}/` |
| 下载目录 | `~/Downloads/han-skill-svg/` |
| 默认主题 | `han-light` |
| 默认比例 | `16:9` |

## 支持类型

| 类型 | 用于 |
|------|------|
| `matrix` | 日程表、对比表、周计划、分组卡片 |
| `flowchart` | 流程步骤与决策 |
| `timeline` | 时间事件 |
| `architecture` | 系统、服务、数据流、分层图 |

按需读对应参考:
- [references/matrix.md](references/matrix.md) / [flowchart.md](references/flowchart.md) / [timeline.md](references/timeline.md) / [architecture.md](references/architecture.md)
- [references/spec-schema.md](references/spec-schema.md)(共享 schema)

## 工作流

1. 识别图表类型,派生短英文 `topic-slug`。
2. 创建 `svg/{topic-slug}/`。
3. 把用户输入存为 `source.md`。
4. 用 [references/spec-schema.md](references/spec-schema.md) 和类型专属参考创建 `spec.json`。
5. 渲染:

```bash
python3 {baseDir}/scripts/main.py render \
  --spec svg/{topic-slug}/spec.json \
  --svg svg/{topic-slug}/output.svg \
  --theme han-light \
  --download \
  --json
```

6. 需要 PNG 则加 `--png`。PNG 导出是 best-effort,依赖 `rsvg-convert` / `cairosvg` / 其他已配置的转换器(没有则只输出 SVG)。

## Spec 规则

- 标签保持短;节点标题与行标签用 2-6 词。
- `matrix` 用 `sections`;`flowchart`/`architecture` 用 `nodes`/`edges`;`timeline` 用 `events`。
- 支持中文,但 CJK 标签要简洁以防溢出。
- 图标仅作语义提示,渲染器把常见图标名映射为内联小符号。
- 教育/家庭规划类视觉优先 `han-light`;技术架构用 `dark-tech`。

## 输出规则

- 输出独立 `.svg`,带 `viewBox`,无固定 `width`/`height`。
- 本地工作文件存 `svg/{topic-slug}/`。
- 用 `--download` 时把最终交付物复制到 `~/Downloads/han-skill-svg/`。
- 不依赖外部图片。
- **architecture 类型渲染后**, 按 [references/architecture.md](references/architecture.md) 的折线优化规则手动优化 SVG 边路由(直线→折线, 消重叠, 汇聚入口)。

## CLI

```bash
# 生成起始 spec
python3 {baseDir}/scripts/main.py template --type matrix --output svg/example/spec.json

# 渲染 SVG
python3 {baseDir}/scripts/main.py render --spec svg/example/spec.json --json

# 校验 spec
python3 {baseDir}/scripts/main.py validate --spec svg/example/spec.json
```

单元测试:`python3 scripts/tests/test_renderer.py`(2 个测试,验证渲染正确性)。
