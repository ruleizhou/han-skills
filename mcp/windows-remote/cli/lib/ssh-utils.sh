#!/usr/bin/env bash
# 共享 SSH/SCP 配置函数 —— 与 MCP server 配置逻辑一致
# 优先 SSH_HOST_ALIAS（~/.ssh/config Host 别名），兜底 WINDOWS_HOST + WINDOWS_USER

# 输出全局变量：SSH_HOST, SSH_OPTS, SCP_OPTS
# 用法：source 此文件后调用 load_ssh_config

load_ssh_config() {
    if [[ -n "${SSH_HOST_ALIAS:-}" ]]; then
        SSH_HOST="$SSH_HOST_ALIAS"
        SSH_OPTS=(-o StrictHostKeyChecking=no -o ConnectTimeout=10)
        SCP_OPTS=(-o StrictHostKeyChecking=no -o ConnectTimeout=10)
        return 0
    fi

    local host="${WINDOWS_HOST:-}"
    local user="${WINDOWS_USER:-}"
    local port="${WINDOWS_PORT:-22}"
    local key="${WINDOWS_KEY_PATH:-$HOME/.ssh/id_ed25519}"

    if [[ -z "$host" ]] || [[ -z "$user" ]]; then
        echo "错误：未配置连接信息。请设置以下环境变量之一：" >&2
        echo "  1. SSH_HOST_ALIAS（推荐，~/.ssh/config 中的 Host 别名）" >&2
        echo "  2. WINDOWS_HOST + WINDOWS_USER" >&2
        return 1
    fi

    SSH_HOST="${user}@${host}"
    SSH_OPTS=(-o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ServerAliveInterval=30 -i "$key" -p "$port")
    SCP_OPTS=(-o StrictHostKeyChecking=no -o ConnectTimeout=10 -P "$port" -i "$key")
}

ssh_exec() {
    load_ssh_config >/dev/null || return 1
    ssh "${SSH_OPTS[@]}" "$SSH_HOST" "$@"
}

# 交互式 SSH（分配 TTY），用于 adb shell 等需要终端交互的场景
ssh_interactive() {
    load_ssh_config >/dev/null || return 1
    ssh -t "${SSH_OPTS[@]}" "$SSH_HOST" "$@"
}

# 通过 stdin 执行 PowerShell 脚本，避免嵌套引号问题
ps_exec() {
    load_ssh_config >/dev/null || return 1
    ssh "${SSH_OPTS[@]}" "$SSH_HOST" "powershell -Command -"
}

remote_sha256() {
    local remote_path="$1"
    load_ssh_config >/dev/null || return 1
    local result
    result=$(ssh "${SSH_OPTS[@]}" "$SSH_HOST" \
        "powershell -Command \"(Get-FileHash -Path '${remote_path}' -Algorithm SHA256).Hash\"" 2>/dev/null) || {
        echo "错误：无法获取远程文件 SHA256: $remote_path" >&2
        return 1
    }
    echo "${result^^}"
}

scp_upload() {
    local local_path="$1"
    local remote_path="$2"
    load_ssh_config >/dev/null || return 1

    if [[ ! -f "$local_path" ]]; then
        echo "错误：本地文件不存在: $local_path" >&2
        return 1
    fi

    scp "${SCP_OPTS[@]}" "$local_path" "${SSH_HOST}:${remote_path}" || return 1

    # 完整性验证
    local local_hash
    local_hash=$(sha256sum "$local_path" | awk '{print $1}' | tr '[:lower:]' '[:upper:]')
    local remote_hash
    remote_hash=$(remote_sha256 "$remote_path") || return 1
    remote_hash=$(echo "$remote_hash" | tr -d '\r\n' | tr '[:lower:]' '[:upper:]')

    if [[ "$local_hash" != "$remote_hash" ]]; then
        echo "错误：SCP 上传完整性验证失败" >&2
        echo "  本地 SHA256: $local_hash" >&2
        echo "  远程 SHA256: $remote_hash" >&2
        return 1
    fi
    echo "SCP 上传成功 + 完整性验证通过 (SHA256: ${local_hash:0:16}...)"
}

scp_download() {
    local remote_path="$1"
    local local_path="$2"
    load_ssh_config >/dev/null || return 1
    # Windows OpenSSH SCP 要求正斜杠路径
    remote_path="${remote_path//\\//}"
    scp "${SCP_OPTS[@]}" "${SSH_HOST}:${remote_path}" "$local_path"
}
