#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# install.sh — Han skills + MCP 统一安装入口
# 用法: ./install.sh <command> [agent|--all] [options]
# 命令: install | uninstall | update | status | help
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_ROOT="$SCRIPT_DIR/skills"
MCP_ROOT="$SCRIPT_DIR/mcp"
CONF_FILE="$SCRIPT_DIR/install.conf"
GEN_MDC="$SCRIPT_DIR/scripts/gen_cursor_rules.py"
PYTHON_DETECT="$SCRIPT_DIR/scripts/_python_detect.sh"

# ── 颜色 ──
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; BOLD=''; NC=''
fi

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*" >&2; }
info() { echo -e "${BLUE}[i]${NC} $*"; }

# ── 加载配置 ──
if [[ ! -f "$CONF_FILE" ]]; then
    err "配置文件不存在: $CONF_FILE"
    exit 1
fi
# shellcheck disable=SC1090
source "$CONF_FILE"

ALL_AGENTS="claude codex opencode cursor"   # 代码常量（不放 conf）
DRY_RUN=false

# MCP 注册才需要 Python 检测；此处仅定义函数，按需调用
if [[ -f "$PYTHON_DETECT" ]]; then
    # shellcheck disable=SC1090
    source "$PYTHON_DETECT"
fi

# ============================================================
# 工具函数
# ============================================================

agent_var() {
    local agent="$1" field="$2"
    local var_name="AGENT_$(echo "$agent" | tr '[:lower:]' '[:upper:]')_${field}"
    if [[ -n "${!var_name+x}" ]]; then
        echo "${!var_name}"
    fi
}

expand_path() {
    local path="$1"
    case "$path" in
        "~") echo "$HOME" ;;
        "~/"*) echo "$HOME/${path#~/}" ;;
        *) echo "$path" ;;
    esac
}

# ============================================================
# 自动发现（单一真源：扫描 ./skills 与 ./mcp）
# ============================================================

has_valid_frontmatter() {
    local skill_dir="$1"
    local skill_md="$skill_dir/SKILL.md"
    local first_line
    [[ -f "$skill_md" ]] || return 1
    IFS= read -r first_line < "$skill_md" || return 1
    [[ "$first_line" == "---" ]] || return 1
    awk 'NR > 1 && $0 == "---" { found = 1; exit } END { exit(found ? 0 : 1) }' "$skill_md"
}

