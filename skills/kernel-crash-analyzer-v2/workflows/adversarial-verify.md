# Agent 对抗验证

本文件包含两个独立的验证阶段，分别在 Step 7 之后和 Step 8 之后执行。

## 前提条件

本步骤需要以**独立视角**执行对抗验证。执行方式取决于当前环境：
- 支持 Agent/subagent 机制（如 Claude Code）→ 启动独立子代理执行验证 prompt
- 不支持独立代理 → 主分析者自行切换到"魔鬼代言人"角色执行验证 prompt

两种方式使用完全相同的验证 prompt，区别仅在于执行上下文是否独立。
验证 prompt **必须执行**，只是执行方式不同。

---

## A 节：根因对抗验证（Step 7 之后执行）

### 准备验证上下文

从已完成的分析中提取以下信息，构建 Agent prompt：

1. **崩溃类型** + fault address
2. **objdump 关键输出**（崩溃指令 ± 20 条）
3. **调用栈** + 寄存器值
4. **Step 7 的根因结论**（直接原因 + 根本原因）
5. **质量自查清单结果**
6. **Step 0 收集的场景描述**

### 调用对抗验证

以独立视角执行以下验证 prompt（不要沿用主分析的推理惯性）：
- 如果环境支持启动独立子代理（Agent tool / subagent / task 等），用它来执行
- 如果不支持，主分析者自行清空已有判断，纯从 prompt 角度出发作答

```
You are a senior kernel engineer reviewing a crash analysis. Your job is to
find flaws in the root cause conclusion, NOT to produce an alternative analysis.
You must challenge the conclusion, not agree with it.

The analysis claims:
- Crash type: <填入崩溃类型>
- Direct cause: <填入直接原因>
- Root cause: <填入根本原因>
- Evidence chain: <填入证据链摘要>
- Quality checklist: <填入自查结果>

Key objdump output:
<填入 objdump 关键指令>

Call stack:
<填入调用栈>

Challenge this conclusion on these specific axes:

1. **VICTIM vs PERPETRATOR**: Is the crash site the actual perpetrator, or could it
   be a victim of corruption from elsewhere? What evidence rules out the latter?
   Consider: memory corruption from adjacent objects, DMA corruption, use-after-free
   where freed memory was re-allocated.

2. **ALTERNATIVE HYPOTHESES**: Name 1-2 plausible alternative root causes that
   would produce identical or near-identical symptoms. For each, state what specific
   evidence would distinguish it from the concluded root cause.

3. **EVIDENCE GAPS**: What evidence is referenced in the conclusion but not
   actually shown? (e.g., "the driver does X" but no source line cited, or
   "the timer was already stopped" but no log evidence).

4. **INIT/PROBE TIMING** (if applicable): If this involves init/probe code,
   could the sequence have been different? Is the time-order assumption verifiable?
   If not applicable, skip this axis.

Output EXACTLY this format:
---
VERDICT: [CONCUR | CONCUR_WITH_CAUTION | DISAGREE]
CHALLENGES:
1. <specific concern>
2. <specific concern>
...
MISSING_EVIDENCE: <what would strengthen the conclusion>
ALTERNATIVE_HYPOTHESES: <if any, with distinguishing evidence>
---
```

### 处理结果

| VERDICT | 动作 |
|---------|------|
| `CONCUR` | 记录结果，继续到 `workflows/step-08-fix.md` |
| `CONCUR_WITH_CAUTION` | 记录 cautions，在修复设计中纳入注意事项，继续到 `workflows/step-08-fix.md` |
| `DISAGREE` | 回到 Step 6 或 Step 7，**针对 Agent 提出的具体质疑**补充分析。不要从头重启 |

**如果主分析者不同意 Agent 的 DISAGREE**：
用 1-2 句理由说明维持原结论："主分析者维持原结论，理由：<原因>"。
在报告中记录此覆盖及理由。**不进行多轮 Agent 对话——验证只做一轮。**

### 存储验证结果

将以下信息记录到内存，供 Step 9 报告和 feedback-loop 使用：
- Agent VERDICT
- Agent challenges 列表摘要
- 主分析者对 challenges 的回应（同意/不同意+理由）

---

## B 节：修复方案对抗验证（Step 8 之后执行）

### 准备验证上下文

从已完成的分析中提取：

1. **根因结论**（已通过 A 节验证）
2. **unified diff 修复方案**
3. **涉及修复点的源码上下文**（修复位置 ± 50 行）
4. **init/probe 执行顺序分析**（如适用）

### 调用对抗验证

以独立视角执行以下验证 prompt（不要沿用主分析的推理惯性）：
- 如果环境支持启动独立子代理（Agent tool / subagent / task 等），用它来执行
- 如果不支持，主分析者自行清空已有判断，纯从 prompt 角度出发作答

```
You are a kernel patch reviewer. The proposed fix is below. Find problems.
Be critical — your job is to prevent buggy patches from being accepted.

Root cause: <填入根因结论>
Proposed fix (unified diff):
<填入 diff 内容>

Source context around the fix:
<填入修复位置 ± 50 行源码>

Check for these specific issues:

1. **PARTIAL FIX**: Does the fix address the root cause completely, or only the
   immediate symptom? Will the same class of bug recur in another code path?
   Check: error paths, remove/shutdown paths, other callers of the same function.

2. **REGRESSION RISK**: Does the fix break error handling elsewhere? Does it
   change behavior for the success path? Does it add new failure modes?

3. **RACE WINDOW** (if concurrency fix): Does the new barrier actually close
   the window, or just narrow it? Is there a wider race still possible?
   If not a concurrency fix, skip this check.

4. **INIT/PROBE ORDER** (if applicable): If fix touches init/probe, does placing
   the fix at this point create a new dependency? Will a later init call overwrite it?
   If not applicable, skip this check.

5. **SEMANTIC CORRECTNESS**: Does the fix change error codes, return values, or
   control flow in a way that callers don't expect? Does it convert a hard crash
   into a silent data corruption?

Output EXACTLY this format:
---
VERDICT: [APPROVE | APPROVE_WITH_NOTES | REJECT]
ISSUES:
1. [HIGH/MEDIUM/LOW] <description>
2. [HIGH/MEDIUM/LOW] <description>
...
SUGGESTED_REVISIONS: <if any>
---
```

### 处理结果

| VERDICT | 动作 |
|---------|------|
| `APPROVE` | 记录结果，继续到 `workflows/step-09-report.md` |
| `APPROVE_WITH_NOTES` | 修复 Agent 指出的 MEDIUM/HIGH 问题，然后继续到 `workflows/step-09-report.md` |
| `REJECT` | 回到 Step 8，**根据 Agent 反驳重新设计修复方案**。必须解决所有 HIGH 级问题 |

**如果主分析者不同意 Agent 的 REJECT**：
用 1-2 句理由说明维持原方案："主分析者维持原修复方案，理由：<原因>"。
在报告中记录此覆盖及理由。**不进行多轮 Agent 对话——验证只做一轮。**

### 存储验证结果

将以下信息记录到内存，供 Step 9 报告和 feedback-loop 使用：
- Agent VERDICT
- Agent issues 列表摘要
- 主分析者对 issues 的回应（采纳/不采纳+理由）

**完成后，读取 `workflows/step-09-report.md` 继续。**
