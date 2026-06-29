# Util Tools - 内核工具总路由

内核开发工具的总入口，按 **场景 → 平台 → 模块 → 类型** 四级交互引导，覆盖三大场景：

- **Debug** — 调试/排查/定位根因
- **器件 Bringup** — 新硬件接入/驱动开发
- **功能开发** — 新特性实现/内核增强

自动路由到对应子 skill，子 skill 不存在时走通用框架，完成后可自动沉淀为新的子 skill。

## 适用场景

**Debug**：
- "看下这个死机 log"
- "分析 USB 拷贝速度"
- "Recovery 模式 U 盘挂载失败"
- "分析内存泄漏"
- 任何需要调试/排查/定位根因的问题

**器件 Bringup**：
- "帮我 bringup 一个 I2C sensor"
- "新加一个 Camera 驱动"
- "DTS 怎么配置这个器件"

**功能开发**：
- "帮我实现一个 sysfs 接口"
- "给这个驱动加 suspend/resume"
- "新增一个 kernel feature"

## 工作流程

```
用户描述需求 → 场景选择 → 三级交互（平台/模块/类型）→ 子 skill 存在？
                                                            ├─ 是 → 调用子 skill
                                                            └─ 否 → 通用框架 → 完成后创建子 skill
```

### Step 0: 场景选择

通过 AskUserQuestion 选择场景（Debug / 器件 Bringup / 功能开发），进入对应分支。

### Debug 分支

- **Step 1**: 平台→模块→问题类型 三级联动路由
- **Step 2**: 路径分派，子 skill 存在→调用，不存在→通用调试
- **Step 3**: 五维排查框架（问题细化→信息收集→定位范围→时间线→收敛结论）

### Bringup 分支

- **Step 1**: 平台→模块→器件类型 三级联动路由
- **Step 2**: 路径分派，子 skill 存在→调用，不存在→通用 bringup
- **Step 3**: 6 阶段 bringup 框架（需求收集→DTS 配置→驱动开发→编译集成→测试验证→学习归档）

### FeatDev 分支

- **Step 1**: 平台→子系统→功能类型 三级联动路由
- **Step 2**: 路径分派，子 skill 存在→调用，不存在→通用功能开发
- **Step 3**: 6 阶段功能开发框架（需求分析→代码研究→方案设计→编码实现→测试验证→学习归档）

### 反馈闭环

用户发出完成信号时触发（"修好了/跑通了/上线了"），回顾过程并确认结论。

## 目录结构

```
util-tools/
├── SKILL.md                              # 主路由（≤100 行）
├── workflows/
│   ├── step-00-scenario.md               # 场景选择
│   ├── debug-step-01-router.md           # Debug 路由
│   ├── debug-step-02-invoke.md           # Debug 分派
│   ├── debug-step-03-debug-fallback.md   # 通用调试
│   ├── debug-step-04-create-subskill.md  # 委托创建子 skill
│   ├── bringup-step-01-router.md         # Bringup 路由
│   ├── bringup-step-02-invoke.md         # Bringup 分派
│   ├── bringup-step-03-bringup-guide.md  # 通用 bringup
│   ├── featdev-step-01-router.md         # FeatDev 路由
│   ├── featdev-step-02-invoke.md         # FeatDev 分派
│   ├── featdev-step-03-featdev-guide.md  # 通用功能开发
│   └── feedback-loop.md                  # 反馈闭环（共享）
├── scripts/
│   └── scan_routes.py                    # 目录扫描 + 索引生成
└── references/
    ├── debug/<platform>/<module>/<type>/  # Debug 子 skill
    ├── bringup/<platform>/<module>/<type>/ # Bringup 子 skill
    ├── featdev/<platform>/<module>/<type>/ # FeatDev 子 skill
    └── subskill-catalog.md               # 子 skill 索引（自动生成）
```

## 已收录子 Skill

| 场景 | 平台 | 模块 | 问题类型 | 子 skill 名 | 添加日期 |
|------|------|------|----------|------------|----------|
| debug | Qualcomm | Stability | kernel-crash-analyzer | kernel-crash-analyzer-v2 | 2026-05-24 |
| debug | Qualcomm | USB | usb-transfer-analyzer | usb-transfer-analyzer | 2026-05-24 |
| debug | Qualcomm | Recovery | storage-mount | recovery-storage-mount | 2026-05-29 |
| debug | Qualcomm | Recovery | storage-mount | recovery-storage-mount | 2026-05-29 |

> 索引由 `scan_routes.py --catalog` 自动生成，新增子 skill 后需刷新。

## 使用方式

在 Claude Code 中描述需求即可自动触发，或通过命令：

```
/util-tools
```

## 新增子 Skill

通用框架完成任务后，会自动引导创建子 skill（委托 `skill-creator-plus`），所有子 skill 默认获得：

- 拆分架构（workflows/ 按步骤组织）
- 自主学习能力（data/patterns.json 置信度评分）
- 反馈闭环（data/cases/ 历史案例存档）
