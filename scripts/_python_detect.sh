#!/usr/bin/env bash
# _python_detect.sh — 通用的 Python 检测 + mcp 模块确保
# 本脚本被 setup-mcp.sh / setup-remote.sh source，不独立执行。
#
# 依赖调用方提供颜色变量 RED/GREEN/YELLOW/CYAN/NC（若未定义则输出纯文本）。
#
# 提供两个函数:
#   detect_python    — 找可用的 Python（python3 > python），设置 PYTHON_BIN
#   ensure_mcp       — 确保 mcp 模块可用，必要时 pip install（交互确认）

# 颜色兜底（若调用方未定义）
_RED="${RED:-}"
_GREEN="${GREEN:-}"
_YELLOW="${YELLOW:-}"
_CYAN="${CYAN:-}"
_NC="${NC:-}"

# ── detect_python: 找可用的 Python 解释器（>= 3.10，优先已装 mcp） ──
# 查找顺序:
#   1. $HAN_MCP_PYTHON 环境变量（用户显式指定）
#   2. PATH 中的 python3 / python（优先已装 mcp 的）
#   3. ~/.local/bin/python3（常见用户安装路径）
# 设置全局变量 PYTHON_BIN。
detect_python() {
    PYTHON_BIN=""

    # 0. 用户显式指定
    if [[ -n "${HAN_MCP_PYTHON:-}" ]] && command -v "$HAN_MCP_PYTHON" &>/dev/null; then
        PYTHON_BIN="$HAN_MCP_PYTHON"
        return 0
    fi

    # 1. 第一轮：PATH 中找已装 mcp 的
    for p in python3 python; do
        if command -v "$p" &>/dev/null && _py_version_ok "$p" && "$p" -c "from mcp.server.fastmcp import FastMCP" 2>/dev/null; then
            PYTHON_BIN="$p"
            return 0
        fi
    done

    # 2. 第二轮：~/.local/bin 找已装 mcp 的
    for p in "$HOME/.local/bin/python3" "$HOME/.local/bin/python"; do
        if command -v "$p" &>/dev/null && _py_version_ok "$p" && "$p" -c "from mcp.server.fastmcp import FastMCP" 2>/dev/null; then
            PYTHON_BIN="$p"
            return 0
        fi
    done

    # 3. 第三轮：找任意版本合格的 Python（给 ensure_mcp 装 mcp）
    for p in python3 python "$HOME/.local/bin/python3"; do
        if command -v "$p" &>/dev/null && _py_version_ok "$p"; then
            PYTHON_BIN="$p"
            return 0
        fi
    done

    echo -e "${_RED}[错误] 未找到 Python >= 3.10，请先安装${_NC}" >&2
    echo "  可通过环境变量指定: export HAN_MCP_PYTHON=/path/to/python3" >&2
    return 1
}

# ── _py_version_ok: 检查 Python 版本 >= 3.10 ──
_py_version_ok() {
    local py="$1"
    local ver
    ver=$("$py" -c "import sys; print(sys.version_info[:2])" 2>/dev/null) || return 1
    # 输出格式如 "(3, 10)" 或 "(3, 8)"
    local major minor
    major=$(echo "$ver" | grep -oP '\d+' | head -1)
    minor=$(echo "$ver" | grep -oP '\d+' | tail -1)
    [[ "$major" -ge 3 ]] && [[ "$minor" -ge 10 ]] && return 0
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
    if "$py" -c "from mcp.server.fastmcp import FastMCP" 2>/dev/null; then
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
        if "$py" -c "from mcp.server.fastmcp import FastMCP" 2>/dev/null; then
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
