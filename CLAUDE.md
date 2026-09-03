# han-skill

Han 个人 Skills 仓库。单一真源在 `skills/`，五平台（Claude Code / Codex / OpenCode / Cursor / Pi）分发。`skills/Deprecated/` 为源码保留、不参与分发。

## Conventions

- **单一真源**：只编辑 `skills/<name>/SKILL.md`（frontmatter 必含 `name` + `description`，name == 目录名，建议 kebab-case）。`.cursor/rules/*.mdc` 是 `scripts/gen_cursor_rules.py` 的生成物——改完 SKILL.md 立即重生成。
- **manifest 同步**：`.claude-plugin/plugin.json`、`marketplace.json`、`.codex-plugin/plugin.json`、`package.json` 的 name/version 保持一致（`validate.py` 校验）。改任一处后跑 validate。
- **frontmatter 路径**用相对路径或 `${CLAUDE_PLUGIN_ROOT}`。
- **Pi 双轨**：`package.json` 的 `pi.skills` 原生加载 + `install.sh install pi` 软链到 `~/.pi/agent/skills`，两者改 skill 后均无需重装。
- **marketplace 决策**：不在 marketplace 引用第三方子目录 plugin（repo 根 `.claude-plugin/` + 子目录 url+path 组合会让 claude 组件扫描扑空、`git-subdir` 需 git≥2.20）；第三方 UA 由 `install.sh` 从其官方源安装（`--no-ua` 跳过），codex/cursor 上 subagent 降级是 UA 官方限制。

## Commands

- 安装/状态/卸载：`./install.sh [install|status|uninstall] [agent|--all]`；清理失效软链 `./install.sh --cleanup`
- 校验：`python3 scripts/validate.py`
- 重生成 cursor rules：`python3 scripts/gen_cursor_rules.py`
- 本地加载测试：`claude --plugin-dir .`
