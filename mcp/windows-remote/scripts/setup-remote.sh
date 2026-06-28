#!/usr/bin/env bash
# Windows 远程控制 - 远程端一键配置
# 用法: bash setup-remote.sh <Windows_IP> <Windows用户名> [SSH端口]
# 示例: bash setup-remote.sh 192.168.1.100 zhourulei

set -e

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}========================================"
echo "  Windows 远程控制 - 远程端配置"
echo -e "========================================${NC}"
echo ""

# ----- 参数检查 -----
if [ -z "$1" ]; then
    echo -e "${RED}[错误] 请提供 Windows IP 地址${NC}"
    echo "用法: bash setup-remote.sh <Windows_IP> <Windows用户名> [SSH端口]"
    echo "示例: bash setup-remote.sh 192.168.1.100 zhourulei"
    exit 1
fi

WIN_HOST="$1"
WIN_USER="${2:-$(whoami)}"
WIN_PORT="${3:-22}"

echo -e "  目标: ${WHITE}${WIN_USER}@${WIN_HOST}:${WIN_PORT}${NC}"
echo ""

# ----- 1. 检查 SSH 客户端 -----
echo -e "${YELLOW}--- 检查 SSH 客户端 ---${NC}"
if command -v ssh &>/dev/null; then
    echo -e "${GREEN}[OK] ssh 客户端可用${NC}"
else
    echo -e "${RED}[错误] 未找到 ssh 客户端，容器中需要预装 openssh-client${NC}"
    exit 1
fi

# ----- 2. 生成 SSH 密钥 -----
echo ""
echo -e "${YELLOW}--- 配置 SSH 密钥 ---${NC}"
SSH_DIR="$HOME/.ssh"
KEY_PATH="$SSH_DIR/id_ed25519"

mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"

if [ -f "$KEY_PATH" ]; then
    echo -e "${GREEN}[OK] SSH 密钥已存在: $KEY_PATH${NC}"
else
    ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -q
    echo -e "${GREEN}[OK] 已生成 SSH 密钥: $KEY_PATH${NC}"
fi

# 输出公钥
PUB_KEY=$(cat "${KEY_PATH}.pub")
echo ""
echo -e "${YELLOW}请将以下公钥添加到 Windows 端的 authorized_keys:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "$PUB_KEY"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Windows 端文件路径: C:\\Users\\${WIN_USER}\\.ssh\\authorized_keys"
echo "  或直接在 Windows PowerShell 执行:"
echo "  Add-Content -Path \"\$env:USERPROFILE\\.ssh\\authorized_keys\" -Value '$PUB_KEY'"
echo ""

# ----- 3. 写 SSH config -----
echo -e "${YELLOW}--- 配置 SSH Config ---${NC}"
SSH_CONFIG="$SSH_DIR/config"
touch "$SSH_CONFIG" && chmod 600 "$SSH_CONFIG"

if grep -q "Host winpc" "$SSH_CONFIG" 2>/dev/null; then
    echo -e "${GREEN}[OK] SSH config 中已有 winpc 配置${NC}"
else
    cat >> "$SSH_CONFIG" <<EOF

Host winpc
    HostName ${WIN_HOST}
    User ${WIN_USER}
    Port ${WIN_PORT}
    IdentityFile ${KEY_PATH}
    StrictHostKeyChecking no
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
    echo -e "${GREEN}[OK] 已添加 winpc 配置到 $SSH_CONFIG${NC}"
fi

# ----- 4. 测试连接 -----
echo ""
echo -e "${YELLOW}--- 测试 SSH 连接 ---${NC}"
echo "请确保已将公钥添加到 Windows 端，按 Enter 继续（或 Ctrl+C 跳过）..."
read -r

if ssh -o ConnectTimeout=5 -o BatchMode=yes winpc "echo CONNECTION_OK" 2>/dev/null | grep -q "CONNECTION_OK"; then
    echo -e "${GREEN}[OK] SSH 连接成功！免密登录已生效${NC}"
