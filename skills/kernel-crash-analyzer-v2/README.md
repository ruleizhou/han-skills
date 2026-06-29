# Kernel Crash Analyzer V2

分析 Linux 内核死机问题，覆盖高通/Android 平台常见 crash 类型。从 crash 现场出发，通过反汇编 + 源码双重追踪定位根本原因，区分症状与根因，输出结构化分析报告和修复建议。

V2 基于 skill-creator-plus 模板重构，V1 作为备份版本仅通过 `/kernel-crash-analyzer` 命令触发。

## 适用场景

- 高通/Android 平台 ramdump 解析后的 crash 分析（parser_out + symbols）
- NULL 指针解引用、KASAN UAF/OOB、SLUB 红区损坏
- ABBA 死锁、kernel panic、Oops
- 开机卡动画（bootanimation stuck）、reboot 卡住
- 内核 init/probe 阶段崩溃的调用序列分析

## 核心原则

1. **先反汇编，再下结论** — 必须从 crash log 提取 fault address，用 objdump 定位到具体指令，再从指令追溯到源码行，不得跳过反汇编直接给结论
2. **改 init/probe 代码前，先验证执行顺序** — 追踪完整回调序列，确认修复点在时间线上正确，不会被后续操作覆盖
3. **先确认范围，再输出** — 分析开始前重述分析范围，让用户确认后再动手

## 架构

SKILL.md（路由层 ~88 行）→ 按需加载 `workflows/step-NN-*.md`，每个步骤独立文件，节省上下文 token。

```
kernel-crash-analyzer-v2/
├── SKILL.md                   # 路由文件：核心原则 + 步骤路由表
├── workflows/                 # 按需加载的步骤文件
│   ├── step-00-scenario.md    # 交互式收集场景
│   ├── step-01-inputs.md      # 自动检测输入文件
│   ├── step-02-encoding.md    # 文件编码检测
│   ├── step-03-crash-type.md  # 签名匹配 + 自学习查询
│   ├── step-04-extract.md     # 提取关键信息
│   ├── step-05-disasm.md      # 反汇编分析 + 工具链缓存
│   ├── step-06-source.md      # 源码追踪 + 模式匹配
│   ├── step-07-symptom.md     # 区分症状/根因 + 质量自查
│   ├── step-08-fix.md         # 修复建议
│   ├── step-09-report.md      # 报告模板 + 案例存档
│   ├── step-10-learn.md       # 收录 + 自学习
│   └── feedback-loop.md       # 反馈闭环（双格式输出）
├── references/                # 参考资料
│   ├── crash_types.md         # crash 类型详细分析策略
│   ├── signature_table.md     # 签名匹配表
│   ├── platform_quirks.md     # 平台怪癖知识累积
│   └── tool_chain.md          # 工具链备忘
├── data/                      # 自学习知识库
│   ├── cases/                 # 分析案例存档
│   ├── signatures.json        # 累积 crash 签名库
│   ├── patterns.json          # 根因模式库
│   └── tool_cache.json        # 工具链缓存
├── evals/                     # 评估用例
│   └── evals.json
└── scripts/                   # 预留
```

## 自学习机制

skill 在每次分析中自动积累知识，越用越完善：

| 触点 | 学什么 | 方式 |
|------|--------|------|
| crash 类型匹配 | 新签名自动累积到 `data/signatures.json` | 自动查询，比硬编码表优先级更高 |
| 反汇编工具 | 工具链可用性缓存在 `data/tool_cache.json` | 同工作区下次跳过 `which` |
| 源码分析 | 从 `data/patterns.json` 查询历史根因模式 | 提供"相似 crash → 可能根因"线索 |
| 案例存档 | 每次分析自动保存到 `data/cases/` | JSON（机读索引）+ Markdown（人类阅读）双格式 |
| 反馈闭环 | 用户主动信号（"修好了/搞定了"）触发 | 成功→提升模式置信度，失败→降低/清除 |

## 工作流程

```
收集输入 → 检测文件编码 → 识别 crash 类型 → 提取关键信息 → 反汇编分析 → 源码分析 → 区分症状/根因 → 输出报告 → 自学习收录
```

### Crash 类型覆盖

