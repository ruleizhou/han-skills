# han-skill

Han 个人 Skills 仓库。单一真源在 `skills/`，五平台（Claude Code / Codex / OpenCode / Cursor / Pi）分发骨架。

## Project Structure

- `skills/<name>/SKILL.md` —— 每个 skill 的入口，frontmatter 必含 `name` + `description`。
- `skills/Deprecated/<name>/` —— 已弃用 skill，**不参与**安装、校验与 cursor rules 生成。
- `skills/.ignore` —— pi 平台的 Deprecated 排除规则（pi 递归发现 SKILL.md，靠此文件跳过 `Deprecated/`；git 不读 `.ignore`，源码仍保留）。由 `validate.py` 校验存在。
- `.claude-plugin/` —— Claude Code marketplace（plugin.json + marketplace.json）。
- `.codex-plugin/` —— OpenAI Codex plugin（plugin.json，含 interface）。
- `.cursor/rules/*.mdc` —— Cursor Project Rules，**生成产物**，由 `scripts/gen_cursor_rules.py` 从 `skills/*/SKILL.md` 生成。
- `hooks/` —— Claude Code SessionStart 钩子，开会话时打印 skill 速查。
- `scripts/validate.py` —— 四平台一致性校验。
- `scripts/gen_cursor_rules.py` —— SKILL.md → .mdc 转换器（支持 `--check`）。
- `mcp/<name>/` —— 附带的 MCP Server，不为 skill（无 SKILL.md），由 `install.sh` 统一管理注册。
- `mcp/<name>/mcp.json` —— MCP 元数据（name, description, env vars）。
- `install.sh` —— Skills + MCP 统一安装入口（install / uninstall / status / update）。
- `install.conf` —— 安装配置（五平台 Agent 表 + MCP 环境变量）。
- `package.json` —— **pi package manifest**（`pi.skills` 指向 `./skills` + `pi-package` keyword），让 `pi install` / `pi -e ./` 原生分发。

## Conventions

- **单一真源**：`skills/` 是唯一编辑入口。`.cursor/rules/*.mdc` 是派生物，**禁止手改**。
- **两套 manifest 同步**：`.claude-plugin/plugin.json` 与 `.codex-plugin/plugin.json` 的 `name`/`version` 必须一致；`marketplace.json` 的 `metadata.version` 与 `plugins[0].name` 也要同步；`package.json` 的 `version` 与上述同步（`name` 因 npm 命名规则设为 `han-skills`，不与 plugin name=`han` 同步）。当前 version=`0.1.0`。
- **OpenCode / Cursor 无 manifest**：OpenCode 靠目录扫描（`~/.config/opencode/skills`、`~/.claude/skills`），Cursor 靠 `~/.cursor/skills` 软链接（与 Claude 相同）。
- **Pi 双轨**：① `package.json` 的 `pi.skills` 让 `pi install git:...`/`pi install ./`/`pi -e ./` 原生加载（pi 实现 Agent Skills 标准，启动扫描 `~/.pi/agent/skills/*/SKILL.md`）；② `install.sh install pi` 软链到 `~/.pi/agent/skills`（与其它平台对称）。两者改 skill 后均无需重装（读源目录）。MCP 暂不接入 pi（pi 有独立 MCP 机制）。
- skill 名建议 kebab-case；`SKILL.md` 的 `name` 字段必须 == 所在目录名。
- frontmatter 用相对路径或 `${CLAUDE_PLUGIN_ROOT}`，禁止硬编码绝对路径。
- skill 间通过明确 CLI 接口协作，不读对方私有目录。
- **marketplace.json 可承载多个 plugin**：`plugins[0]` = `han`（自有，受 validate.py name/version 同步约束）；`plugins[1+]` 理论上可放第三方「纯引用」条目，但**子目录 plugin 有坑**——`url`+`path` 在「repo 根有 `.claude-plugin/` + plugin 在子目录」时，claude 会把 repo 根当组件扫描根 → 组件 0（实测 UA 即如此）；`git-subdir` 需 git≥2.20（否则 `invalid filter-spec 'tree:0'`）。所以 han-skills **不**在 marketplace 引用第三方 plugin。
- **install.sh 同步安装第三方 plugin（UA）**：install.sh 默认同步装 UA（`HAN_INSTALL_UA=1`，`--no-ua` 跳过），各平台用 **UA 官方源**——claude→`claude plugin marketplace add Egonex-AI/Understand-Anything` + `install understand-anything@understand-anything`（**不**用 han-skills marketplace 引用，因 UA repo 结构会让 claude 组件扫描扑空）；codex/opencode→UA 官方 `curl|bash`（opencode 额外软链 agents 补 subagent）；cursor→CLI 不支持故提示 IDE。UA 在 codex/cursor 上降级（subagent 不注册）是 UA 官方平台限制。

## Boundaries

- **Always**：改 `skills/<name>/SKILL.md` 后，立即 `python3 scripts/gen_cursor_rules.py` 重生成 `.mdc`。
- **Always**：新增/移动 skill 到 `skills/Deprecated/` 后，确认 `skills/.ignore` 仍覆盖（pi 递归发现 SKILL.md，`validate.py` 会校验 `.ignore` 或 package.json glob negation 任一存在）。
- **Always**：改任一 manifest 的 `name`/`version` 后，同步其它套（含 `package.json`），并跑 `python3 scripts/validate.py`。
- **Always**：新增 skill 后，按需更新三套 manifest 的 description/keywords。
- **Never**：手编 `.cursor/rules/*.mdc`（它是生成物，会被下次生成覆盖、CI 会判过期）。
- **Never**：硬编码本机用户目录或绝对路径（MCP 注册路径由 `install.sh` 运行时动态解析）。
- MCP Server 不参与 `validate.py` / `gen_cursor_rules.py` 校验（它们只处理 `skills/`）。

## Commands

- 安装：`./install.sh` 或 `./install.sh install <agent|--all>`（默认五平台 claude / codex / opencode / cursor / pi）；pi 另可 `pi install ./` 或 `pi install git:YOUR_GH_USER/han-skill` 原生安装
- 查看状态：`./install.sh status`
- 卸载：`./install.sh uninstall <agent|--all>`
- 清理失效软链：`./install.sh --cleanup`
- 校验：`python3 scripts/validate.py`
- 重生成 cursor rules：`python3 scripts/gen_cursor_rules.py`
- 本地加载测试：`claude --plugin-dir .`
- 公开分发：GitHub `YOUR_GH_USER/han-skill`（推送前替换所有 `YOUR_GH_USER` 占位符）
