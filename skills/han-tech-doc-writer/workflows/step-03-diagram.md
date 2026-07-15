# Step 3: 图表与信息图生成

根据 Step 2 的图表清单和信息图清单，依次生成 D2 图表（SVG）和信息图（PNG）。

**开始前读取** `references/obsidian-guide.md` §4（目录与命名）。

## 3.0 准备工作

### 检测 D2 CLI

```bash
which d2 && d2 --version
```

如果 `d2` 未安装，告知用户：
> D2 CLI 未安装，将输出 D2 源代码作为代码块嵌入文档。安装 D2 后可手动编译：`d2 --theme=300 --dark-theme=200 -l elk input.d2 output.svg`

### 创建图片目录

在 **Step 1.6 确认的 `output_dir`** 下创建：

```bash
mkdir -p <output_dir>/_diagrams
```

所有 .d2 源文件、SVG 产物和信息图 PNG 都放在**与 .md 同目录**的 `_diagrams/` 下。`output_dir` 本身须已在 Step 1.6 经用户确认存在。

### 页面 slug

`slug` = Obsidian 页面标题（= 文件名去 `.md`），用于所有 `_diagrams/` 文件命名。

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
- 暗色：`--dark-theme=200`（SVG 内嵌亮/暗双主题，Obsidian 自动适配）
- 布局：`-l elk`（**必须显式指定**）
- 不加 `--sketch`（技术文档需要正式风格）

### d. 写 D2 代码

基于模板骨架，填入实际内容：
- 所有节点标签使用中文
- 技术术语保留英文
- 连接线标注关键操作/数据
- 使用 `_diagrams/<slug>-<短码>.d2` 命名（短码：arch/flow/state/seq/er/class/net/gantt）

## 3.3 编译（SVG 首选）

对每个 .d2 文件，**必须**编译 SVG：

```bash
d2 --theme=300 --dark-theme=200 -l elk _diagrams/<slug>-<短码>.d2 _diagrams/<slug>-<短码>.svg
```

PNG 为可选（Obsidian 正文嵌入用 SVG，**不因 PNG 失败而中断**）：

```bash
d2 --theme=300 -l elk _diagrams/<slug>-<短码>.d2 _diagrams/<slug>-<短码>.png
```

### 编译失败处理

常见错误及修复：
- 语法错误 → 对照 d2-cheatsheet.md 检查，修正后重试
- 中文显示异常 → 确认系统字体支持中文，必要时用英文标签兜底
- 布局重叠 → 调整节点位置或简化层级（**保持 `-l elk`**）
- PNG 失败（Playwright 未装）→ 忽略，SVG 成功即可继续

### 编译成功后

验证 SVG 文件存在且非空：
```bash
ls -lh _diagrams/<slug>-*.svg
```

## 3.4 图表补充模式（快捷入口）

当用户说"加个图"或"画个架构图"时，跳过 Step 0-2，直接执行：

1. 从对话上下文或现有 Obsidian 页面提取需要配图的概念/模块/流程
2. 读取现有页面的 frontmatter `title` 作为 slug
3. 如果用户指定了图表类型，直接使用；否则根据内容推断
4. 如果当前目录已有 `_diagrams/` 和文档 .md 文件，将新图追加到现有文档（Obsidian wikilink 嵌入）
5. 执行 3.1 → 3.2 → 3.3 流程

## 3.5 信息图生成

D2 图表全部完成后，对 Step 2 信息图清单中的每一项生成信息图。

### 3.5.1 准备调用参数

对每个信息图候选，组装请求字符串：

```
为一份技术文档的[位置描述，如"文档开篇"/"第X章开头"]生成概念信息图。

文档主题: [Obsidian 页面标题]
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

复制到 vault 的 `_diagrams/`，按 Obsidian 命名规范重命名:
```bash
cp ~/Downloads/han-skill-imagen/{slug}-infographic.png _diagrams/<页面slug>-info.png
```

多信息图时用 `-info-2`、`-info-3` 后缀区分。

记录映射关系供 Step 4 使用:
| info-1 | 文档开篇(Hero) | _diagrams/<slug>-info.png | landscape |
| info-2 | 3. 核心模块开头 | _diagrams/<slug>-info-2.png | landscape |

### 3.5.4 生成失败处理

- 如果 han-infographic 无法出图（无后端/key/运行时工具），跳过该信息图
- 在文档对应位置标注 `> 🎨 *信息图: <主题> — 未能生成，可后续通过"加个信息图"命令补充*`
- 不阻塞 D2 图表生成和文档输出

### 3.5.5 信息图补充模式（快捷入口）

当用户说"加个信息图"或"配张概念图"时，提取概念内容，跳过 D2 部分直接执行 3.5 流程。生成的信息图追加到现有 Obsidian 文档。

**完成后，读取 `workflows/step-04-write.md` 继续。**
