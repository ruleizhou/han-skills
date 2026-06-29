# Step 0: 交互式获取场景信息

**分析开始前，必须先使用 `AskUserQuestion` 收集死机场景和内核源码路径。** 这两个信息决定后续分析的侧重点和反汇编定位能力。

```json
// AskUserQuestion 调用参数
questions:
  - question: "请描述本次死机的具体情况（触发场景、现象、是否可复现等）？"
    header: "死机场景"
    options:
      - label: "我来描述"
        description: "选择此项后在下方输入框描述死机的具体情况，包括触发操作、现象、复现条件等"
  - question: "内核源码树在哪个路径？"
    header: "源码路径"
    options:
      - label: "当前工作目录"
        description: "使用当前目录作为内核源码根目录，objdump 和源码行映射都从这里定位"
```

**场景信息用途**：
- 帮助判断 crash 是竞态问题、电源管理问题还是初始化顺序问题
- 影响 Step 6 源码分析的必查清单优先级（如"插拔外设"→ 优先查竞态和错误路径清理）
- 如果用户描述的场景与后续分析发现不符，主动提出
- 场景描述会记录到案例存档（`data/cases/`）

**完成后，读取 `workflows/step-01-inputs.md` 继续。**
