# Step 3: 图表与信息图生成

根据 Step 2 的图表清单和信息图清单，依次生成 D2 图表和信息图。

## 3.0 准备工作

### 检测 D2 CLI

```bash
which d2 && d2 --version
```

如果 `d2` 未安装，告知用户：
> D2 CLI 未安装，将输出 D2 源代码作为代码块嵌入文档。安装 D2 后可手动编译：`d2 --theme=300 -l elk input.d2 output.png`

### 创建图片目录

```bash
mkdir -p _diagrams
```

所有 .d2 源文件、编译产物和信息图都放在当前工作目录的 `_diagrams/` 下。

## 3.1 图表类型判定

对 Step 2 D2 图表清单中的每一项，读取 `references/diagram-placement-guide.md` 确认图表类型选择是否正确。

## 3.2 编写 D2 代码

对每个图表，**按以下顺序操作**：

### a. 读取模板

读取 han-d2-diagram skill 中对应的模板文件作为骨架：

```
Read: ${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/<type>.d2
```

模板路径映射：
- system-architecture → `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/system-architecture.d2`
- flowchart → `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/flowchart.d2`
- sequence-diagram → `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/sequence-diagram.d2`
- state-machine → `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/state-machine.d2`
- er-diagram → `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/er-diagram.d2`
- class-diagram → `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/class-diagram.d2`
- gantt-chart → `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/gantt-chart.d2`
- network-topology → `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/assets/templates/network-topology.d2`

### b. 读取语法参考

根据需要读取：
- `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/references/d2-shapes-guide.md` — 确认 shape 语法
- `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/references/d2-cheatsheet.md` — 连接/容器/样式语法

### c. 读取主题参考

读取 `${CLAUDE_PLUGIN_ROOT}/skills/han-d2-diagram/references/d2-themes.md`，技术文档统一使用：
- 主题：`--theme=300`（Terminal 蓝灰色系）
- 不加 `--sketch`（技术文档需要正式风格）
- 语义颜色参考：
  - 核心模块 → 橙色 `#FF9800`
  - 数据存储 → 绿色 `#4CAF50`
  - 外部服务 → 蓝色 `#2196F3`
  - 错误/异常 → 红色 `#F44336`

### d. 写 D2 代码

基于模板骨架，填入实际内容：
- 所有节点标签使用中文
- 技术术语保留英文
- 连接线标注关键操作/数据
- 使用 `_diagrams/<short-name>.d2` 命名

## 3.3 编译

对每个 .d2 文件，执行双格式输出：

```bash
d2 --theme=300 -l elk _diagrams/<name>.d2 _diagrams/<name>.png
d2 --theme=300 --dark-theme=200 -l elk _diagrams/<name>.d2 _diagrams/<name>.svg
```

### 编译失败处理

常见错误及修复：
- 语法错误 → 对照 d2-cheatsheet.md 检查，修正后重试
- 中文显示异常 → 确认系统字体支持中文，必要时用英文标签兜底
- 布局重叠 → 尝试 `-l dagre` 替代 `-l elk`，或调整节点位置

### 编译成功后

验证图片文件存在且非空：
```bash
ls -lh _diagrams/<name>.png _diagrams/<name>.svg
```

## 3.4 图表补充模式（快捷入口）

当用户说"加个图"或"画个架构图"时，跳过 Step 0-2，直接执行：

1. 从对话上下文提取需要配图的概念/模块/流程
2. 如果用户指定了图表类型，直接使用；否则根据内容推断
3. 如果当前工作目录已有 `_diagrams/` 和文档 .md 文件，将新图追加到现有文档
4. 执行 3.1 → 3.2 → 3.3 流程

## 3.5 信息图生成

D2 图表全部完成后，对 Step 2 信息图清单中的每一项生成信息图。

### 3.5.1 准备调用参数

对每个信息图候选，组装请求字符串：

```
为一份技术文档的[位置描述，如"文档开篇"/"第X章开头"]生成概念信息图。

文档主题: [文档标题]
内容类型: [根据 doc_type 映射]
关键概念:
  - [概念1]: [一句话描述]
  - [概念2]: [一句话描述]
  ...

推荐布局: [从 Step 2 信息图清单或 patterns.json 匹配, 默认 dense-modules]
推荐风格: [lab-notes (技术内容) / journal (概览汇报), 默认 journal]
画幅: landscape

要求：中文清晰可读，信息密度高，适合作为文档视觉亮点。
```

### 3.5.2 调用 han-infographic

```
Skill(skill="han-infographic", args="<上述请求字符串>")
```

han-infographic 会执行其内部工作流（分析→确认参数→生成→输出→学习），期间可能通过 AskUserQuestion 让用户确认布局/风格选择。

### 3.5.3 收集产物

han-infographic 完成后，产物位于:
```
~/Downloads/han-skill-imagen/{slug}-infographic.png
```

将此文件复制到 `_diagrams/` 目录:
```bash
cp ~/Downloads/han-skill-imagen/{slug}-infographic.png _diagrams/info-{chapter-slug}.png
```

记录映射关系供 Step 4 使用:
| info-1 | 文档开篇(Hero) | _diagrams/info-overview.png | landscape |
| info-2 | 3. 核心模块开头 | _diagrams/info-modules.png | landscape |

### 3.5.4 生成失败处理

- 如果 han-infographic 无法出图（无后端/key/运行时工具），跳过该信息图
- 在文档对应位置标注 `[信息图: <主题> — 未能生成，可后续通过"加个信息图"命令补充]`
- 不阻塞 D2 图表生成和文档输出

### 3.5.5 信息图补充模式（快捷入口）

当用户说"加个信息图"或"配张概念图"时，提取概念内容，跳过 D2 部分直接执行 3.5 流程。生成的信息图追加到现有文档。

**完成后，读取 `workflows/step-04-write.md` 继续。**