SKILL_NAMES=()
SKILL_SOURCES=()
discover_skills() {
    local skill_dir
    if [[ ! -d "$SKILLS_ROOT" ]]; then
        err "skills 目录不存在: $SKILLS_ROOT"
        exit 1
    fi
    shopt -s nullglob
    SKILL_NAMES=()
    SKILL_SOURCES=()
    for skill_dir in "$SKILLS_ROOT"/*; do
        [[ -d "$skill_dir" ]] || continue
        if ! has_valid_frontmatter "$skill_dir"; then
            warn "跳过 $(basename "$skill_dir")（SKILL.md frontmatter 无效）"
            continue
        fi
        SKILL_NAMES+=("$(basename "$skill_dir")")
        SKILL_SOURCES+=("$skill_dir")
    done
    shopt -u nullglob
    if [[ ${#SKILL_NAMES[@]} -eq 0 ]]; then
        err "未发现有效 skill: $SKILLS_ROOT"
        exit 1
    fi
}

MCP_NAMES=()
MCP_DIRS=()
discover_mcps() {
    local mcp_dir name meta
    MCP_NAMES=()
    MCP_DIRS=()
    [[ -d "$MCP_ROOT" ]] || return 0
    shopt -s nullglob
    for mcp_dir in "$MCP_ROOT"/*; do
        [[ -d "$mcp_dir" ]] || continue
        meta="$mcp_dir/mcp.json"
        if [[ -f "$meta" ]]; then
            name="$(python3 -c "import json; print(json.load(open('$meta')).get('name',''))" 2>/dev/null || echo "$(basename "$mcp_dir")")"
        else
            name="$(basename "$mcp_dir")"
        fi
        MCP_NAMES+=("$name")
        MCP_DIRS+=("$mcp_dir")
    done
    shopt -u nullglob
}

# ============================================================
# MCP JSON 构建/合并（用环境变量给 Python 传参，避免路径注入）
# ============================================================

# 输出 env 对象的 JSON（仅含已配置值的 key），无则输出空
build_env_json() {
    local mcp_dir="$1"
    local meta="$mcp_dir/mcp.json"
    [[ -f "$meta" ]] || return 0
    # conf 的 WINDOWS_REMOTE_SSH_ALIAS 映射成实际 env key SSH_HOST_ALIAS
    SSH_HOST_ALIAS="${WINDOWS_REMOTE_SSH_ALIAS:-}" MCP_META="$meta" python3 -c "
import json, os, sys
try:
    keys = list(json.load(open(os.environ['MCP_META'])).get('env', {}))
except Exception:
    sys.exit(0)
out = {}
for k in keys:
    v = os.environ.get(k)
    if v:
        out[k] = v
if out:
    print(json.dumps(out, ensure_ascii=False))
"
}

# 输出完整 mcp server JSON 片段（需先 detect_python 设好 $PYTHON_BIN）
build_mcp_json() {
    local mcp_name="$1"
    local mcp_dir="" server_py="" found=false i
    for i in "${!MCP_NAMES[@]}"; do
        if [[ "${MCP_NAMES[$i]}" == "$mcp_name" ]]; then
            mcp_dir="${MCP_DIRS[$i]}"
            found=true
            break
        fi
    done
    [[ "$found" == true ]] || return 1
    server_py="$mcp_dir/server.py"
    local env_json json
    env_json="$(build_env_json "$mcp_dir")"
    json="{\"command\":\"${PYTHON_BIN}\",\"args\":[\"${server_py}\"]"
    [[ -n "$env_json" ]] && json+=",\"env\":${env_json}"
    json+="}"
    echo "$json"
}

# 0 = mcp_name 已在 mcp_file 的 mcpServers 中
mcp_in_json() {
    local mcp_file="$1" mcp_name="$2"
    [[ -f "$mcp_file" ]] || return 1
    MCP_FILE="$mcp_file" MCP_NAME="$mcp_name" python3 -c "
import json, os, sys
try:
    data = json.load(open(os.environ['MCP_FILE']))
except Exception:
    sys.exit(1)
sys.exit(0 if os.environ['MCP_NAME'] in data.get('mcpServers', {}) else 1)
"
}

merge_mcp_json() {
    local mcp_file="$1" mcp_name="$2" mcp_json="$3"
    MCP_FILE="$mcp_file" MCP_NAME="$mcp_name" MCP_JSON="$mcp_json" python3 -c "
import json, os
f, name, j = os.environ['MCP_FILE'], os.environ['MCP_NAME'], os.environ['MCP_JSON']
try:
    with open(f) as fh:
        data = json.load(fh)
except (json.JSONDecodeError, FileNotFoundError):
    data = {}
data.setdefault('mcpServers', {})[name] = json.loads(j)
with open(f, 'w') as fh:
    json.dump(data, fh, indent=2, ensure_ascii=False)
    fh.write('\n')
"
}

remove_mcp_json() {
    local mcp_file="$1" mcp_name="$2"
    [[ -f "$mcp_file" ]] || return 0
    MCP_FILE="$mcp_file" MCP_NAME="$mcp_name" python3 -c "
import json, os
f, name = os.environ['MCP_FILE'], os.environ['MCP_NAME']
with open(f) as fh:
    data = json.load(fh)
if name in data.get('mcpServers', {}):
    del data['mcpServers'][name]
    with open(f, 'w') as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)
        fh.write('\n')
"
}

# ============================================================
# Skills 安装/卸载
# ============================================================

# install_skills_to_dir <label> <dir> <format>
install_skills_to_dir() {
    local label="$1" dir="$2" format="$3"

    if [[ "$format" == "mdc" ]]; then
        if [[ ! -f "$GEN_MDC" ]]; then
            warn "$label: gen_cursor_rules.py 不存在，跳过 mdc"
            return 0
        fi
        if $DRY_RUN; then
            echo "  [dry] python3 $(basename "$GEN_MDC") --output $dir"
        else
            mkdir -p "$dir"
            python3 "$GEN_MDC" --output "$dir" >/dev/null
            log "$label: 生成 .mdc → $dir"
        fi
        return 0
    fi

    $DRY_RUN || mkdir -p "$dir"
    local i name source link created=0 updated=0 skipped=0
    for i in "${!SKILL_NAMES[@]}"; do
        name="${SKILL_NAMES[$i]}"
        source="${SKILL_SOURCES[$i]}"
        link="$dir/$name"

        if [[ "$format" == "copy" ]]; then
            if [[ -d "$link" ]]; then
                skipped=$((skipped+1)); continue
            fi
            $DRY_RUN || cp -r "$source" "$link"
            created=$((created+1))
            continue
        fi

        # symlink
        if [[ -e "$link" && ! -L "$link" ]]; then
            warn "$label: 跳过 $name（目标非软链: $link）"
            skipped=$((skipped+1)); continue
        fi
        if [[ -L "$link" ]]; then
            local cur; cur="$(readlink "$link")"
            if [[ "$cur" == "$source" ]]; then
                skipped=$((skipped+1)); continue
            fi
            $DRY_RUN || { rm "$link"; ln -s "$source" "$link"; }
            updated=$((updated+1))
        else
            $DRY_RUN || ln -s "$source" "$link"
            created=$((created+1))
        fi
    done
    info "$label: skills +$created ~$updated =$skipped → $dir"
}

uninstall_skills_to_dir() {
    local label="$1" dir="$2" format="$3"
    local i name link removed=0

    if [[ "$format" == "mdc" ]]; then
        for i in "${!SKILL_NAMES[@]}"; do
            link="$dir/${SKILL_NAMES[$i]}.mdc"
            if [[ -f "$link" ]]; then
                $DRY_RUN || rm -f "$link"
                removed=$((removed+1))
            fi
        done
        [[ $removed -gt 0 ]] && log "$label: 移除 $removed 个 .mdc"
        return 0
    fi

    for i in "${!SKILL_NAMES[@]}"; do
        name="${SKILL_NAMES[$i]}"
        link="$dir/$name"
        if [[ "$format" == "copy" ]]; then
            if [[ -d "$link" ]]; then
                $DRY_RUN || rm -rf "$link"
                removed=$((removed+1))
            fi
        elif [[ -L "$link" ]]; then
            $DRY_RUN || rm "$link"
            removed=$((removed+1))
        fi
    done
    [[ $removed -gt 0 ]] && log "$label: 移除 $removed 个 skill"
}

install_skills() {
    local agent="$1"
    local format skills_dir
    format="$(agent_var "$agent" SKILLS_FORMAT)"
    skills_dir="$(agent_var "$agent" SKILLS_DIR)"
    if [[ -z "$format" || -z "$skills_dir" ]]; then
        info "$agent: 不支持 Skills，跳过"
        return 0
    fi
    install_skills_to_dir "$agent" "$(expand_path "$skills_dir")" "$format"
}

uninstall_skills() {
    local agent="$1"
    local format skills_dir
    format="$(agent_var "$agent" SKILLS_FORMAT)"
    skills_dir="$(agent_var "$agent" SKILLS_DIR)"
    if [[ -z "$format" || -z "$skills_dir" ]]; then
        return 0
    fi
    uninstall_skills_to_dir "$agent" "$(expand_path "$skills_dir")" "$format"
}

# ============================================================
# MCP 注册/卸载
# ============================================================

install_mcps() {
    local agent="$1"
    local mcp_type
    mcp_type="$(agent_var "$agent" MCP_TYPE)"
    if [[ -z "$mcp_type" ]]; then
        return 0
    fi
    if [[ ${#MCP_NAMES[@]} -eq 0 ]]; then
        info "$agent: 无 MCP 源（mcp/ 为空），跳过"
        return 0
    fi

    # 需要 Python（注册命令要用）
    if ! detect_python 2>/dev/null; then
        warn "$agent: 未检测到 Python，跳过 MCP 注册"
        return 0
    fi

    local i
    for i in "${!MCP_NAMES[@]}"; do
        local mcp_name="${MCP_NAMES[$i]}"
        local mcp_dir="${MCP_DIRS[$i]}"
        local server_py="$mcp_dir/server.py"
        if [[ ! -f "$server_py" ]]; then
            warn "$agent: $mcp_name 缺 server.py，跳过"
            continue
        fi

        if [[ "$mcp_type" == "command" ]]; then
            # Claude Code: claude mcp add
            if ! command -v claude &>/dev/null; then
                warn "$agent: claude CLI 未找到，跳过 MCP"
                continue
            fi
            if claude mcp list 2>/dev/null | grep -q "$mcp_name"; then
                info "$agent: MCP $mcp_name 已注册"
                continue
            fi
            local env_json env_flags=""
            env_json="$(build_env_json "$mcp_dir")"
            if [[ -n "$env_json" ]]; then
                env_flags="$(ENVJ="$env_json" python3 -c "
import json, os
d = json.loads(os.environ['ENVJ'])
print(' '.join(f'-e{k}={v}' for k, v in d.items()))
")"
            fi
            if $DRY_RUN; then
                echo "  [dry] claude mcp add $mcp_name -s user $env_flags -- $PYTHON_BIN $server_py"
            else
                # shellcheck disable=SC2086
                if claude mcp add "$mcp_name" -s user $env_flags -- "$PYTHON_BIN" "$server_py"; then
                    log "$agent: 注册 MCP $mcp_name"
                else
                    warn "$agent: 注册 $mcp_name 失败"
                fi
            fi

        elif [[ "$mcp_type" == "json" ]]; then
            local mcp_file
            mcp_file="$(agent_var "$agent" MCP_FILE)"
            if [[ -z "$mcp_file" ]]; then
                warn "$agent: 未定义 MCP_FILE"
                continue
            fi
            mcp_file="$(expand_path "$mcp_file")"
            if mcp_in_json "$mcp_file" "$mcp_name"; then
                info "$agent: MCP $mcp_name 已在 $(basename "$mcp_file")"
                continue
            fi
            local mcp_json
            mcp_json="$(build_mcp_json "$mcp_name")"
            if $DRY_RUN; then
                echo "  [dry] 注册 $mcp_name → $mcp_file"
            else
                mkdir -p "$(dirname "$mcp_file")"
                merge_mcp_json "$mcp_file" "$mcp_name" "$mcp_json"
                log "$agent: 注册 MCP $mcp_name → $mcp_file"
            fi
        fi
    done
}

uninstall_mcps() {
    local agent="$1"
    local mcp_type
    mcp_type="$(agent_var "$agent" MCP_TYPE)"
    [[ -z "$mcp_type" || ${#MCP_NAMES[@]} -eq 0 ]] && return 0

    local i
    for i in "${!MCP_NAMES[@]}"; do
        local mcp_name="${MCP_NAMES[$i]}"
        if [[ "$mcp_type" == "command" ]]; then
            if command -v claude &>/dev/null && claude mcp list 2>/dev/null | grep -q "$mcp_name"; then
                if $DRY_RUN; then
                    echo "  [dry] claude mcp remove $mcp_name -s user"
                else
                    claude mcp remove "$mcp_name" -s user 2>/dev/null || true
                fi
                log "$agent: 移除 MCP $mcp_name"
            fi
        elif [[ "$mcp_type" == "json" ]]; then
            local mcp_file
            mcp_file="$(agent_var "$agent" MCP_FILE)"
            mcp_file="$(expand_path "$mcp_file")"
            if [[ -f "$mcp_file" ]] && mcp_in_json "$mcp_file" "$mcp_name"; then
                if $DRY_RUN; then
                    echo "  [dry] 从 $(basename "$mcp_file") 移除 $mcp_name"
                else
                    remove_mcp_json "$mcp_file" "$mcp_name"
                fi
                log "$agent: 移除 MCP $mcp_name"
            fi
        fi
    done
}

# ============================================================
# 失效软链清理
# ============================================================

cleanup_stale_links() {
    echo -e "${BLUE}=== 清理失效软链 ===${NC}"
    local agent skills_dir format link current removed=0
    for agent in $ALL_AGENTS; do
        format="$(agent_var "$agent" SKILLS_FORMAT)"
        skills_dir="$(agent_var "$agent" SKILLS_DIR)"
        [[ "$format" == "symlink" && -n "$skills_dir" ]] || continue
        skills_dir="$(expand_path "$skills_dir")"
        [[ -d "$skills_dir" ]] || continue

        shopt -s nullglob
        for link in "$skills_dir"/*; do
            [[ -L "$link" ]] || continue
            current="$(readlink "$link")"
            case "$current" in
                "$SKILLS_ROOT"/*)
                    if [[ ! -d "$current" || ! -f "$current/SKILL.md" ]]; then
                        echo -e "  ${RED}rm stale:${NC} $(basename "$link") -> $current"
                        $DRY_RUN || rm "$link"
                        removed=$((removed+1))
                    fi
                    ;;
            esac
        done
        shopt -u nullglob
    done
    if [[ $removed -eq 0 ]]; then
        echo "  无失效软链"
    else
        echo "  清理 $removed 个"
    fi
}

# ============================================================
# 状态看板
# ============================================================

show_status() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║       Han Skills + MCP 安装状态              ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${BOLD}【源】${NC}"
    log "Skills: $SKILLS_ROOT (${#SKILL_NAMES[@]} 个)"
    if [[ -d "$MCP_ROOT" ]]; then
        log "MCPs:   $MCP_ROOT (${#MCP_NAMES[@]} 个)"
    else
        warn "MCPs:   无 mcp/ 目录"
    fi
    echo ""

    local agent
    for agent in $ALL_AGENTS; do
        local pretty dir format skills_dir mcp_type
        case "$agent" in
            claude)   pretty="Claude Code" ;;
            codex)    pretty="Codex" ;;
            opencode) pretty="OpenCode" ;;
            cursor)   pretty="Cursor" ;;
            *)        pretty="$agent" ;;
        esac
        dir="$(agent_var "$agent" DIR)"
        format="$(agent_var "$agent" SKILLS_FORMAT)"
        skills_dir="$(agent_var "$agent" SKILLS_DIR)"
        mcp_type="$(agent_var "$agent" MCP_TYPE)"
        echo -e "${BOLD}【${pretty}】${NC}"

        # Skills
        if [[ -n "$format" && -n "$skills_dir" ]]; then
            local sdir; sdir="$(expand_path "$skills_dir")"
            local inst=0 miss=0 total="${#SKILL_NAMES[@]}" i name link
            for i in "${!SKILL_NAMES[@]}"; do
                name="${SKILL_NAMES[$i]}"
                if [[ "$format" == "mdc" ]]; then
                    link="$sdir/$name.mdc"
                    if [[ -f "$link" ]]; then inst=$((inst+1)); else miss=$((miss+1)); fi
                elif [[ "$format" == "copy" ]]; then
                    link="$sdir/$name"
                    if [[ -d "$link" ]]; then inst=$((inst+1)); else miss=$((miss+1)); fi
                else
                    link="$sdir/$name"
                    if [[ -L "$link" ]]; then inst=$((inst+1)); else miss=$((miss+1)); fi
                fi
            done
            if [[ "$miss" -eq 0 ]]; then
                log "Skills: $inst/$total（$sdir）"
            else
                warn "Skills: $inst/$total，缺 $miss（$sdir）"
            fi
        else
            info "Skills: 不支持"
        fi

        # MCP
        if [[ -z "$mcp_type" ]]; then
            info "MCPs:   不支持"
        elif [[ ${#MCP_NAMES[@]} -eq 0 ]]; then
            info "MCPs:   无源"
        elif [[ "$mcp_type" == "command" ]]; then
            local mi=0 mm=0 mtotal="${#MCP_NAMES[@]}" n
            for n in "${MCP_NAMES[@]}"; do
                if command -v claude &>/dev/null && claude mcp list 2>/dev/null | grep -q "$n"; then
                    mi=$((mi+1))
                else
                    mm=$((mm+1))
                fi
            done
            if [[ "$mm" -eq 0 ]]; then log "MCPs:   $mi/$mtotal"; else warn "MCPs:   $mi/$mtotal，缺 $mm"; fi
        else
            local mcp_file mi=0 mm=0 mtotal="${#MCP_NAMES[@]}" n
            mcp_file="$(expand_path "$(agent_var "$agent" MCP_FILE)")"
            for n in "${MCP_NAMES[@]}"; do
                if mcp_in_json "$mcp_file" "$n"; then mi=$((mi+1)); else mm=$((mm+1)); fi
            done
            if [[ "$mm" -eq 0 ]]; then
                log "MCPs:   $mi/$mtotal（$mcp_file）"
            else
                warn "MCPs:   $mi/$mtotal，缺 $mm（$mcp_file）"
            fi
        fi
        echo ""
    done
}

# ============================================================
# 命令实现
# ============================================================

validate_agent() {
    local a found=false
    for a in $ALL_AGENTS; do
        [[ "$a" == "$1" ]] && found=true
    done
    if [[ "$found" == false ]]; then
        err "未知 Agent: $1（支持: $(echo $ALL_AGENTS | tr ' ' ', ')）"
        exit 1
    fi
}

# 公共选项解析 → AGENT_ARG / SKILLS_ONLY / MCP_ONLY（DRY_RUN 全局）
parse_opts() {
    AGENT_ARG=""; SKILLS_ONLY=false; MCP_ONLY=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skills-only) SKILLS_ONLY=true; shift ;;
            --mcp-only)    MCP_ONLY=true; shift ;;
            --dry-run)     DRY_RUN=true; shift ;;
            --all)         AGENT_ARG="--all"; shift ;;
            -h|--help)     return 1 ;;
            -*)            err "未知选项: $1"; return 1 ;;
            *)             AGENT_ARG="$1"; shift ;;
        esac
    done
    return 0
}

agents_for() {
    # $1 = AGENT_ARG；回显要处理的 agent 列表（已校验）
    if [[ "$1" == "--all" ]]; then
        echo "$ALL_AGENTS"
    else
        validate_agent "$1"
        echo "$1"
    fi
}

cmd_install() {
    parse_opts "$@" || { show_help; return 1; }
    [[ -n "$AGENT_ARG" ]] || AGENT_ARG="--all"   # 未指定 agent 默认全平台
    local agents a
    agents="$(agents_for "$AGENT_ARG")"
    for a in $agents; do
        echo ""
        info "=== 安装 → $a ==="
        $MCP_ONLY || install_skills "$a"
        $SKILLS_ONLY || install_mcps "$a"
    done
    echo ""
    log "完成。运行 './install.sh status' 查看状态"
}

cmd_uninstall() {
    parse_opts "$@" || { show_help; return 1; }
    [[ -n "$AGENT_ARG" ]] || { err "用法: $0 uninstall <agent|--all>"; return 1; }
    local agents a
    agents="$(agents_for "$AGENT_ARG")"
    for a in $agents; do
        $MCP_ONLY || uninstall_skills "$a"
        $SKILLS_ONLY || uninstall_mcps "$a"
    done
    log "卸载完成"
}

cmd_update() {
    parse_opts "$@" || { show_help; return 1; }
    [[ -n "$AGENT_ARG" ]] || { err "用法: $0 update <agent|--all>"; return 1; }
    info "重新同步..."
    local agents a
    agents="$(agents_for "$AGENT_ARG")"
    for a in $agents; do
        echo ""
        info "=== 更新 → $a ==="
        $MCP_ONLY || uninstall_skills "$a"
        $SKILLS_ONLY || uninstall_mcps "$a"
        $MCP_ONLY || install_skills "$a"
        $SKILLS_ONLY || install_mcps "$a"
    done
    log "完成"
}

# 向后兼容老 flag: ./install.sh --target DIR [--dry-run] | ./install.sh --dry-run
cmd_legacy() {
    if [[ "${1:-}" == "--dry-run" && $# -eq 1 ]]; then
        cmd_install --all --dry-run
        return
    fi
    local targets=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target)
                [[ $# -ge 2 ]] || { err "--target 需要目录"; exit 1; }
                targets+=("$(expand_path "$2")"); shift 2
                ;;
            --dry-run) DRY_RUN=true; shift ;;
            *) err "未知选项: $1"; exit 1 ;;
        esac
    done
    if [[ ${#targets[@]} -eq 0 ]]; then
        cmd_install --all
        return
    fi
    echo -e "${BLUE}=== 安装 Skills（legacy --target，symlink）===${NC}"
    local t
    for t in "${targets[@]}"; do
        install_skills_to_dir "(--target)" "$t" symlink
    done
    $DRY_RUN && echo -e "${YELLOW}(dry-run 模式 — 未实际改动)${NC}"
    echo -e "${GREEN}Done!${NC}"
}

show_help() {
    cat <<EOF
${BOLD}Han Skills + MCP 安装器${NC}

${BOLD}用法:${NC}
  $0 <command> [agent|--all] [options]
  $0                                  # 无参 = install --all

${BOLD}命令:${NC}
  install   [agent|--all]   安装 skills + MCP
  uninstall [agent|--all]   卸载
  update    [agent|--all]   重新同步（卸载 + 安装）
  status                    查看所有平台安装状态
  --cleanup                 清理失效软链
  help                      显示本帮助

${BOLD}选项:${NC}
  --skills-only    只处理 skills
  --mcp-only       只处理 MCP
  --dry-run        预览，不实际改动
  --target DIR     (兼容) 把 skills 软链到 DIR，可重复

${BOLD}Agent:${NC}  $(echo $ALL_AGENTS | tr ' ' ' | ')

${BOLD}示例:${NC}
  $0                          # 装全部到所有平台
  $0 status                   # 看状态
  $0 install claude           # 只装 Claude Code
  $0 install cursor           # 生成 .mdc → ~/.cursor/rules
  $0 install claude --mcp-only
  $0 uninstall cursor         # 卸载 Cursor
  $0 update --all             # 全平台重装

${BOLD}配置:${NC}  $CONF_FILE
EOF
}

# ============================================================
# 主入口
# ============================================================

discover_skills
discover_mcps

case "${1:-}" in
    install)    shift; cmd_install "$@" ;;
    uninstall)  shift; cmd_uninstall "$@" ;;
    update)     shift; cmd_update "$@" ;;
    status|--list|-l) show_status ;;
    --cleanup)  cleanup_stale_links ;;
    --dry-run)  cmd_legacy --dry-run ;;
    --target)   cmd_legacy "$@" ;;
    help|-h|--help) show_help ;;
    "")         cmd_install --all ;;
    *)
        err "未知命令: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
