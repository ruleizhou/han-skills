# Step 3: 应用样式

为 D2 代码添加美观的样式（主题、颜色、sketch 风格）。

## CLI 主题（推荐作为基础）

```bash
# 技术文档（clean 风格）
d2 --theme=300 -l elk input.d2 output.png

# 演示文稿（sketch 风格）
d2 --theme=300 -l elk --sketch input.d2 output.png

# 暗色环境（仅 SVG）
d2 --theme=300 --dark-theme=200 -l elk input.d2 output.svg
```

详细主题列表见 `references/d2-themes.md`

## 全局样式

```d2
style: {
  fill: "#E3F2FD"        # 背景色
  stroke: "#1976D2"      # 边框色
  stroke-width: 2        # 边框粗细
  stroke-dash: 5         # 虚线边框
  fill-pattern: dots     # 填充图案：dots/lines/grain
  border-radius: 10      # 圆角
  shadow: true           # 阴影
  opacity: 0.8           # 透明度
  font-size: 24          # 字体大小
}
```

## 节点内联样式

```d2
database: 数据库 {
  shape: cylinder
  style.fill: "#E8F5E9"
  style.stroke: "#4CAF50"
}

frontend: 前端 {
  style.fill: "#E3F2FD"
  style.opacity: 0.9
}
```

## 连接样式

```d2
a -> b: 异常流程 {
  style.stroke: "#FF0000"
  style.stroke-dash: 5
}
```

## 样式场景指南

### 技术文档
- 主题：`--theme=300`（Terminal），不添加 `--sketch`
- 颜色：低饱和度，避免过于鲜艳

### 演示文稿
- 主题：`--theme=300` + `--sketch`
- 颜色：可使用鲜艳颜色区分模块

### 暗色环境
- 主题：`--theme=300` + `--dark-theme=200`（仅 SVG）
- 必须使用 SVG 格式

### 强调重点
```d2
critical: 关键路径 {
  style.fill: "#FFCDD2"
  style.stroke: "#F44336"
}
```

## 颜色方案（Material Design）

| 用途 | 颜色 | Hex |
|------|------|-----|
| 主要节点 | Blue | `#2196F3` / `#E3F2FD` |
| 成功/正常 | Green | `#4CAF50` / `#E8F5E9` |
| 警告/决策 | Orange | `#FF9800` / `#FFF3E0` |
| 错误/异常 | Red | `#F44336` / `#FFEBEE` |
| 信息/辅助 | Grey | `#9E9E9E` / `#F5F5F5` |

语义化颜色：数据库=绿，外部服务=蓝，核心模块=橙，错误处理=红

## 样式检查清单

- [ ] CLI 主题是否合适？
- [ ] 颜色是否有语义？
- [ ] 样式是否一致？
- [ ] 是否需要暗色主题？

---

**完成后，读取 workflows/step-04-validate-compile.md 继续**