else
    echo -e "${RED}[!!] SSH 连接失败${NC}"
    echo "可能原因："
    echo "  1. 公钥未添加到 Windows 端"
    echo "  2. Windows SSH 服务未启动"
    echo "  3. 网络不通（ping ${WIN_HOST} 检查）"
    echo ""
    echo "公钥内容（复制到 Windows 的 authorized_keys）："
    echo "$PUB_KEY"
    echo ""
    echo "配置完成后可手动测试: ssh winpc 'echo hello'"
    exit 1
fi

# ----- 5. 注册 MCP Server -----
echo ""
echo -e "${YELLOW}--- 注册 MCP Server ---${NC}"

# 检测 MCP server 路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_PATH="$(dirname "$SCRIPT_DIR")/server.py"

if [ ! -f "$SERVER_PATH" ]; then
    echo -e "${RED}[错误] 未找到 server.py，请确认目录结构完整${NC}" >&2
    exit 1
fi

# 检测可用的 Python 并确保 mcp 模块已安装
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [[ -f "$PROJECT_ROOT/scripts/_python_detect.sh" ]]; then
    source "$PROJECT_ROOT/scripts/_python_detect.sh"
else
    # 兜底：独立的简化检测（未随 han-skill 分发时）
    detect_python() {
        PYTHON_BIN=""
        for p in python3 python; do
            if command -v "$p" &>/dev/null; then
                PYTHON_BIN="$p"
                return 0
            fi
        done
        return 1
    }
    ensure_mcp() {
        local py="${1:-$PYTHON_BIN}"
        "$py" -c "from mcp.server.fastmcp import FastMCP" 2>/dev/null && return 0
        echo "[警告] mcp 模块未安装，将尝试 pip install mcp"
        "$py" -m pip install mcp 2>&1 || { echo "[错误] mcp 安装失败"; return 1; }
        return 0
    }
fi

detect_python || { echo -e "${RED}[错误] 未找到 Python${NC}" >&2; exit 1; }
ensure_mcp || { echo -e "${RED}[错误] 无法确保 mcp 模块${NC}" >&2; exit 1; }
echo "Python: $PYTHON_BIN ($($PYTHON_BIN --version 2>&1))"

echo "MCP Server 路径: $SERVER_PATH"
echo ""
echo "请执行以下命令注册 MCP Server（复制粘贴即可）："
echo ""
echo -e "${CYAN}claude mcp add windows-remote -s user \\${NC}"
echo -e "${CYAN}  -e SSH_HOST_ALIAS=winpc \\${NC}"
echo -e "${CYAN}  -- ${PYTHON_BIN} ${SERVER_PATH}${NC}"
echo ""
echo "（如未配置 SSH config，可改用环境变量方式：）"
echo ""
echo "  claude mcp add windows-remote -s user \\"
echo "    -e WINDOWS_HOST=${WIN_HOST} \\"
echo "    -e WINDOWS_USER=${WIN_USER} \\"
echo "    -e WINDOWS_PORT=${WIN_PORT} \\"
echo "    -e WINDOWS_KEY_PATH=${KEY_PATH} \\"
echo "    -- ${PYTHON_BIN} ${SERVER_PATH}"
echo ""

# ----- 完成 -----
echo ""
echo -e "${CYAN}========================================"
echo "  配置完成！"
echo -e "========================================${NC}"
echo ""
echo "快速使用："
echo "  ssh winpc 'adb devices'"
echo "  ssh winpc 'fastboot devices'"
echo ""
echo "MCP 工具（注册后新开会话）："
echo "  check_connection  - 测试连接"
echo "  list_devices      - 查看设备"
echo "  adb 'devices'     - 执行 adb 命令"
echo "  fastboot 'devices' - 执行 fastboot 命令"
echo ""
