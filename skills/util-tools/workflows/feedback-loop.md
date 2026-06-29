# 反馈闭环

## 触发条件

用户主动发出完成信号时触发（被动触发，不主动弹出）：

- **Debug 场景**："问题解决了"、"修好了"、"搞定了"、"根因确认了"、"不再复现"、"修复生效"、"验证通过"
- **Bringup 场景**："器件跑通了"、"bringup 完成了"、"点亮了"、"工作正常"
- **FeatDev 场景**："功能上线了"、"开发完成了"、"测试通过"、"功能正常"

## 流程（5 步）

### 1. 回顾

从对话历史中提取：
- 场景类型（debug / bringup / featdev）
- 路由路径（scenario/platform/module/type）
- 处理模式（子 skill / 通用框架）
- 问题描述和现象
- 关键步骤
- 根因/结论和解决方案
- 使用的子 skill 名称（如有）
- 用户提供的代码路径（如有）

### 2. 呈现

以表格形式向用户展示处理链路：

```
## 处理过程回顾

| 项目 | 内容 |
|------|------|
| 场景 | <scenario> |
| 路由路径 | <scenario>/<platform>/<module>/<type> |
| 处理模式 | 子 skill: <name> / 通用框架 |
| 问题/需求 | <summary> |
| 根因/方案 | <root_cause_or_solution> |
| 代码路径 | <code_paths> |
| 关键词 | <keywords> |
```

### 3. 确认

用 AskUserQuestion 确认：

```
question: "分析/处理结果是否正确有效？"
header: "效果确认"
options:
  - label: "正确有效"
    description: "根因准确/方案有效/功能正常"
  - label: "部分有效"
    description: "方向正确但不完全准确"
  - label: "不太对"
    description: "分析不准或方案无效"
```

### 4. 生成文档

基于对话内容生成结构化文档（在对话中展示）：

```
## 分析文档

### 基本信息
- 日期：YYYY-MM-DD
- 场景：<scenario>
- 平台：<platform>
- 模块：<module>
- 类型：<type>

### 问题/需求描述
<用户看到的描述>

### 处理过程
1. <关键步骤 1>
2. <关键步骤 2>
...

### 根因/方案
<结论>（附关键证据）

### 经验总结
<关键经验>
```

### 5. 询问创建/更新子 skill

#### 5.1 通用框架模式（无子 skill）

用 AskUserQuestion 询问是否创建子 skill：

```
question: "该类型尚无专用子 skill，是否创建？"
header: "创建子 skill"
options:
  - label: "创建子 skill（推荐）"
    description: "基于本次经验创建子 skill。下次遇到同类需求可直接定位。"
  - label: "不创建"
    description: "本次结果仅保留在对话中。"
```

- 选"创建" → 读取对应场景的 create-subskill 文件：
  - Debug → `workflows/debug-step-04-create-subskill.md`
  - Bringup → 委托 `skill-creator-plus`
  - FeatDev → 委托 `skill-creator-plus`
- 选"不创建" → 结束

#### 5.2 子 skill 模式（子 skill 已存在）

分析本次处理过程中子 skill 的覆盖完整性，如有未覆盖情况 → 询问是否更新子 skill。

### 6. 输出闭环总结

```
## 反馈闭环完成

- 场景：<scenario>
- 子 skill 操作：<无/已创建/已更新>
- 分析文档：<已在对话中生成>
- 状态：<已解决/已完成/部分解决>
```

---

闭环结束后，所有步骤结束。
