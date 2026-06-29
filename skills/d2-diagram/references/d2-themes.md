# D2 Themes 主题参考

## CLI 主题参数

```bash
d2 --theme=<ID> input.d2 output.png
d2 --theme=<ID> --dark-theme=<ID> input.d2 output.svg
```

## 推荐主题

| ID | 名称 | 风格 | 推荐场景 |
|----|------|------|----------|
| 0 | Default | 默认浅色 | 通用 |
| 100 | Neutral | 灰白色系 | 简洁风格 |
| 200 | Dark | 暗色 | 暗色环境（仅 SVG） |
| 300 | Terminal | 蓝灰色系 | **技术文档（推荐）** |

## 主题组合建议

### 技术文档
```bash
d2 --theme=300 -l elk input.d2 output.png
```

### 演示文稿
```bash
d2 --theme=300 -l elk --sketch input.d2 output.png
```

### 暗色环境
```bash
# --dark-theme 仅适用于 SVG 格式
d2 --theme=300 --dark-theme=200 -l elk input.d2 output.svg
```

## Sketch 风格

`--sketch` 参数生成手绘风格，适合：
- 演示文稿
- 非正式讨论
- 原型设计

```bash
d2 --theme=300 -l elk --sketch input.d2 output.png
d2 --theme=300 -l elk --sketch input.d2 output.svg
```

## Inline Sketch 样式

在 D2 代码中直接定义手绘风格：

```d2
style: {
  fill-pattern: dots    # dots / lines / grain
  stroke-dash: 5        # 虚线
  border-radius: 10     # 圆角
  shadow: true          # 阴影
}
```

## 其他常用参数

| 参数 | 作用 | 示例 |
|------|------|------|
| `--pad <n>` | 内边距 | `--pad 50` |
| `--center` | 居中放置 | `--center` |
| `--scale <n>` | 缩放 | `--scale 2` |
| `--watch` | 监控变化 | `--watch` |

## 参考文档

完整主题列表：https://d2lang.com/tour/themes/
