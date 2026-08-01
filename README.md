# Han Skills

Han 个人 Skills 仓库，用来集中维护可复用的本地 AI 工作流。同时作为**多平台 skill 分发骨架**的示例。

当前收录五类 skill：

- **han-skill-creator-plus** —— 能造「自学习（feedback loop）+ 按需文件拆分（SKILL.md 路由 + workflows/）」skill 的工厂，适合长期沉淀自己的 skill 集合。
- **han 生图体系** —— `han-imagen` 生图底座（OpenAI/Google 双 provider，纯 Python 标准库）+ 5 个业务 skill（信息图 / 手绘知识卡 / 拆解图 / 幻灯片 / SVG 图表）。业务 skill 均带防幻觉两阶段法 + 自学习，套底座出图；幻灯片/SVG 是纯标准库 CLI 工具。
- **han-llm-wiki** —— 个人知识库 Wiki 维护技能，9 个命令（init/ingest/query/lint/card/weekly/research/mode/think/save），BM25 检索 + 方法论模式（PARA/LYT/Zettelkasten）+ D2 配图。
- **han-kernel-crash-analyzer** —— Linux 内核崩溃分析（高通/Android），覆盖 NULL 指针 / KASAN UAF / SLUB 损坏 / ABBA 死锁 / panic / ramdump。反汇编优先 + Agent 对抗验证 + 案例自学习闭环。
- **实用工具** —— `han-d2-diagram`（D2 声明式图表，sketch 手绘风）+ `han-git-commit`（交互式 Git 提交信息生成，基于 `~/.git-template`）+ `han-flash-test`（UFS/eMMC 读写速率测试，规格对标 + 自学习闭环）+ `han-tech-doc-writer`（技术文档写作，D2 图表 + 信息图双轨视觉，7 步工作流 + 自学习反馈闭环）+ `han-util-tools`（内核工具总路由，按 场景→平台→模块→类型 四级引导）+ `han-quota-watch`（LLM 配额守卫，智谱 Coding Plan 每 5 小时用量判定 + 429 自动休眠/唤醒，Claude Code 专用）。

## 目录结构

```
.
├── .claude-plugin/
│   ├── plugin.json              # Claude Code plugin manifest
│   └── marketplace.json         # 声明本仓库为 Claude marketplace
├── .codex-plugin/
│   └── plugin.json              # Codex plugin config（含 interface）
├── .cursor/
│   └── rules/
│       └── *.mdc                  # 每个 skill 一个，由 scripts/gen_cursor_rules.py 生成
├── hooks/
│   ├── hooks.json               # Claude Code SessionStart 钩子
│   └── session-start.sh         # 打印可用 skill 速查
├── references/
│   └── README.md                # 跨 skill 共享参考
├── scripts/
│   ├── validate.py              # 五平台校验（含 package.json）
│   └── gen_cursor_rules.py      # SKILL.md → .cursor/rules/*.mdc 转换器
├── skills/
│   └── <name>/                  # 每个 skill 一个目录（han-skill-creator-plus + han-* 生图体系 + han-llm-wiki + han-kernel-crash-analyzer + han-d2-diagram + han-git-commit + han-flash-test + han-tech-doc-writer + han-util-tools），单一真源
├── mcp/                          # 附带的 MCP Server（非 skill）
│   └── windows-remote/           #   Windows 远程控制（adb/fastboot/UART）
├── install.sh                   # 软链接安装（五平台目标）
├── package.json                 # pi package manifest（pi install 原生分发）
├── README.md
└── CLAUDE.md
```

每个 skill 放在 `skills/<skill-name>/` 下，含必需的 `SKILL.md`。`skills/` 是**唯一真源**；`.cursor/rules/*.mdc` 是生成产物，禁止手改。

## 多平台 Plugin 配置

本仓库支持 **5 套** skill 分发机制，对应不同 Agent 客户端：