| Crash 签名 | 类型 | 分析重点 |
|---|---|---|
| `Unable to handle kernel NULL pointer dereference` | NULL 指针解引用 | ERR_PTR 转换、错误路径返回 |
| `KASAN: use-after-free` | KASAN UAF | alloc/free 时间线、竞态条件 |
| `KASAN: slab-out-of-bounds` | KASAN OOB | 数组边界、结构体大小变化 |
| `SLUB: redzone` | SLUB 红区损坏 | 相邻对象越界写入 |
| `Kernel panic - not syncing` | 通用 panic | 先找 taint 来源，再追根因 |
| `BUG: scheduling while atomic` | 原子上下文调度 | mutex/sleep 调用路径 |
| mutex 交叉持有 | ABBA 死锁 | 锁依赖图、错误路径 unlock 缺失 |

### 反汇编工具链

按优先级自动检测并使用可用的 ARM64 反汇编工具：

| 优先级 | 工具 | 说明 |
|---|---|---|
| 1 | `aarch64-linux-gnu-objdump` | 交叉工具链，不一定安装 |
| 2 | `llvm-objdump` | LLVM 工具链，通常已安装 |
| 3 | `objdump` | 系统自带，需支持 ARM64 目标 |
| 4 | crash log 内嵌 `Code:` 行 | 高通 dmesg_TZ.txt 手动解码 |
| 5 | Python Capstone | 反汇编库 |
| 6 | ARM ARM 手册 | 最后手段 |

### 文件编码处理

Android/高通平台 crash log 常见编码：

| `file` 输出 | 含义 | 处理方式 |
|---|---|---|
| `UTF-16LE Unicode text, with CRLF` | Android event log | `iconv -f UTF-16LE -t UTF-8` 转换 |
| `ASCII text` / `UTF-8 text` | 标准文本 | 直接读取 |
| `data` | 未知编码/二进制 | 尝试 iconv 或 `head -c 200` 判断 |
| `ELF 64-bit LSB shared object, ARM aarch64` | vmlinux (PIE) | 注意符号表可能独立存放 |

## 使用方式

在 Claude Code 中直接描述问题，skill 会自动触发：

- "帮我分析一下这个 NULL 指针死机"
- "这个 ramdump 的 parser_out 和 symbols 都有了，看看什么原因"
- "开机卡在动画了，看一下 log"

### 输入

三个核心输入（缺一不可）：
- **Crash 现场**：parser_out/ 目录 或 crash log 文件（.txt/.log）
- **符号文件**：vmlinux 或 System.map（用于反汇编）
- **内核代码路径**：对应的内核源码树

如果当前工作目录已有这些文件，会自动识别；缺失的关键文件会通过交互式提问收集。

### 输出

一份中文结构化分析报告：
1. **崩溃概览** — crash 类型、进程、时间，直接原因 vs 根本原因
2. **证据链** — Fault address → objdump 指令 → 源码位置 → 数据流分析
3. **调用栈分析** — 逐层分析，标注每层角色
4. **根因结论** — 明确的根因描述，附带证据
5. **修复建议** — Unified diff 格式，init/probe 修复附执行顺序验证
6. **验证步骤** — 修复后如何验证效果

## 依赖

- `file` — 检测文件编码
- `iconv` — UTF-16LE → UTF-8 转换
- `objdump` / `llvm-objdump` / `aarch64-linux-gnu-objdump` — ARM64 反汇编（至少一个可用）
- 内核源码树 — 用于源码行映射和因果链分析
- 无需额外 Python/Node 包

## V2 版本说明

V2 基于 skill-creator-plus 的文件拆分 + 自学习架构模板重新生成。

### 与 V1 的关系

- V2 为默认版本（自动触发），V1 为备份（仅 `/kernel-crash-analyzer` 命令触发）
- V2 目录：`skills/kernel-crash-analyzer-v2/`
- V1 目录：`skills/kernel-crash-analyzer/`（保持不动）

### V2 相比 V1 的改进

- feedback-loop 新增双格式输出：JSON 写入 `data/cases/`（机读索引）+ Markdown 写入用户工作目录（人类阅读）
- feedback-loop 新增 diff preview 机制（更新模式库前展示变更预览）
- SKILL.md 路由层严格遵循 skill-creator-plus 模板结构

## 参考资料

- `references/crash_types.md` — 各类 crash 的详细分析策略
- `references/tool_chain.md` — 工具链备忘 + 安装命令
- `references/platform_quirks.md` — 平台怪癖知识
