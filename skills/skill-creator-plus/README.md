# Skill Creator Plus

在官方 skill-creator 基础上，创建自带**文件拆分架构**和**自主学习能力**的 skill。也可为已有单体 skill 追加这两种能力。

## 核心理念

| 问题 | 解法 |
|------|------|
| SKILL.md 动辄 300-500 行，token 浪费 | 路由层 ≤100 行 + workflows/ 按需加载，省 60-80% |
| Skill 创建后就"死"了，不会进化 | patterns.json 置信度评分 + feedback-loop，越用越完善 |
| 复杂 skill 步骤耦合，改一发动全身 | 每步独立文件，改步骤不影响其他步骤 |

## 适用场景

- 创建复杂多步骤的 skill（单一输入→多阶段分析→结构化输出）
- Skill 需要在真实使用中持续优化（诊断类、分析类、决策类）
- 将已有的单体 SKILL.md（>200 行）拆分为多文件架构
- 为 skill 添加"修好了/搞定了"的反馈闭环能力

不需要的场景：简单一步式 skill、纯格式转换 skill — 这些用官方 skill-creator 直接写单文件即可。

## 架构

```
skill-creator-plus/
├── SKILL.md                          # 路由层（52 行）
├── workflows/                        # 按需加载的步骤文件
│   ├── step-00-needs.md              # 需求捕获 + 架构选择
│   ├── step-01-gen-split-arch.md     # 从模板生成拆分结构
│   ├── step-02-gen-self-learning.md  # 添加自主学习基础设施
│   ├── step-03-eval-iterate.md       # 评估与迭代（复用官方 skill-creator）
│   ├── step-04-migrate.md            # 已有 skill 迁移
│   └── step-05-package.md            # 打包（复用官方 package_skill.py）
├── templates/                        # 可复用的 skill 模板
│   ├── split-arch/                   # 拆分架构模板
│   │   ├── SKILL.md.template         #   路由层模板
│   │   └── workflows/
│   │       └── step-NN-name.md.template
│   └── self-learning/                # 自学习基础设施模板
│       ├── data/
│       │   ├── patterns.json.template #   通用模式库（含 confidence 规则）
│       │   └── cases/.gitkeep
│       ├── workflows/
│       │   ├── feedback-loop.md.template   # 通用 7 步闭环
│       │   └── step-XX-learn.md.template   # 通用学习步骤
│       └── references/
│           └── domain-knowledge.md.template
└── references/                       # 参考文档
    ├── split-architecture.md         # 拆分架构说明
    └── self-learning-mechanism.md    # 自主学习机制说明
```

## 两种能力详解

### 1. 文件拆分架构

将单体 SKILL.md 拆为路由层 + 步骤文件：

```
传统（单体）                         拆分后
─────────────                      ─────────────
SKILL.md (400 行)                  SKILL.md (80 行)  ← 路由层
  全部内容每次触发都加载               ├── step-00-xxx.md  ← 仅当前步骤加载
                                     ├── step-01-xxx.md
                                     ├── ...
                                     └── step-NN-xxx.md
```

**机制**：不是框架 import，而是 SKILL.md 中的路由表告诉 AI "先 Read workflows/step-00.md"，每个步骤末尾写明 "完成后，读取 workflows/step-01.md 继续"。

**收益**：每步只加载 ~50 行指令而非一次性 400 行，复杂 skill 越明显。

### 2. 自主学习能力

三层架构，让 skill 在真实使用中积累经验：

| 层 | 文件 | 职责 |
|----|------|------|
| 反馈层 | `workflows/feedback-loop.md` | 用户喊"搞定了"→ 回顾 → 确认 → 存档 → 更新置信度 |
| 学习层 | `workflows/step-XX-learn.md` | 每次任务后收录新模式/新类型（自动，不需用户确认） |
| 数据层 | `data/patterns.json` + `data/cases/` | 持久化存储，confidence: success +1, fail -1, <0 移除 |

**触发**：反馈闭环完全被动 — 用户不主动发信号绝不弹出。学习层在任务主流程最后一步自动执行。

## 工作流程

```
需求捕获 → 架构选择 → 生成拆分结构 → 添加自学习 → 评估迭代 → 打包
                │                        │
                ├─ 选"仅拆分"  跳过自学习 ─┘
                └─ 选"传统"    转官方 skill-creator
```

存量 skill 迁移有独立路径（Step 4），检测现有结构 → 提取切分点 → 拆分 → 可选加自学习。

### 详细流程

1. **需求捕获（Step 0）** — 前置闸门判断值不值得做 → 一次一问挖四要素 → 确认门回述获批
2. **架构选择（Step 0）** — 拆分+自学习 / 仅拆分 / 传统单文件（后者转官方 skill-creator）
3. **生成拆分结构（Step 1）** — 从模板生成 SKILL.md 路由层 + workflows/ 步骤文件 → 草稿自检
4. **添加自学习（Step 2，可选）** — data/patterns.json + feedback-loop + learn 步骤
5. **评估迭代（Step 3）** — 默认轻量「跑给你看」，重型量化按需（见 `references/评测指南.md`）
6. **打包（Step 5）** — 复用官方 package_skill.py 生成 .skill
7. **最后一公里（Step 6）** — 安装位置、name 校验、重启会话、自测触发

迁移已有 skill 走 Step 4（检测结构 → 拆分 → 可选加自学习），不经过创建流程。

## 使用方式

在 Claude Code 中通过 skill 自动触发：

- "创建一个能自学习的 skill，用来分析 XX"
- "把这个 skill 拆分成多个文件，太长了"
- "为 kernel-crash-analyzer 加上反馈闭环"

### 和官方 skill-creator 的分工

| | 官方 skill-creator | skill-creator-plus |
|--|-------------------|-------------------|
| 创建简单 skill | 用这个 | 不适用 |
| 创建复杂 skill | 可以用（单体文件） | 更好（拆分+自学习） |
| Eval/迭代/打包 | 提供（scripts/） | 复用官方的 |
| 文件拆分 | 手动 | 模板自动生成 |
| 自学习 | 无 | patterns.json + feedback-loop |

## 依赖

无外部依赖。Eval 和打包复用官方 skill-creator 的 Python 脚本（`~/.claude/plugins/.../skill-creator/scripts/`）。

## FAQ

**和官方 skill-creator 什么关系？**
增强版。复用官方成熟的 eval/打包后端，新增文件拆分架构 + 自主学习能力。简单 skill 用官方即可，复杂 skill 用本 skill。

**能一次生成一整套相关 skill 吗？**
不能。每次聚焦做好一个 skill。若想法其实是好几个，会提醒拆开。

**支持英文吗？**
中文优先，但跟随用户语言——你用英文它就用英文。

**生成的 skill 怎么自测触发？**
新开会话，用接近真实需求的语句试。任务越具体越容易触发；简单单步操作不触发是正常的。详见 Step 6「最后一公里」。

## 参考资料

- `references/split-architecture.md` — 拆分架构详细说明（收益对比、编写规范、目录对照）
- `references/self-learning-mechanism.md` — 自主学习三层架构说明（数据层/学习层/反馈层）
- `templates/` — 拆分 + 自学会模板文件，`step-01` 和 `step-02` 从这些模板生成 skill 骨架
- `../kernel-crash-analyzer/` — 拆分+自学习架构的 live reference
