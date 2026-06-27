# Han Skills

Han 个人 Skills 仓库，用来集中维护可复用的本地 AI 工作流。同时作为**多平台 skill 分发骨架**的示例。

首个 skill 是 **skill-creator-plus** —— 一个能造「自学习（feedback loop）+ 按需文件拆分（SKILL.md 路由 + workflows/）」skill 的工厂，适合长期沉淀自己的 skill 集合。

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
│       └── skill-creator-plus.mdc   # 由 scripts/gen_cursor_rules.py 生成
├── hooks/
│   ├── hooks.json               # Claude Code SessionStart 钩子
│   └── session-start.sh         # 打印可用 skill 速查
├── references/
│   └── README.md                # 跨 skill 共享参考
├── scripts/
│   ├── validate.py              # 四平台校验
│   └── gen_cursor_rules.py      # SKILL.md → .cursor/rules/*.mdc 转换器
├── skills/
│   └── skill-creator-plus/      # 单一真源，所有平台共用
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

## 本地校验

提交前跑校验脚本，检查 SKILL.md frontmatter、两套 plugin manifest 同步、cursor rules 同步、脚本执行位：

```
python3 scripts/validate.py
```

CI 在 push 到 `main` 与每个 pull request 上自动运行 `gen_cursor_rules.py --check` + `validate.py`（见 `.github/workflows/validate.yml`）。

## 致谢

分发骨架参考了 [luoli523/guige-skills](https://github.com/luoli523/guige-skills)，并扩展到 OpenCode / Cursor 两个新平台。