| 平台 | 机制 | 仓库里的产物 | 安装命令 |
| --- | --- | --- | --- |
| Claude Code | git marketplace | `.claude-plugin/` | `/plugin add-marketplace` → `/plugin install` |
| OpenAI Codex | git marketplace | `.codex-plugin/` | `codex plugin marketplace add` → `codex plugin add` |
| OpenCode | 目录扫描（无 marketplace） | 无 manifest，靠 `install.sh` | `./install.sh` |
| Cursor | 目录扫描（`~/.cursor/skills`） | 无 manifest，靠 `install.sh` 软链 | `./install.sh install cursor` |
| Pi | pi package（[Agent Skills 标准](https://agentskills.io)） | `package.json`（`pi.skills`） | `pi install git:...` 或 `./install.sh install pi` |

> `name`/`version`/`description` 在 `.claude-plugin/`、`.codex-plugin/` 与 `package.json` 之间保持同步，由 `scripts/validate.py` 校验（`package.json` 仅校验 `version`，`name` 因 npm 命名规则不同设为 `han-skills`）。

## 附载的第三方 Plugin：Understand-Anything

install.sh 会**同步安装**第三方 plugin [Understand-Anything](https://github.com/Egonex-AI/Understand-Anything)（UA）——AI 代码库理解工具，7 阶段多 agent 流水线把任意代码库扫成交互式知识图谱（文件/函数/类/依赖 + 导览 + 深度解释 + Web dashboard）。

> UA 的 plugin 内容在其仓库的 `understand-anything-plugin/` 子目录（repo 根另有 `.claude-plugin/` 作 marketplace 入口）。**han-skills 的 marketplace 不直接引用 UA**——`url`+`path` 会让 claude 把 repo 根当组件扫描根 → 组件 0；`git-subdir` 需 git≥2.20。改由 install.sh 各平台用 UA 官方源装。

**四平台完整度**（UA 完整体验绑死 Claude Code，跨平台是 UA 官方都解不开的硬约束）：

| 平台 | install.sh 装 UA 的方式 | 完整度 |
| --- | --- | --- |
| Claude Code | `claude plugin marketplace add Egonex-AI/Understand-Anything` + `claude plugin install understand-anything@understand-anything` | ✅ 完整（skills + 9 subagent） |
| OpenCode | UA 官方 `curl\|bash` + 额外软链 `agents/*.md` 到 `~/.config/opencode/agents/` | ✅ 可完整（补 subagent 注册） |
| Codex | UA 官方 `curl\|bash`（仅 skills） | ⚠️ 降级（UA 无 codex 清单，subagent 不注册） |
| Cursor | 跳过 + 提示 IDE clone | ⚠️ CLI 官方不支持 plugin，需 IDE |

**install.sh 默认同步装 UA**（`HAN_INSTALL_UA=1`），随 `./install.sh` 一并安装。跳过用 `--no-ua` 或 `HAN_INSTALL_UA=0`；单独操作用 `--ua-only`：

```
./install.sh                              # 装 han skills + MCP + UA（四平台）
./install.sh install claude --no-ua       # 只装 claude 的 han skills，不装 UA
./install.sh install opencode --ua-only   # 只给 opencode 装 UA
./install.sh uninstall claude             # 卸载（含 UA，对称）
```

> **运行时依赖**：Node 22 + pnpm 10 + Python 3 仅在首次 `/understand` 时才需要（构建 `packages/core`）；安装 plugin 本身不需要。
> **国内网络备用**：`UA_INSTALL_URL=https://gitee.com/rulei_mirror/Understand-Anything/raw/main/install.sh ./install.sh ...`。

## 安装

> 推送 GitHub 前，先把 `.claude-plugin/`、`.codex-plugin/` 里的 `ruleizhou` 替换成你的 GitHub 用户名。

### 方式一：Claude Code Plugin

```
/plugin add-marketplace ruleizhou/han-skill
/plugin install han@han-skills
```

更新：

```
/plugin update han@han-skills
```

### 方式二：Codex Plugin

```
codex plugin marketplace add ruleizhou/han-skill --ref main
codex plugin add han@han-skills
```

更新：

```
codex plugin marketplace upgrade han-skills
codex plugin remove han@han-skills
codex plugin add han@han-skills
```

说明：Codex 安装后会把 plugin 缓存到 `~/.codex/plugins/cache/`，运行时读缓存副本。修改本仓库 skill 后需推 GitHub、刷新 marketplace 并重装。

### 方式三：OpenCode（目录扫描）

OpenCode 原生兼容 Anthropic 的 `SKILL.md`，启动时扫描 `~/.config/opencode/skills/*/SKILL.md`、`~/.claude/skills/*/SKILL.md` 等（frontmatter 只认 `name/description/license/compatibility/metadata`，`name` 必须 == 目录名）。无需 marketplace，软链接进去即生效：

```
./install.sh
```

默认链到 `~/.config/opencode/skills`、`~/.claude/skills`、`~/.codex/skills`、`~/.cursor/skills` 四个目录。

### 方式四：Cursor（目录扫描）

与 Claude 相同：`install.sh` 软链接完整 skill 目录到 `~/.cursor/skills/`，Agent 按 `SKILL.md` 的 `description` 自动匹配（含 `scripts/`、`references/` 等子目录）。

```
./install.sh install cursor
```

### 方式五：pi（pi package / 软链）

[Pi](https://pi.dev)（`@earendil-works/pi-coding-agent`）实现 [Agent Skills 标准](https://agentskills.io)，启动时原生扫描 `~/.pi/agent/skills/*/SKILL.md`。本仓库的 `package.json` 声明了 `pi.skills`，两种装法：

**A. pi 原生 package（推荐）** —— 走 `pi install`，自动管理、可 `pi list` / `pi config` 启用禁用、`pi update --all` 更新：

```
pi install git:github.com/YOUR_GH_USER/han-skill        # 全局（git，发布后用）
pi install ./han-skills                                  # 本地路径（开发用）
pi -e ./han-skills                                       # 临时试用（不写 settings）
```

或团队共享：在项目 `.pi/settings.json` 写 `{"packages":["git:github.com/YOUR_GH_USER/han-skill"]}`，pi 启动自动装。

**B. install.sh 软链**（与其它平台一致，链到 `~/.pi/agent/skills`）：

```
./install.sh install pi
```

装好后 pi 会话内 `/skill:han-<name>` 直接调用；改 skill 后无需重装（软链/pi package 均读源目录）。

> `skills/.ignore` 已排除 `Deprecated/`（pi 递归发现 SKILL.md，靠此文件跳过弃用 skill；git 不读 `.ignore`，弃用源码仍保留）。

> MCP（windows-remote/wolai）暂不接入 pi（pi 有独立 MCP 机制，见 [settings 文档](https://pi.dev/docs/latest/settings)）；Understand-Anything 可自行 `pi install git:Egonex-AI/Understand-Anything`。

### 方式六：本地 install.sh（兼容模式）

适用于手动管理 skill 目录，或在 plugin 机制不可用时：

```
./install.sh --dry-run
./install.sh --list
./install.sh --cleanup
./install.sh --target ~/.claude/skills --target ~/.config/opencode/skills
HAN_SKILLS_TARGETS="$HOME/.claude/skills:$HOME/.config/opencode/skills" ./install.sh
```

## 本地开发

```
./install.sh                          # 软链安装到五平台默认目标
./install.sh --list                   # 查看各目标安装状态
python3 scripts/validate.py           # 校验：skills + 三套 manifest 同步 + package.json(pi) + cursor rules + 执行位
python3 scripts/gen_cursor_rules.py   # 从 skills/*/SKILL.md 重新生成 .cursor/rules/*.mdc
python3 scripts/gen_cursor_rules.py --check   # 只校验 cursor rules 是否过期
```

## 当前 Skill

| Skill | 定位 |
| --- | --- |
| `han-skill-creator-plus` | 创建带自学习（feedback loop）+ 按需拆分（SKILL.md 路由 + workflows/）的 skill；也用于改进调试已有 skill |
| `han-imagen` | 生图底座：双 provider（OpenAI gpt-image / Google gemini），作用域隔离 `.han-skills/.env`，纯 Python 标准库 CLI |
| `han-infographic` | 信息图：防幻觉两阶段法 + 24 布局×26 风格 + 自学习 |
| `han-hand-write-pic` | 手绘知识卡：暖色手账/sketchnote，normal/high 双密度 + 自学习 |
| `han-disassembly-diagram` | 拆解图：hybrid/exploded/cutaway 模式，材料标注 + 原理流程 + 自学习 |
| `han-slides` | 图片式幻灯片：每页出图 → 合并 PPTX/PDF（纯标准库） |
| `han-llm-wiki` | 个人知识库 Wiki 维护：9 命令（init/ingest/query/lint/card/weekly/research/mode/think/save），BM25 检索 + 方法论模式（PARA/LYT/Zettelkasten）+ D2 配图 |
| `han-kernel-crash-analyzer` | Linux 内核崩溃分析（高通/Android）：NULL 指针 / KASAN UAF / SLUB / ABBA 死锁 / panic / ramdump；反汇编优先 + 对抗验证 + 案例自学习 |
| `han-d2-diagram` | D2 声明式图表：流程图/架构图/ER/类图，sketch 手绘风，双格式输出（PNG+SVG）+ 自学习 |
| `han-git-commit` | 交互式 Git 提交信息生成器：基于 `~/.git-template`，交互收集 Module/Project/Bug-ID，AI 分析 diff 填充摘要/根因/方案 |
| `han-flash-test` | UFS/eMMC 读写速率测试：fio 直接读写裸块设备，顺序/随机多档取中位数，规格对标 + 自学习闭环 |
| `han-tech-doc-writer` | 技术文档写作：D2 图表 + 信息图（han-infographic）双轨视觉，7 步工作流（诊断→源→大纲→图表+信息图→写作→审核→输出），自学习反馈闭环 |
| `han-util-tools` | 内核工具总路由：/han-util-tools 命令触发，按 场景→平台→模块→类型 四级引导，覆盖 Debug/器件 Bringup/功能开发 |
| `han-quota-watch` | LLM 配额守卫：智谱 Coding Plan 每 5 小时用量判定，超阈值写检查点 + CronCreate(durable) 唤醒，实现 429 后会话自动恢复（Claude Code 专用，依赖 `~/.claude/CLAUDE.md` 第五节） |

## 已弃用 Skill

| Skill | 说明 | 替代 |
| --- | --- | --- |
| `han-svg` | 可编辑 SVG 图表（matrix/flowchart/timeline/architecture） | `han-d2-diagram`（D2 声明式图表，输出 SVG） |

源码保留于 `skills/Deprecated/han-svg/`，不参与安装与分发。

## 附带的 MCP Server

| MCP Server | 说明 |
| --- | --- |
| `windows-remote` | Windows 远程控制：通过 SSH 在远程 Windows PC 上执行 adb/fastboot/串口命令，12 个 MCP 工具 |

### 安装 MCP Server

```bash
# 查看可注册的 MCP 服务器（生成 claude mcp add 命令）
./scripts/setup-mcp.sh

# 仅列出发现的 MCP
./scripts/setup-mcp.sh --list

# 交互式自动注册（需要 claude CLI）
./scripts/setup-mcp.sh --register
```

`windows-remote` 还需要在 Windows 端配置 OpenSSH Server，详见 `mcp/windows-remote/README.md`。

## 本地校验

提交前跑校验脚本，检查 SKILL.md frontmatter、两套 plugin manifest 同步、cursor rules 同步、脚本执行位：

```
python3 scripts/validate.py
```

CI 在 push 到 `main` 与每个 pull request 上自动运行 `gen_cursor_rules.py --check` + `validate.py`（见 `.github/workflows/validate.yml`）。

## 致谢

分发骨架参考了 [luoli523/guige-skills](https://github.com/luoli523/guige-skills)，并扩展到 OpenCode / Cursor 两个新平台。
