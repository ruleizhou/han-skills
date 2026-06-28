#!/usr/bin/env bash
# 安装 rmt-adb 和 rmt-fastboot 到 ~/.local/bin（symlink 方式）
# 同时自动配置 SSH 连接环境变量到 ~/.bashrc
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/.local/bin"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== 安装远程 adb/fastboot 终端工具 ===${NC}"
echo ""

# ────────────────── 1. 安装 symlink ──────────────────
mkdir -p "$INSTALL_DIR"

for tool in rmt-adb rmt-fastboot rmt-uart; do
    src="${SCRIPT_DIR}/${tool}"
    dst="${INSTALL_DIR}/${tool}"

    if [[ -L "$dst" ]] || [[ -f "$dst" ]]; then
        echo -e "${YELLOW}[!]${NC} ${dst} 已存在，覆盖..."
        rm -f "$dst"
    fi

    ln -s "$src" "$dst"
    echo -e "${GREEN}[OK]${NC} ${tool} → ${dst}"
done

# ────────────────── 2. 检测 SSH 连接方式 ──────────────────
SSH_ENV_LINE=""

# 优先：当前 shell 已有 SSH_HOST_ALIAS
if [[ -n "${SSH_HOST_ALIAS:-}" ]]; then
    SSH_ENV_LINE="export SSH_HOST_ALIAS=${SSH_HOST_ALIAS}"
    echo -e "${GREEN}[检测]${NC} 当前 Shell: SSH_HOST_ALIAS=${SSH_HOST_ALIAS}"
fi

# 其次：从 MCP 配置读取
if [[ -z "$SSH_ENV_LINE" ]]; then
    MCP_ALIAS=$(claude mcp get windows-remote 2>/dev/null | grep "SSH_HOST_ALIAS=" | head -1 | sed 's/.*SSH_HOST_ALIAS=//')
    if [[ -n "$MCP_ALIAS" ]]; then
        SSH_ENV_LINE="export SSH_HOST_ALIAS=${MCP_ALIAS}"
        echo -e "${GREEN}[检测]${NC} MCP 配置: SSH_HOST_ALIAS=${MCP_ALIAS}"
    fi
fi

# 再次：检查 ~/.ssh/config 中是否有 winpc
if [[ -z "$SSH_ENV_LINE" ]]; then
    SSH_HOST_FROM_CONFIG=$(grep -i "^Host " "$HOME/.ssh/config" 2>/dev/null | head -1 | awk '{print $2}')
    if [[ -n "$SSH_HOST_FROM_CONFIG" ]]; then
        SSH_ENV_LINE="export SSH_HOST_ALIAS=${SSH_HOST_FROM_CONFIG}"
        echo -e "${GREEN}[检测]${NC} SSH Config: SSH_HOST_ALIAS=${SSH_HOST_FROM_CONFIG}"
    fi
fi

# 兜底：检查 WINDOWS_HOST
if [[ -z "$SSH_ENV_LINE" ]] && [[ -n "${WINDOWS_HOST:-}" ]] && [[ -n "${WINDOWS_USER:-}" ]]; then
    SSH_ENV_LINE="export WINDOWS_HOST=${WINDOWS_HOST} WINDOWS_USER=${WINDOWS_USER}"
    echo -e "${GREEN}[检测]${NC} 当前 Shell: WINDOWS_HOST=${WINDOWS_HOST}"
fi

# ────────────────── 3. 写入 Shell 配置文件 ──────────────────
SHELL_RC=""
if [[ -f "$HOME/.bashrc" ]]; then
    SHELL_RC="$HOME/.bashrc"
elif [[ -f "$HOME/.zshrc" ]]; then
    SHELL_RC="$HOME/.zshrc"
fi

if [[ -n "$SSH_ENV_LINE" ]] && [[ -n "$SHELL_RC" ]]; then
    if grep -qF "$SSH_ENV_LINE" "$SHELL_RC" 2>/dev/null; then
        echo -e "${GREEN}[OK]${NC} ${SHELL_RC} 已包含连接配置，跳过"
    else
        echo "" >> "$SHELL_RC"
        echo "# windows-remote SSH 连接配置（由 install.sh 添加）" >> "$SHELL_RC"
        echo "$SSH_ENV_LINE" >> "$SHELL_RC"
        echo -e "${GREEN}[OK]${NC} 已写入 ${SHELL_RC}:"
        echo "    ${SSH_ENV_LINE}"
    fi
elif [[ -z "$SSH_ENV_LINE" ]]; then
    echo ""
    echo -e "${YELLOW}[!]${NC} 未检测到 SSH 连接配置，请手动设置以下之一："
    echo "  1. export SSH_HOST_ALIAS=<~/.ssh/config 中的 Host 别名>"
    echo "  2. export WINDOWS_HOST=... WINDOWS_USER=..."
fi

# ────────────────── 4. 检查 PATH ──────────────────
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo -e "${YELLOW}注意：${NC}${INSTALL_DIR} 不在 PATH 中"
    if [[ -n "$SHELL_RC" ]]; then
        if ! grep -qF 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_RC" 2>/dev/null; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
            echo -e "${GREEN}[OK]${NC} 已添加 PATH 到 ${SHELL_RC}"
        fi
    fi
fi

# ────────────────── 5. 收尾 ──────────────────
echo ""
echo -e "${GREEN}安装完成！${NC}执行以下命令使配置生效:"
echo -e "  ${YELLOW}source ${SHELL_RC:-~/.bashrc}${NC}"
echo ""
echo "使用示例:"
echo "  rmt-adb devices"
echo "  rmt-adb push ~/app.apk /sdcard/app.apk"
echo "  rmt-fastboot devices"
echo "  rmt-fastboot flash boot ~/boot.img"
echo "  rmt-uart list"
echo "  rmt-uart send COM3 \"AT\""
echo "  rmt-uart start COM3"
