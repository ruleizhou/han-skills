# han-skill

Han 个人 Skills 仓库。单一真源在 `skills/`，四平台（Claude Code / Codex / OpenCode / Cursor）分发骨架。

## Project Structure

- `skills/<name>/SKILL.md` —— 每个 skill 的入口，frontmatter 必含 `name` + `description`。
- `.claude-plugin/` —— Claude Code marketplace（plugin.json + marketplace.json）。
- `.codex-plugin/` —— OpenAI Codex plugin（plugin.json，含 interface）。
- `.cursor/rules/*.mdc` —— Cursor Project Rules，**生成产物**，由 `scripts/gen_cursor_rules.py` 从 `skills/*/SKILL.md` 生成。
- `hooks/` —— Claude Code SessionStart 钩子，开会话时打印 skill 速查。
- `scripts/validate.py` —— 四平台一致性校验。
- `scripts/gen_cursor_rules.py` —— SKILL.md → .mdc 转换器（支持 `--check`）。
- `mcp/<name>/` —— 附带的 MCP Server，不为 skill（无 SKILL.md），由 `install.sh` 统一管理注册。
- `mcp/<name>/mcp.json` —— MCP 元数据（name, description, env vars）。
- `install.sh` —— Skills + MCP 统一安装入口（install / uninstall / status / update）。
- `install.conf` —— 安装配置（四平台 Agent 表 + MCP 环境变量）。

## Conventions

- **单一真源**：`skills/` 是唯一编辑入口。`.cursor/rules/*.mdc` 是派生物，**禁止手改**。
- **两套 manifest 同步**：`.claude-plugin/plugin.json` 与 `.codex-plugin/plugin.json` 的 `name`/`version` 必须一致；`marketplace.json` 的 `metadata.version` 与 `plugins[0].name` 也要同步。当前 name=`han`，version=`0.1.0`。
- **OpenCode / Cursor 无 manifest**：OpenCode 靠目录扫描（`~/.config/opencode/skills`、`~/.claude/skills`），Cursor 靠 `~/.cursor/skills` 软链接（与 Claude 相同）。
- skill 名建议 kebab-case；`SKILL.md` 的 `name` 字段必须 == 所在目录名。
- frontmatter 用相对路径或 `${CLAUDE_PLUGIN_ROOT}`，禁止硬编码绝对路径。
- skill 间通过明确 CLI 接口协作，不读对方私有目录。

## Boundaries

- **Always**：改 `skills/<name>/SKILL.md` 后，立即 `python3 scripts/gen_cursor_rules.py` 重生成 `.mdc`。
- **Always**：改任一 manifest 的 `name`/`version` 后，同步另一套，并跑 `python3 scripts/validate.py`。
- **Always**：新增 skill 后，按需更新三套 manifest 的 description/keywords。
- **Never**：手编 `.cursor/rules/*.mdc`（它是生成物，会被下次生成覆盖、CI 会判过期）。
- **Never**：硬编码本机用户目录或绝对路径（MCP 注册路径由 `install.sh` 运行时动态解析）。
- MCP Server 不参与 `validate.py` / `gen_cursor_rules.py` 校验（它们只处理 `skills/`）。

## Commands

- 安装：`./install.sh` 或 `./install.sh install <agent|--all>`（默认四平台 claude / codex / opencode / cursor）
- 查看状态：`./install.sh status`
- 卸载：`./install.sh uninstall <agent|--all>`
- 清理失效软链：`./install.sh --cleanup`
- 校验：`python3 scripts/validate.py`
- 重生成 cursor rules：`python3 scripts/gen_cursor_rules.py`
- 本地加载测试：`claude --plugin-dir .`
- 公开分发：GitHub `YOUR_GH_USER/han-skill`（推送前替换所有 `YOUR_GH_USER` 占位符）
