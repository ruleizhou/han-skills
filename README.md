# Han Skills

Han 个人 Skills 仓库，用来集中维护可复用的本地 AI 工作流。同时作为**多平台 skill 分发骨架**的示例。

当前收录五类 skill：

- **skill-creator-plus** —— 能造「自学习（feedback loop）+ 按需文件拆分（SKILL.md 路由 + workflows/）」skill 的工厂，适合长期沉淀自己的 skill 集合。
- **han 生图体系** —— `han-imagen` 生图底座（OpenAI/Google 双 provider，纯 Python 标准库）+ 5 个业务 skill（信息图 / 手绘知识卡 / 拆解图 / 幻灯片 / SVG 图表）。业务 skill 均带防幻觉两阶段法 + 自学习，套底座出图；幻灯片/SVG 是纯标准库 CLI 工具。
- **llm-wiki** —— 个人知识库 Wiki 维护技能，9 个命令（init/ingest/query/lint/card/weekly/research/mode/think/save），BM25 检索 + 方法论模式（PARA/LYT/Zettelkasten）+ D2 配图。
- **kernel-crash-analyzer-v2** —— Linux 内核崩溃分析（高通/Android），覆盖 NULL 指针 / KASAN UAF / SLUB 损坏 / ABBA 死锁 / panic / ramdump。反汇编优先 + Agent 对抗验证 + 案例自学习闭环。
- **实用工具** —— `d2-diagram`（D2 声明式图表，sketch 手绘风）+ `git-commit`（交互式 Git 提交信息生成，基于 `~/.git-template`）+ `flash-test`（UFS/eMMC 读写速率测试，规格对标 + 自学习闭环）。

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
│   ├── validate.py              # 四平台校验
│   └── gen_cursor_rules.py      # SKILL.md → .cursor/rules/*.mdc 转换器
├── skills/
│   └── <name>/                  # 每个 skill 一个目录（skill-creator-plus + han-* 生图体系 + llm-wiki + kernel-crash-analyzer-v2 + d2-diagram + git-commit + flash-test），单一真源
├── mcp/                          # 附带的 MCP Server（非 skill）
│   └── windows-remote/           #   Windows 远程控制（adb/fastboot/UART）
├── install.sh                   # 软链接安装（三目标）
├── README.md
└── CLAUDE.md
```

每个 skill 放在 `skills/<skill-name>/` 下，含必需的 `SKILL.md`。`skills/` 是**唯一真源**；`.cursor/rules/*.mdc` 是生成产物，禁止手改。

## 多平台 Plugin 配置

本仓库支持 **4 套** skill 分发机制，对应不同 Agent 客户端：

| 平台 | 机制 | 仓库里的产物 | 安装命令 |
| --- | --- | --- | --- |
| Claude Code | git marketplace | `.claude-plugin/` | `/plugin add-marketplace` → `/plugin install` |
| OpenAI Codex | git marketplace | `.codex-plugin/` | `codex plugin marketplace add` → `codex plugin add` |
| OpenCode | 目录扫描（无 marketplace） | 无 manifest，靠 `install.sh` | `./install.sh` |
| Cursor | `.cursor/rules/*.mdc` | `.cursor/rules/` | 仓库已内置，用 `@<name>` 引用 |

> `name`/`version`/`description` 在 `.claude-plugin/` 与 `.codex-plugin/` 之间保持同步，由 `scripts/validate.py` 校验。

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

默认链到 `~/.config/opencode/skills`、`~/.claude/skills`、`~/.codex/skills` 三个目录。

### 方式四：Cursor（rules）

仓库已内置 `.cursor/rules/skill-creator-plus.mdc`（`alwaysApply: false`），在对话里用 `@skill-creator-plus` 引用即可按需加载。改了 SKILL.md 后重新生成：

```
python3 scripts/gen_cursor_rules.py
```

### 方式五：本地 install.sh（兼容模式）

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
./install.sh                          # 软链安装到三个默认目标
./install.sh --list                   # 查看各目标安装状态
python3 scripts/validate.py           # 校验：skills + manifest 同步 + cursor rules 同步 + 执行位
python3 scripts/gen_cursor_rules.py   # 从 skills/*/SKILL.md 重新生成 .cursor/rules/*.mdc
python3 scripts/gen_cursor_rules.py --check   # 只校验 cursor rules 是否过期
```

## 当前 Skill

| Skill | 定位 |
| --- | --- |
| `skill-creator-plus` | 创建带自学习（feedback loop）+ 按需拆分（SKILL.md 路由 + workflows/）的 skill；也用于改进调试已有 skill |
| `han-imagen` | 生图底座：双 provider（OpenAI gpt-image / Google gemini），作用域隔离 `.han-skills/.env`，纯 Python 标准库 CLI |
| `han-infographic` | 信息图：防幻觉两阶段法 + 24 布局×26 风格 + 自学习 |
| `han-hand-write-pic` | 手绘知识卡：暖色手账/sketchnote，normal/high 双密度 + 自学习 |
| `han-disassembly-diagram` | 拆解图：hybrid/exploded/cutaway 模式，材料标注 + 原理流程 + 自学习 |
| `han-slides` | 图片式幻灯片：每页出图 → 合并 PPTX/PDF（纯标准库） |
| `han-svg` | 可编辑 SVG 图表：matrix/flowchart/timeline/architecture，确定性 Python 渲染（非生图模型） |
| `llm-wiki` | 个人知识库 Wiki 维护：9 命令（init/ingest/query/lint/card/weekly/research/mode/think/save），BM25 检索 + 方法论模式（PARA/LYT/Zettelkasten）+ D2 配图 |
| `kernel-crash-analyzer-v2` | Linux 内核崩溃分析（高通/Android）：NULL 指针 / KASAN UAF / SLUB / ABBA 死锁 / panic / ramdump；反汇编优先 + 对抗验证 + 案例自学习 |
| `d2-diagram` | D2 声明式图表：流程图/架构图/ER/类图，sketch 手绘风，双格式输出（PNG+SVG）+ 自学习 |
| `git-commit` | 交互式 Git 提交信息生成器：基于 `~/.git-template`，交互收集 Module/Project/Bug-ID，AI 分析 diff 填充摘要/根因/方案 |
| `flash-test` | UFS/eMMC 读写速率测试：fio 直接读写裸块设备，顺序/随机多档取中位数，规格对标 + 自学习闭环 |

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
