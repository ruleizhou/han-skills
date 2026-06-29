# D2 Diagram Skill V2

基于 [D2](https://d2lang.com/) 声明式图表语言的 Claude Code Skill，支持生成专业图表、架构图、流程图等，并可应用手绘/草图风格。

V2 采用文件拆分架构 + 自主学习，按需加载步骤文件，越用越完善。

## 功能

- 将文字描述转化为 D2 图表代码并编译为 PNG/SVG
- 支持手绘风格（`--sketch`）
- 内置 8 种图表模板：架构图、流程图、ER图、拓扑图、序列图、类图、状态机、甘特图
- 智能需求诊断（快速创建/需求理解/代码优化/语法查询）
- 代码质量校验和常见错误预防
- 自主学习（模式积累、用户偏好、反馈闭环）
- 中文标注友好

## 使用方式

在 Claude Code 中直接描述你想要的图表即可触发，例如：

```
画一个微服务系统架构图
帮我画一个用户注册的流程图
生成一个订单系统的 ER 图
画一个 UML 类图，展示用户和订单的关系
```

## 架构

V2 采用路由层 + 按需加载架构：

```
han-d2-diagram/
├── SKILL.md                  # 路由层（≤100行），模式判断和导航
├── VERSION                   # 版本号
├── workflows/                # 分步骤按需加载
│   ├── step-00-diagnose.md          # 需求诊断
│   ├── step-01-select-objects.md    # 选择 D2 shapes
│   ├── step-02-write-code.md        # 编写 D2 代码
│   ├── step-03-apply-styling.md     # 应用样式
│   ├── step-04-validate-compile.md  # 验证并编译
│   ├── step-05-iterate-optimize.md  # 迭代优化
│   ├── step-06-learn.md             # 自主学习收录
│   └── feedback-loop.md             # 反馈闭环
├── data/                     # 自学习数据
│   ├── patterns.json                # 模式库
│   └── cases/                       # 案例归档
├── references/               # 参考文档
│   ├── d2-cheatsheet.md             # 语法速查
│   ├── d2-themes.md                 # 主题参考
│   └── d2-shapes-guide.md           # Shapes 语法指南
└── assets/templates/         # 8 种图表模板
    ├── system-architecture.d2
    ├── flowchart.d2
    ├── er-diagram.d2
    ├── network-topology.d2
    ├── sequence-diagram.d2
    ├── class-diagram.d2
    ├── state-machine.d2
    └── gantt-chart.d2
```

## 编译命令

```bash
# 标准 PNG 输出
d2 --theme=300 -l elk input.d2 output.png

# SVG 输出（支持暗色主题）
d2 --theme=300 --dark-theme=200 -l elk input.d2 output.svg

# 手绘风格
d2 --theme=300 -l elk --sketch input.d2 output.png
```

**约定：** 每次编译同时生成 PNG 和 SVG 两种格式。

## 依赖

- [D2 CLI](https://github.com/terrastruct/d2) — 需要本地安装 `d2` 命令行工具
- ELK 布局引擎（通过 `-l elk` 参数启用）

## 更多资源

- [D2 官方文档](https://d2lang.com/tour/intro/)
- [D2 GitHub 仓库](https://github.com/terrastruct/d2)
