# Debug Router（路由 + 分派一体化）

SKILL.md 已预跑 `scan_routes.py` 并缓存结果到 `R`。本文件从 `R.by_scenario.debug` 提取数据，连续完成三级选择 + 分派，**无中间 Read**。

## 三级选择（连续执行，禁止跳过）

### 选平台

```
platforms = sorted(R.by_scenario.debug.keys())
```

AskUserQuestion（header: "平台"）：选项来自 `platforms` + `手动输入`（空则仅显示手动输入）。
手动输入规范化：全小写、空格→下划线、去除非字母数字下划线。

### 选模块

```
modules = sorted(R.by_scenario.debug[selected_platform].keys())
```

AskUserQuestion（header: "模块"）：选项来自 `modules` + `手动输入`。

### 选类型

```
types = R.by_scenario.debug[selected_platform][selected_module]
```

AskUserQuestion（header: "问题类型"）：选项来自 `types` + `手动输入`。

## 分派

### 路径

```
path = references/debug/<platform>/<module>/<type>/
```

### 创建缺失目录

```bash
mkdir -p references/debug/<platform>/<module>/<type>/
```
平台/模块目录不存在时补建 `.gitkeep`。

### 检查 & 分派

```bash
test -f references/debug/<platform>/<module>/<type>/SKILL.md
```

- **存在** → 输出 `定位到 debug 子 skill: <platform>/<module>/<type>`，展示 description，按子 skill 工作流执行
- **不存在** → 输出 `尚无专用子 skill，进入通用调试`，读取 `workflows/debug-step-03-debug-fallback.md`
