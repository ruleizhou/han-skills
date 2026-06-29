# Step 4: 验证并编译

验证 D2 代码语法正确性，并编译为 PNG 和 SVG 两种格式。

## 语法验证

### 使用 D2 CLI 验证

```bash
# 编译同时验证（推荐）
d2 --theme=300 -l elk input.d2 output.png
# 如有语法错误，D2 会输出错误信息
```

### 常见语法错误

| 错误信息 | 原因 | 修复 |
|----------|------|------|
| `expected '}'` | 大括号未闭合 | 检查 `{}` 配对 |
| `undefined connection target` | 连接到不存在的节点 | 检查节点名称拼写 |
| `invalid shape` | shape 名称错误 | 查阅 `references/d2-shapes-guide.md` |

## 编译为双格式

**必须同时生成 PNG 和 SVG！**

```bash
# PNG（适合插入文档、PPT）
d2 --theme=300 -l elk input.d2 output.png

# SVG（支持暗色主题、可缩放）
d2 --theme=300 --dark-theme=200 -l elk input.d2 output.svg

# 手绘风格
d2 --theme=300 -l elk --sketch input.d2 output.png
d2 --theme=300 --dark-theme=200 -l elk --sketch input.d2 output.svg
```

## 命令参数

| 参数 | 作用 | 推荐场景 |
|------|------|----------|
| `--theme=300` | Terminal 主题 | 技术文档 |
| `--dark-theme=200` | 暗色主题（仅 SVG） | 暗色环境 |
| `-l elk` | ELK 布局引擎 | 架构图/序列图 |
| `-l dagre` | Dagre 布局引擎 | 流程图/状态机 |
| `--sketch` | 手绘风格 | 演示文稿 |
| `--pad <n>` | 添加内边距 | 节点密集时 |
| `--center` | 居中放置 | 节点较少时 |

## 编译结果验证

- [ ] PNG 文件是否生成？
- [ ] SVG 文件是否生成？
- [ ] 布局是否多行多列？（拒绝单行/单列一字排开）
- [ ] 宽高比是否适中（约 4:3 ~ 16:9）？
- [ ] 节点不重叠、连接不交叉？
- [ ] 中文标签是否正常？（无乱码）
- [ ] 样式是否正确？

## 布局不理想时

1. **更换布局引擎**：`-l dagre` ↔ `-l elk`
2. **调整方向**：`direction: down` ↔ `direction: right`
3. **容器分组**：使用 `{}` 将节点拆分成多个分组，形成多行多列
4. **添加内边距**：`--pad 50`

## 中文显示异常

检查：D2 版本 ≥ 0.5.0、文件编码 UTF-8、终端支持 UTF-8

## 大型图表（节点 > 50）

```bash
d2 --theme=300 -l elk --pad 100 large.d2 large.png
```

---

**完成后，读取 workflows/step-05-iterate-optimize.md 继续**
