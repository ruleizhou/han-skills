# Debug Step 4: 委托 skill-creator-plus 创建子 skill

## 目标

通用调试成功后，统一委托 `skill-creator-plus` 为该问题类型创建子 skill。
**所有子 skill 默认获得拆分架构 + 自学习能力。**

## 前置条件

本步骤由反馈闭环（feedback-loop.md）在确认问题解决且用户同意创建后触发，不自动执行。

## 流程

### 4.1 收集创建上下文

从本次调试中提取完整上下文：

```markdown
## 子 skill 创建上下文

### 路由信息
- 场景：debug
- 平台：<platform>
- 模块：<module>
- 问题类型：<type>
- 创建路径：references/debug/<platform>/<module>/<type>/

### 问题特征
- 现象描述：<问题现象>
- 排查要点：<关键排查步骤（已在实际调试中验证有效）>
- 根因分析：<根因结论>
- 修复方案：<采用或建议的修复方案>
- 关键代码路径：<用户提供的代码路径>
- 关键词：<从描述和分析中提取的关键词列表>

### 创建要求
- 需要：文件拆分架构 (SKILL.md 路由层 + workflows/ 分步骤) + 自主学习能力 (feedback-loop + learn 步骤 + data/patterns.json + data/cases/)
- 启动 skill-creator-plus 后，自动进入其 step-01 (gen-split-arch) + step-02 (gen-self-learning)
```

### 4.2 委托 skill-creator-plus

**统一走 skill-creator-plus，不再自行创建文件。**

直接调用：

```
Skill(skill="skill-creator-plus", args="<上一步收集的创建上下文>")
```

### 4.3 创建后刷新索引

skill-creator-plus 完成创建后，刷新索引：

```bash
python3 scripts/scan_routes.py --catalog
```

---

完成后，输出闭环总结，所有步骤结束。
