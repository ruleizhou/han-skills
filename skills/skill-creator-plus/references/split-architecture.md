# 文件拆分架构

## 为什么拆分

Claude Code 的 skill 系统使用三级渐进加载：

1. **元数据**（name + description）— 始终在上下文中（~100 词）
2. **SKILL.md 正文** — skill 触发时加载（建议 <500 行）
3. **打包资源**（scripts/、references/、assets/）— 按需加载

"拆分架构"扩展了第 2 层：**SKILL.md 仅做路由（≤100 行），实际工作流指令放在 `workflows/` 目录中按需 Read。**

### 收益

| 维度 | 单体 SKILL.md | 拆分架构 |
|------|-------------|---------|
| Token 消耗 | 每次触发全量加载 | 仅加载当前步骤，省 60-80% |
| 可维护性 | 改一处影响全局 | 步骤独立，互不干扰 |
| 可读性 | 长文滚动，难以定位 | 单步聚焦，职责清晰 |
| 扩展性 | 加步骤=加行数，恶性膨胀 | 加文件即可，不影响路由层 |

## 目录结构

```
skill-name/
├── SKILL.md                    # 路由层（≤100 行）
│   ├── YAML frontmatter        # name + description（触发匹配）
│   ├── 核心原则                  # 最高优先级规则（3-5 条）
│   ├── 模式判断                  # 触发信号 → 模式 → 动作 路由表
│   ├── Workflow 表格            # Step | 文件 | 做什么（串联索引）
│   └── 参考资料速查               # references/ data/ 路径速查
├── workflows/                  # 按需加载的步骤文件
│   ├── step-00-xxx.md          # 每个步骤一个文件
│   ├── step-01-xxx.md
│   ├── ...
│   ├── step-XX-learn.md        # 自主学习步骤（可选）
│   └── feedback-loop.md        # 反馈闭环（可选）
├── references/                 # 参考文档（需要时 Read）
├── data/                       # 自学习知识库（可选）
│   ├── patterns.json           # 模式/经验库（confidence 评分）
│   ├── signatures.json         # 特征签名库（可选）
│   └── cases/                  # 历史案例存档
├── evals/                      # 评估用例
└── scripts/                    # 辅助脚本
```

## 路由层编写规范

### SKILL.md 结构模板

```markdown
---
name: skill-name
description: > ...（触发条件 + 功能描述，~100 词）
---

# Skill Title

## 核心原则      （3-5 条最高优先级规则）

## 模式判断      （路由表：触发信号 → 模式 → 动作）

## 预检清单      （快速判断上下文，跳过不必要的步骤）

## Workflow      （步骤索引表：Step | 文件 | 做什么）

## 参考资料速查   （文件路径速查表）
```

### 要点

- **≤100 行**，超过说明有步骤细节混入了路由层
- **Workflow 表格**是核心，每行串联一个步骤文件
- 每个步骤文件末尾必须有 `完成后，读取 workflows/step-NN-xxx.md 继续`
- 模式判断明确写出触发条件和对应动作

## 步骤文件编写规范

### 命名

`step-NN-动词-名词.md`，如 `step-00-needs.md`、`step-03-crash-type.md`

### 内容

- 一个步骤只做一件事
- 开头标明 `# Step N: 标题`
- 结尾标明下一步 `完成后，读取 workflows/step-NN-xxx.md 继续`
- 引用外部文件时给出相对路径（从 skill 根目录起）

### 建议数量

- 3-7 个步骤：理想范围
- 8-12 个步骤：可接受，检查是否可以合并
- >12 个步骤：考虑拆分为子模式或分阶段

## 与官方目录的对应关系

| 官方目录 | 用途 | 拆分架构中 |
|----------|------|-----------|
| `scripts/` | 可执行代码 | 同，不变 |
| `references/` | 参考文档 | 同，不变 |
| `assets/` | 模板等资源 | 同，不变 |
| — | — | `workflows/`：步骤文件（扩展，非官方标准目录） |
| — | — | `data/`：自学习数据（扩展，非官方标准目录） |

`workflows/` 和 `data/` 不是官方 skill 系统的内置目录，但 AI 通过 Read 工具加载，效果等价。

## 多领域变体组织模式

一个 skill 跨多个领域/平台时，**不要把所有领域的细节塞进 SKILL.md**，而是按变体拆分到 `references/`，正文只留选择逻辑：

```
cloud-deploy/
├── SKILL.md          # 流程 + 领域选择逻辑（≤100 行）
└── references/
    ├── aws.md        # 只在用户要部署 AWS 时 Read
    ├── gcp.md        # 只在部署 GCP 时 Read
    └── azure.md      # 只在部署 Azure 时 Read
```

SKILL.md 里写清「用户提到 AWS → 读 `references/aws.md`」，Claude 只加载相关的变体文件，其余不进上下文。这是拆分架构省 token 的核心场景之一。

## 内部文件 vs 用户可见文件边界

skill 里的文件分两类，处理方式不同：

| 类型 | 例子 | 处理 |
|------|------|------|
| **机器读**（内部契约） | `scripts/*.py`、`agents/*.md`、schemas、`data/patterns.json` | 保持结构化原样，不需中文化 |
| **用户可见**（UI / 报告） | eval viewer、生成报告、给用户看的笔记 | 跟随用户语言中文化 |

划分原则：AI 读取解析的文件保持机器友好；最终呈现给用户看的内容跟随用户语言。混在一起会导致「机器该读的被翻译坏」或「用户该看的还是英文」。
