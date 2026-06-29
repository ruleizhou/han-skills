#!/usr/bin/env bash
# _python_detect.sh — 通用的 Python 检测 + mcp 模块确保
# 本脚本被 install.sh / setup-remote.sh source，不独立执行。
#
# 依赖调用方提供颜色变量 RED/GREEN/YELLOW/CYAN/NC（若未定义则输出纯文本）。
#
# 提供两个函数:
#   detect_python    — 找可用的 Python（>= 3.10，优先已装 mcp），设置 PYTHON_BIN
#   ensure_mcp       — 确保 mcp 模块可用，必要时 pip install（交互确认）

# 颜色兜底（若调用方未定义）
_RED="${RED:-}"
_GREEN="${GREEN:-}"
_YELLOW="${YELLOW:-}"
_CYAN="${CYAN:-}"
_NC="${NC:-}"

# ── _add_python_candidate: 去重追加候选解释器 ──
_seen_python_candidates=""
_add_python_candidate() {
    local c="$1"
    [[ -n "$c" ]] || return 0
    if [[ "$c" != /* ]]; then
        command -v "$c" &>/dev/null || return 0
        c="$(command -v "$c")"
    fi
    [[ -x "$c" ]] || return 0
    [[ " $_seen_python_candidates " == *" $c "* ]] && return 0
    _seen_python_candidates+=" $c"
    _PYTHON_CANDIDATES+=("$c")
}

# ── _python_candidates: 收集所有候选 Python 路径 ──
# 查找顺序:
#   1. $HAN_MCP_PYTHON 环境变量（用户显式指定）
#   2. PATH 中的 python3 / python
#   3. ~/.local/bin/python3
#   4. /usr/local/meig/python/*/bin/python3（公司常见安装路径）
#   5. $HAN_MCP_PYTHON_SEARCH_DIRS 中列出的目录（冒号分隔）
_PYTHON_CANDIDATES=()
_python_candidates() {
    _PYTHON_CANDIDATES=()
    _seen_python_candidates=""

    _add_python_candidate "${HAN_MCP_PYTHON:-}"
    _add_python_candidate python3
    _add_python_candidate python
    _add_python_candidate "$HOME/.local/bin/python3"
    _add_python_candidate "$HOME/.local/bin/python"

    if [[ -d /usr/local/meig/python ]]; then
        local meig_py
        for meig_py in /usr/local/meig/python/*/bin/python3; do
            [[ -e "$meig_py" ]] || continue
            _add_python_candidate "$meig_py"
        done
    fi

    if [[ -n "${HAN_MCP_PYTHON_SEARCH_DIRS:-}" ]]; then
        local dir py
        IFS=':' read -ra _py_search_dirs <<< "$HAN_MCP_PYTHON_SEARCH_DIRS"
        for dir in "${_py_search_dirs[@]}"; do
            [[ -n "$dir" ]] || continue
            for py in "$dir" "$dir/bin/python3" "$dir/python3"; do
                _add_python_candidate "$py"
            done
        done
    fi

    printf '%s\n' "${_PYTHON_CANDIDATES[@]}"
}

# ── _py_version_ok: 检查 Python 版本 >= 3.10 ──
_py_version_ok() {
    local py="$1"
    "$py" -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)" 2>/dev/null
}

# ── _py_version_tuple: 输出版本号（如 3.10）供排序 ──
_py_version_tuple() {
    local py="$1"
    "$py" -c "import sys; print(f'{sys.version_info[0]}.{sys.version_info[1]}')" 2>/dev/null
}

# ── _has_mcp: 检查 mcp 模块是否可用 ──
_has_mcp() {
    local py="$1"
    "$py" -c "from mcp.server.fastmcp import FastMCP" 2>/dev/null
}

# ── _pick_best_python: 从候选中选最高版本；require_mcp=true 时仅考虑已装 mcp 的 ──
_pick_best_python() {
    local require_mcp="$1"
    shift
    local -a cands=("$@")
    local c ver line best=""

    for c in "${cands[@]}"; do
        _py_version_ok "$c" || continue
        if [[ "$require_mcp" == true ]] && ! _has_mcp "$c"; then
            continue
        fi
        ver="$(_py_version_tuple "$c")" || continue
        line+="${ver}"$'\t'"${c}"$'\n'
    done

    [[ -n "$line" ]] || return 1
    best="$(printf '%s' "$line" | sort -t$'\t' -k1,1V | tail -1 | cut -f2-)"
    [[ -n "$best" ]] || return 1
    PYTHON_BIN="$best"
    return 0
}

# ── detect_python: 找可用的 Python 解释器（>= 3.10，优先已装 mcp 的最高版本） ──
# 设置全局变量 PYTHON_BIN。
detect_python() {
    PYTHON_BIN=""
    local -a cands=()

    while IFS= read -r c; do
        [[ -n "$c" ]] && cands+=("$c")
    done < <(_python_candidates)

    if _pick_best_python true "${cands[@]}"; then
        return 0
    fi
    if _pick_best_python false "${cands[@]}"; then
        return 0
    fi

    echo -e "${_RED}[错误] 未找到 Python >= 3.10，请先安装${_NC}" >&2
    echo "  可通过环境变量指定: export HAN_MCP_PYTHON=/path/to/python3" >&2
    echo "  或追加搜索目录: export HAN_MCP_PYTHON_SEARCH_DIRS=/path/to/python/bin" >&2
    return 1
}

# ── ensure_mcp: 确保 mcp 模块可用 ──
# 先检测 mcp 模块是否存在，不存在则询问用户是否自动 pip install。
# 依赖 detect_python 先设置好 PYTHON_BIN。
# 成功返回 0，失败返回 1。
ensure_mcp() {
    local py="${1:-$PYTHON_BIN}"
    if [[ -z "$py" ]]; then
        echo -e "${_RED}[错误] Python 未检测到，无法安装 mcp${_NC}" >&2
        return 1
    fi

    # 版本检查
    if ! _py_version_ok "$py"; then
        local ver; ver=$("$py" --version 2>&1)
        echo -e "${_RED}[错误] Python 版本过低: $ver（需要 >= 3.10）${_NC}" >&2
        echo "  请安装 Python >= 3.10，或设置 HAN_MCP_PYTHON 指向正确的 Python" >&2
        return 1
    fi

    # 先测试 mcp 是否已安装
    if _has_mcp "$py"; then
        echo -e "${_GREEN}[OK]${_NC} Python: $py ($($py --version 2>&1)), mcp 已安装"
        return 0
    fi

    # mcp 未安装，询问用户是否自动安装
    echo -e "${_YELLOW}mcp 模块未安装（Python: $py $($py --version 2>&1)）${_NC}"
    echo -n "是否自动执行 pip install mcp？[Y/n] "
    read -r answer
    if [[ "$answer" =~ ^[Nn] ]]; then
        echo -e "${_YELLOW}跳过 mcp 安装。请手动执行: $py -m pip install mcp${_NC}"
        return 1
    fi

    echo -e "${_CYAN}正在安装 mcp（$py -m pip install mcp）...${_NC}"
    if "$py" -m pip install --quiet mcp 2>&1; then
        if _has_mcp "$py"; then
            echo -e "${_GREEN}[OK] mcp 安装成功${_NC}"
            return 0
        fi
    fi

    echo -e "${_RED}[错误] mcp 安装失败${_NC}" >&2
    echo "  可能原因：" >&2
    echo "  1. 网络不通或 PyPI 不可达" >&2
    echo "  2. pip 版本过旧（尝试: $py -m pip install --upgrade pip）" >&2
    echo "  3. 需要虚拟环境（尝试: python3 -m venv /tmp/mcp-venv && source /tmp/mcp-venv/bin/activate && pip install mcp）" >&2
    echo "" >&2
    echo "  手动安装: $py -m pip install mcp" >&2
    echo "  或指定已有 mcp 的 Python: export HAN_MCP_PYTHON=/path/to/python3" >&2
    return 1
}
