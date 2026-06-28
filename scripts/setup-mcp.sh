#!/usr/bin/env bash
set -euo pipefail

# setup-mcp.sh — 发现并注册 han-skill 附带的 MCP Server
#
# 扫描 mcp/*/mcp.json，检测 Python 环境，输出 claude mcp add 命令。
#
# 用法:
#   ./scripts/setup-mcp.sh              # 显示注册命令（手动复制执行）
#   ./scripts/setup-mcp.sh --register   # 自动注册（交互确认，需要 claude CLI）
#   ./scripts/setup-mcp.sh --list       # 仅列出发现的 MCP 服务器

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MCP_ROOT="$PROJECT_ROOT/mcp"

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    NC=''
fi

LIST_ONLY=false
AUTO_REGISTER=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --list) LIST_ONLY=true; shift ;;
        --register) AUTO_REGISTER=true; shift ;;
        -h|--help)
            echo "用法: $(basename "$0") [--list | --register]"
            echo ""
            echo "  (无参数)    显示注册命令，手动复制执行"
            echo "  --list      仅列出发现的 MCP 服务器"
            echo "  --register  自动注册（交互确认，需要 claude CLI）"
            exit 0
            ;;
        *) echo -e "${RED}未知选项: $1${NC}" >&2; exit 1 ;;
    esac
done

# ── 检查 mcp/ 目录 ──
if [[ ! -d "$MCP_ROOT" ]]; then
    echo -e "${YELLOW}未找到 mcp/ 目录，没有附带的 MCP Server${NC}"
    exit 0
fi

# ── 发现 MCP 服务器 ──
discover_mcp_servers() {
    local mcp_dir name desc
    MCP_NAMES=()
    MCP_DIRS=()
    MCP_DESCS=()

    shopt -s nullglob
    for mcp_dir in "$MCP_ROOT"/*; do
        [[ -d "$mcp_dir" ]] || continue
        local meta="$mcp_dir/mcp.json"
        if [[ -f "$meta" ]]; then
            name="$(python3 -c "import json; print(json.load(open('$meta')).get('name',''))" 2>/dev/null || echo "$(basename "$mcp_dir")")"
            desc="$(python3 -c "import json; print(json.load(open('$meta')).get('description',''))" 2>/dev/null || echo "")"
        else
            name="$(basename "$mcp_dir")"
            desc=""
        fi
        MCP_NAMES+=("$name")
        MCP_DIRS+=("$mcp_dir")
        MCP_DESCS+=("$desc")
    done
    shopt -u nullglob
}

# ── 加载通用 Python 检测 ──
source "$SCRIPT_DIR/_python_detect.sh"

# ── 读 mcp.json 的 env 字段 ──
read_env_hints() {
    local meta="$1"
    python3 -c "
import json
try:
    data = json.load(open('$meta'))
    env = data.get('env', {})
    for k, v in env.items():
        print(f'{k}|{v}')
except: pass
" 2>/dev/null || true
}

# ── 主逻辑 ──
discover_mcp_servers

if [[ ${#MCP_NAMES[@]} -eq 0 ]]; then
    echo -e "${YELLOW}mcp/ 目录下未发现 MCP 服务器${NC}"
    exit 0
fi

# ── --list 模式（无需 Python/mcp，直接列出） ──
if $LIST_ONLY; then
    echo -e "${BLUE}=== 发现的 MCP 服务器 ===${NC}"
    for i in "${!MCP_NAMES[@]}"; do
        echo -e "${GREEN}${MCP_NAMES[$i]}${NC}"
        echo "  路径: ${MCP_DIRS[$i]}"
        echo "  入口: ${MCP_DIRS[$i]}/server.py"
        [[ -n "${MCP_DESCS[$i]}" ]] && echo "  说明: ${MCP_DESCS[$i]}"
        echo ""
    done
    # 显示 Python 信息（不强制要求 mcp）
    if command -v python3 &>/dev/null; then
        echo "Python: $(python3 --version 2>&1)"
    fi
    exit 0
fi

if ! detect_python; then
    echo -e "${RED}无法继续：未找到可用的 Python${NC}" >&2
    exit 1
fi

ensure_mcp || {
    echo -e "${RED}无法继续：mcp 模块不可用${NC}" >&2
    exit 1
}

# ── 显示注册命令 ──
echo -e "${BLUE}=== MCP Server 注册命令 ===${NC}"
echo "项目路径: $PROJECT_ROOT"
echo "Python: $PYTHON_BIN ($($PYTHON_BIN --version 2>&1 || true))"
echo ""

for i in "${!MCP_NAMES[@]}"; do
    name="${MCP_NAMES[$i]}"
    dir="${MCP_DIRS[$i]}"
    desc="${MCP_DESCS[$i]}"
    server_py="$dir/server.py"
    meta="$dir/mcp.json"

    if [[ ! -f "$server_py" ]]; then
        echo -e "${RED}[$name] 未找到 server.py，跳过${NC}"
        continue
    fi

    echo -e "${GREEN}── ${name}${NC}"
    [[ -n "$desc" ]] && echo "   ${desc}"
    echo ""

    # 读取环境变量提示
    env_hints="$(read_env_hints "$meta")"
    env_args=()
    env_descs=()

    if [[ -n "$env_hints" ]]; then
        while IFS='|' read -r key val; do
            [[ -z "$key" ]] && continue
            env_args+=("  -e $key=...")
            env_descs+=("  # $key: $val")
        done <<< "$env_hints"
    fi

    if $AUTO_REGISTER; then
        # 交互式收集环境变量
        cmd_env_args=()
        if [[ -n "$env_hints" ]]; then
            echo "请配置以下环境变量（直接回车跳过）："
            while IFS='|' read -r key val; do
                [[ -z "$key" ]] && continue
                echo -n "  $key [$val]: "
                read -r user_val
                if [[ -n "$user_val" ]]; then
                    cmd_env_args+=("-e" "${key}=${user_val}")
                fi
            done <<< "$env_hints"
        fi

        echo ""
        echo -n "确认注册 ${name}? [y/N] "
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            claude mcp add "$name" -s user \
                "${cmd_env_args[@]}" \
                -- "$PYTHON_BIN" "$server_py"
            echo -e "${GREEN}[OK] ${name} 已注册${NC}"
        else
            echo "跳过 ${name}"
        fi
        echo ""
    else
        # 显示手动注册命令
        if [[ ${#env_args[@]} -gt 0 ]]; then
            echo "  # 方式一: SSH config Host 别名（推荐）"
            echo "  claude mcp add ${name} -s user \\\\"
            echo "    -e SSH_HOST_ALIAS=winpc \\\\"
            echo "    -- ${PYTHON_BIN} ${server_py}"
            echo ""
            echo "  # 方式二: 完整环境变量"
            echo "  claude mcp add ${name} -s user \\\\"
            for arg in "${env_args[@]}"; do
                echo "  ${arg} \\\\"
            done
            echo "    -- ${PYTHON_BIN} ${server_py}"
        else
            echo "  claude mcp add ${name} -s user \\\\"
            echo "    -- ${PYTHON_BIN} ${server_py}"
        fi
        echo ""
    fi
done

if ! $AUTO_REGISTER; then
    echo -e "${CYAN}──────────────────────────────────────${NC}"
    echo "复制上方命令到终端执行即可完成注册。"
    echo "注册后运行 claude mcp list 验证。"
    echo -e "使用 ${GREEN}--register${NC} 参数可交互式自动注册。"
fi
