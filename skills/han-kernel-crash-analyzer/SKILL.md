---
name: han-kernel-crash-analyzer
description: >
  Two modes:
  [分析模式] Analyze Linux kernel crash dumps (NULL pointer dereference, KASAN UAF,
  SLUB corruption, ABBA deadlock, kernel panic, ramdump) on Qualcomm/Android
  platforms. Trigger when user mentions kernel crash, 死机, ramdump, KASAN, kernel
  panic, NULL pointer, deadlock, SLUB redzone, DDR blue screen, or provides crash
  dump files (parser_out, symbols, kasan.txt).
  [反馈闭环模式] Trigger when user signals the problem is resolved (问题解决了, 修好了,
  修复生效, 搞定了, 根因确认了, 不再复现). Review historical cases in data/cases/,
  ask user to confirm which analysis was correct, update patterns.json confidence,
  and close the feedback loop.
---

# Kernel Crash Analyzer V2

分析 Linux 内核死机问题，覆盖高通/Android 平台常见 crash 类型。V2 基于 han-skill-creator-plus 模板重构。

## 核心原则

1. **先反汇编，再下结论** — 必须从 crash log 提取 fault address，用 objdump 定位到具体指令，再追溯到源码行。反汇编之前不得给根因结论。
2. **改 init/probe 代码前，先验证执行顺序** — 追踪完整回调序列，确认修复点在时间线上正确，不会被后续操作覆盖。
3. **先确认范围，再输出** — 分析开始前重述分析范围，让用户确认后再动手。

## 模式判断

**先判断用户意图属于哪种模式**：

| 触发信号 | 模式 | 动作 |
|----------|------|------|
| crash/死机/ramdump/KASAN/panic 等 + 文件路径 | 分析模式 | 进入下方 Workflow |
| 问题解决了/修好了/修复生效/搞定了/根因确认了/不再复现 | 反馈闭环模式 | 跳过分析，直接读取 `workflows/feedback-loop.md` |

## 预检清单（分析模式）

在进入工作流之前快速判断：
- 用户是否已明确提供 crash 类型 + 文件路径？→ 可能跳过 Step 0/1，直接进入 Step 2
- 用户是否只说"分析这个"没有上下文？→ 严格从 Step 0 开始
- 是否有多个 crash log？→ 先定位主 crash log

## Workflow

本 skill 使用 11 步工作流（Step 0 ~ Step 10），按顺序执行。**每个步骤开始时，先 Read 对应的详细指令文件：**

| Step | 文件 | 做什么 |
|------|------|--------|
| 0 | `workflows/step-00-scenario.md` | 交互式收集场景信息 + 内核源码路径 |
| 1 | `workflows/step-01-inputs.md` | 自动检测 + 收集 crash 输入文件 |
| 2 | `workflows/step-02-encoding.md` | 检测文件编码和格式 |
| 3 | `workflows/step-03-crash-type.md` | 签名匹配识别 crash 类型 |
| 4 | `workflows/step-04-extract.md` | 从 crash log 提取关键信息 |
| 5 | `workflows/step-05-disasm.md` | 反汇编分析（最关键步骤） |
| 6 | `workflows/step-06-source.md` | 源码因果追踪 |
| 7 | `workflows/step-07-symptom.md` | 区分症状与根因 + 质量自查 |
| 7A | `workflows/adversarial-verify.md` A 节 | Agent 对抗验证根因结论 |
| 8 | `workflows/step-08-fix.md` | 提出修复建议 |
| 8A | `workflows/adversarial-verify.md` B 节 | Agent 对抗验证修复方案 |
| 9 | `workflows/step-09-report.md` | 输出报告 + 案例自动存档 |
| 10 | `workflows/step-10-learn.md` | 收录新类型/场景 |

**反馈闭环由用户主动触发（"修好了/搞定了"等），不在分析流程中自动弹出。触发后读取 `workflows/feedback-loop.md`。**

**Step 7A 和 8A 是 Agent 对抗验证步骤。Agent tool 不可用或调用失败时跳过这两个步骤，回退到现有手动流程（不阻塞后续步骤）。**

**开始分析时，首先读取 `workflows/step-00-scenario.md`。**

## 参考资料速查

- 签名匹配表：`references/signature_table.md`（硬编码回退）
- 崩溃类型专项指南：`references/crash_types.md`（各类详细分析策略）
- 平台怪癖：`references/platform_quirks.md`（内核/平台版本特定知识）
- 工具链备忘：`references/tool_chain.md`（反汇编工具优先级 + 安装）
- 分析手册模板：`references/analysis-manual-template.md`（闭环时生成操作手册的结构要求和生成原则）
- 自学习签名库：`data/signatures.json`（运行时优先查询此文件）
- 根因模式库：`data/patterns.json`（历史分析模式累积）
- 工具链缓存：`data/tool_cache.json`（按工作区缓存可用工具）
- **vmlinux 匹配（禅道 ramdump）**：Skill `zentao-bug-log-fetch` §「vmlinux 匹配」— 检索范围仅 `aosp-log-analysis-workspace/`，`Linux version` 整行 EXACT MATCH
- **vmlinux 匹配（禅道 ramdump）**：Skill `zentao-bug-log-fetch` §「vmlinux 匹配」— 检索范围仅 `aosp-log-analysis-workspace/`，`Linux version` 整行 EXACT MATCH

## 崩溃类型速览

| Crash 签名 | 类型 | 分析重点 |
|---|---|---|
| `Unable to handle kernel NULL pointer dereference` | NULL 指针解引用 | ERR_PTR 转换、错误路径返回 |
| `KASAN: use-after-free` | KASAN UAF | alloc/free 时间线、竞态条件 |
| `KASAN: slab-out-of-bounds` | KASAN OOB | 数组边界、结构体大小变化 |
| `SLUB: redzone` | SLUB 红区损坏 | 相邻对象越界写入 |
| `Kernel panic - not syncing` | 通用 panic | 先找 taint 来源，再追根因 |
| `BUG: scheduling while atomic` | 原子上下文调度 | mutex/sleep 调用路径 |
| mutex 交叉持有 | ABBA 死锁 | 锁依赖图、错误路径 unlock 缺失 |

## MCP 集成预留

如果未来有 `crash-log-parser` MCP 服务可用，Step 3/4/5 可调用 MCP 工具加速（`match_signature`、`parse_crash_log`、`disassemble_at`）。MCP 不可用时回退到手动流程——MCP 是加速器，不是必要条件。
