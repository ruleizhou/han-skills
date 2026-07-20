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

# 从 mcp.json 读取元数据字段，缺省 type="command"
read_mcp_meta() {
    local mcp_dir="$1" field="$2"
    local meta="$mcp_dir/mcp.json"
    [[ -f "$meta" ]] || { [[ "$field" == "type" ]] && echo "command" || echo ""; return 0; }
    MCP_META="$meta" MCP_FIELD="$field" python3 -c "
import json, os, sys
with open(os.environ['MCP_META']) as f:
    d = json.load(f)
val = d.get(os.environ['MCP_FIELD'], 'command' if os.environ['MCP_FIELD']=='type' else '')
if isinstance(val, (dict, list)):
    print(json.dumps(val, ensure_ascii=False))
else:
    print(val)
"
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
        if [[ "$(basename "$skill_dir")" == "Deprecated" ]]; then
            continue
        fi
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

# 输出 HTTP MCP 的完整 JSON（url + headers，env var 替换）
build_http_mcp_json() {
    local mcp_dir="$1"
    MCP_META="$mcp_dir/mcp.json" WOLAI_TOKEN="${WOLAI_TOKEN:-}" python3 -c "
import json, os, re
with open(os.environ['MCP_META']) as f:
    d = json.load(f)
url = d.get('url', '')
# headers 中的 \${VAR} 用环境变量替换
headers = {}
for k, v in d.get('headers', {}).items():
    v_sub = v
    for match in re.finditer(r'\\$\\{(\\w+)\\}', v):
        var_name = match.group(1)
        v_sub = v_sub.replace(match.group(0), os.environ.get(var_name, ''))
    headers[k] = v_sub
result = {'type': 'http', 'url': url, 'headers': headers}
print(json.dumps(result, ensure_ascii=False))
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

    # 需要 Python >= 3.10（仅 command 类型 MCP server 运行依赖）
    # HTTP 类型 MCP 不需要 Python；仅跳过检测，循环内按类型判断
    local has_python=true
    if ! detect_python; then
        has_python=false
    fi

    local i
    for i in "${!MCP_NAMES[@]}"; do
        local mcp_name="${MCP_NAMES[$i]}"
        local mcp_dir="${MCP_DIRS[$i]}"
        local mcp_type_meta
        mcp_type_meta="$(read_mcp_meta "$mcp_dir" "type")"

        # HTTP 类型：跳过 server.py 检查，统一走 JSON 直接写入
        if [[ "$mcp_type_meta" == "http" ]]; then
            install_http_mcp "$agent" "$mcp_name" "$mcp_dir"
            continue
        fi

        local server_py="$mcp_dir/server.py"
        if [[ ! -f "$server_py" ]]; then
            warn "$agent: $mcp_name 缺 server.py，跳过"
            continue
        fi

        if [[ "$mcp_type" == "command" ]]; then
            # Claude Code: claude mcp add
            if [[ "$has_python" != "true" ]]; then
                warn "$agent: 未找到 Python >= 3.10，跳过 command MCP $mcp_name（可设置 HAN_MCP_PYTHON）"
                continue
            fi
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
        local mcp_dir="${MCP_DIRS[$i]}"
        local mcp_type_meta
        mcp_type_meta="$(read_mcp_meta "$mcp_dir" "type")"

        # HTTP 类型：从对应 JSON 文件移除
        if [[ "$mcp_type_meta" == "http" ]]; then
            uninstall_http_mcp "$agent" "$mcp_name"
            continue
        fi

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
# Understand-Anything（第三方 plugin）安装
# 默认同步装（HAN_INSTALL_UA=1，install.conf 兜底；--no-ua / HAN_INSTALL_UA=0 关）。
# 各平台原生方式：claude→claude plugin install；codex/opencode→UA 官方 curl|bash；
# cursor→CLI 官方不支持 plugin，提示 IDE clone。
# ============================================================

install_ua() {
    local agent="$1"
    [[ "${HAN_INSTALL_UA:-1}" == "1" ]] || { info "$agent: 跳过 UA（--no-ua 或 HAN_INSTALL_UA=0）"; return 0; }
    case "$agent" in
        claude)
            command -v claude &>/dev/null || { warn "$agent: claude CLI 未找到，跳过 UA"; return 0; }
            local ua_mp="${UA_MARKETPLACE:-Egonex-AI/Understand-Anything}"
            if $DRY_RUN; then
                echo "  [dry] claude plugin marketplace add $ua_mp（UA 官方）"
                echo "  [dry] claude plugin install understand-anything@understand-anything"
                return 0
            fi
            # 用 UA 官方 marketplace（其 source 是相对路径 ./understand-anything-plugin，组件加载正确）。
            # 不走 han-skills marketplace 引用：UA repo 根有 .claude-plugin/ + plugin 在 understand-anything-plugin/
            # 子目录，url+path 会让 claude 把 repo 根当组件扫描根 → 组件 0；git-subdir 又需 git≥2.20。
            claude plugin marketplace list 2>/dev/null | grep -q "understand-anything" \
                || claude plugin marketplace add "$ua_mp"
            if claude plugin list 2>/dev/null | grep -q "understand-anything"; then
                info "$agent: UA 已装"; return 0
            fi
            if claude plugin install understand-anything@understand-anything; then
                log "$agent: 装好 UA（完整：skills + 9 subagent）"
            else
                warn "$agent: 装 UA 失败"
            fi
            ;;
        codex)
            command -v curl &>/dev/null || { warn "$agent: curl 未找到，跳过 UA"; return 0; }
            if $DRY_RUN; then echo "  [dry] curl -fsSL UA install.sh | bash -s codex"; return 0; fi
            if curl -fsSL "$UA_INSTALL_URL" | bash -s codex; then
                log "$agent: 装好 UA skills（降级：UA 无 codex 清单，subagent 不注册）"
            else
                warn "$agent: 装 UA 失败"
            fi
            ;;
        opencode)
            command -v curl &>/dev/null || { warn "$agent: curl 未找到，跳过 UA"; return 0; }
            if $DRY_RUN; then
                echo "  [dry] curl -fsSL UA install.sh | bash -s opencode"
                echo "  [dry] + 软链 agents/*.md → ~/.config/opencode/agents/"
                return 0
            fi
            if ! curl -fsSL "$UA_INSTALL_URL" | bash -s opencode; then
                warn "$agent: UA 装 skills 失败"; return 0
            fi
            # 额外补 subagent 注册（比 UA 官方更完整）：软链 agents/*.md 到 opencode 扫描目录
            local ua_agents="$HOME/.understand-anything/repo/understand-anything-plugin/agents"
            local oc_dir="$HOME/.config/opencode/agents"
            if [[ -d "$ua_agents" ]]; then
                mkdir -p "$oc_dir"
                local a n=0
                shopt -s nullglob
                for a in "$ua_agents"/*.md; do ln -sfn "$a" "$oc_dir/$(basename "$a")"; n=$((n+1)); done
                shopt -u nullglob
                log "$agent: 装好 UA（skills + $n subagent，可完整）"
            else
                log "$agent: 装好 UA skills（未找到 agents 目录，跳过 subagent 注册）"
            fi
            ;;
        cursor)
            info "$agent: cursor CLI 官方不支持 plugin（论坛确认）。完整方案 = git clone UA 仓库后在 Cursor IDE 打开，靠 .cursor-plugin 自动发现（含 subagent）。install.sh 不代劳此 GUI 步骤。"
            ;;
        *)
            info "$agent: 无 UA 安装路径，跳过"
            ;;
    esac
}

# Understand-Anything 卸载（与 install_ua 对称；幂等，未装则无操作，不受 HAN_INSTALL_UA 开关影响）
uninstall_ua() {
    local agent="$1"
    case "$agent" in
        claude)
            command -v claude &>/dev/null || return 0
            claude plugin list 2>/dev/null | grep -q "understand-anything" || return 0
            if $DRY_RUN; then
                echo "  [dry] claude plugin uninstall understand-anything"; return 0
            fi
            if claude plugin uninstall understand-anything 2>/dev/null; then
                log "$agent: 移除 UA"
            else
                warn "$agent: 移除 UA 失败"
            fi
            ;;
        codex|opencode)
            local ua_repo="$HOME/.understand-anything/repo"
            [[ -d "$ua_repo" ]] || return 0
            if $DRY_RUN; then
                echo "  [dry] bash $ua_repo/install.sh --uninstall $agent"
            elif bash "$ua_repo/install.sh" --uninstall "$agent" 2>/dev/null; then
                log "$agent: 移除 UA"
            else
                warn "$agent: 移除 UA 失败（可手动 rm -rf ~/.understand-anything）"
            fi
            # opencode 额外移除指向 UA repo 的 subagent 软链
            if [[ "$agent" == "opencode" && -d "$HOME/.config/opencode/agents" ]]; then
                local oc_dir="$HOME/.config/opencode/agents" a
                shopt -s nullglob
                for a in "$oc_dir"/*.md; do
                    [[ -L "$a" ]] || continue
                    case "$(readlink "$a")" in
                        */.understand-anything/repo/*) $DRY_RUN || rm -f "$a" ;;
                    esac
                done
                shopt -u nullglob
            fi
            ;;
        cursor)
            info "$agent: UA 未经 install.sh 安装（cursor 走 IDE），无需卸载"
            ;;
    esac
}

# HTTP MCP 目标 JSON 文件
http_mcp_target_file() {
    local agent="$1"
    case "$agent" in
        claude)   echo "$HOME/.claude.json" ;;
        opencode) echo "$(expand_path "$(agent_var opencode MCP_FILE)")" ;;
        cursor)   echo "$(expand_path "$(agent_var cursor MCP_FILE)")" ;;
        *)        echo "" ;;
    esac
}

install_http_mcp() {
    local agent="$1" mcp_name="$2" mcp_dir="$3"
    local target_file
    target_file="$(http_mcp_target_file "$agent")"
    if [[ -z "$target_file" ]]; then
        warn "$agent: HTTP MCP 不支持，跳过 $mcp_name"
        return 0
    fi

    if mcp_in_json "$target_file" "$mcp_name"; then
        info "$agent: HTTP MCP $mcp_name 已注册"
        return 0
    fi

    local http_json
    http_json="$(build_http_mcp_json "$mcp_dir")"
    if $DRY_RUN; then
        echo "  [dry] 注册 HTTP MCP $mcp_name → $target_file"
    else
        mkdir -p "$(dirname "$target_file")"
        merge_mcp_json "$target_file" "$mcp_name" "$http_json"
        log "$agent: 注册 HTTP MCP $mcp_name → $target_file"
    fi
}

uninstall_http_mcp() {
    local agent="$1" mcp_name="$2"
    local target_file
    target_file="$(http_mcp_target_file "$agent")"
    if [[ -z "$target_file" ]]; then
        return 0
    fi

    if [[ -f "$target_file" ]] && mcp_in_json "$target_file" "$mcp_name"; then
        if $DRY_RUN; then
            echo "  [dry] 从 $(basename "$target_file") 移除 HTTP MCP $mcp_name"
        else
            remove_mcp_json "$target_file" "$mcp_name"
        fi
        log "$agent: 移除 HTTP MCP $mcp_name"
    fi
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
                "$SKILLS_ROOT"/Deprecated/*)
                    echo -e "  ${RED}rm deprecated:${NC} $(basename "$link") -> $current"
                    $DRY_RUN || rm "$link"
                    removed=$((removed+1))
                    ;;
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
        else
            local mi=0 mm=0 mtotal="${#MCP_NAMES[@]}" k mcp_type_meta target
            for k in "${!MCP_NAMES[@]}"; do
                local mcp_n="${MCP_NAMES[$k]}"
                local mcp_d="${MCP_DIRS[$k]}"
                mcp_type_meta="$(read_mcp_meta "$mcp_d" "type")"
                if [[ "$mcp_type_meta" == "http" ]]; then
                    target="$(http_mcp_target_file "$agent")"
                    if [[ -n "$target" ]] && mcp_in_json "$target" "$mcp_n"; then
                        mi=$((mi+1))
                    else
                        mm=$((mm+1))
                    fi
                elif [[ "$mcp_type" == "command" ]]; then
                    if command -v claude &>/dev/null && claude mcp list 2>/dev/null | grep -q "$mcp_n"; then
                        mi=$((mi+1))
                    else
                        mm=$((mm+1))
                    fi
                else
                    local mcp_file
                    mcp_file="$(expand_path "$(agent_var "$agent" MCP_FILE)")"
                    if mcp_in_json "$mcp_file" "$mcp_n"; then mi=$((mi+1)); else mm=$((mm+1)); fi
                fi
            done
            if [[ "$mm" -eq 0 ]]; then
                log "MCPs:   $mi/$mtotal"
            else
                warn "MCPs:   $mi/$mtotal，缺 $mm"
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
    AGENT_ARG=""; SKILLS_ONLY=false; MCP_ONLY=false; UA_ONLY=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skills-only) SKILLS_ONLY=true; shift ;;
            --mcp-only)    MCP_ONLY=true; shift ;;
            --with-ua)     HAN_INSTALL_UA=1; shift ;;
            --no-ua)       HAN_INSTALL_UA=0; shift ;;
            --ua-only)     UA_ONLY=true; shift ;;
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
        if $UA_ONLY; then install_ua "$a"; continue; fi
        $MCP_ONLY || install_skills "$a"
        $SKILLS_ONLY || install_mcps "$a"
        $SKILLS_ONLY || $MCP_ONLY || install_ua "$a"
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
        if $UA_ONLY; then uninstall_ua "$a"; continue; fi
        $MCP_ONLY || uninstall_skills "$a"
        $SKILLS_ONLY || uninstall_mcps "$a"
        $SKILLS_ONLY || $MCP_ONLY || uninstall_ua "$a"
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
        $SKILLS_ONLY || $MCP_ONLY || install_ua "$a"
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
    echo -e "$(cat <<EOF
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
  $0 install cursor           # 软链 → ~/.cursor/skills
  $0 install claude --mcp-only
  $0 uninstall cursor         # 卸载 Cursor
  $0 update --all             # 全平台重装

${BOLD}配置:${NC}  $CONF_FILE
EOF
)"
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
