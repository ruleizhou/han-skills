# FeatDev Router（路由 + 分派一体化）

SKILL.md 已预跑 `scan_routes.py` 并缓存结果到 `R`。本文件从 `R.by_scenario.featdev` 提取数据，连续完成三级选择 + 分派，**无中间 Read**。

## 三级选择（连续执行，禁止跳过）

### 选平台

```
platforms = sorted(R.by_scenario.featdev.keys())
```

AskUserQuestion（header: "平台"）：选项来自 `platforms` + `手动输入`。
手动输入规范化：全小写、空格→下划线、去除非字母数字下划线。

### 选子系统

```
subsystems = sorted(R.by_scenario.featdev[selected_platform].keys())
```

AskUserQuestion（header: "子系统"）：选项来自 `subsystems` + `手动输入`。
示例：Power / Thermal / Memory / Scheduler / Filesystem / Network / Driver

### 选功能类型

```
types = R.by_scenario.featdev[selected_platform][selected_subsystem]
```

AskUserQuestion（header: "功能类型"）：选项来自 `types` + `手动输入`。

## 分派

### 路径

```
path = references/featdev/<platform>/<subsystem>/<type>/
```

### 创建缺失目录

```bash
mkdir -p references/featdev/<platform>/<subsystem>/<type>/
```
平台/子系统目录不存在时补建 `.gitkeep`。

### 检查 & 分派

```bash
test -f references/featdev/<platform>/<subsystem>/<type>/SKILL.md
```

- **存在** → 输出 `定位到功能开发子 skill: <platform>/<subsystem>/<type>`，展示 description，按子 skill 工作流执行
- **不存在** → 输出 `尚无专用子 skill，进入通用功能开发框架`，读取 `workflows/featdev-step-03-featdev-guide.md`
