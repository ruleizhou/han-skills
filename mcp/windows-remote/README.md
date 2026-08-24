# windows-remote

通过 SSH 远程控制局域网内的 Windows PC，执行 `adb`、`fastboot`、串口操作等命令。

适用于：远程服务器（Linux 容器）控制本地 Windows 11 PC 的场景。

## 架构

```
远程容器 (Linux)                         本地 Windows 11
┌─────────────────┐                    ┌──────────────────┐
│  MCP Server     │                    │  OpenSSH Server  │
│  (Claude Code)  │    SSH over LAN    │  + adb.exe       │
│  CLI (rmt-adb)  │ ═══════════════════│  + fastboot.exe  │
└─────────────────┘                    └──────────────────┘
       ↑ 两种使用入口
       ├── Claude Code: MCP 工具（adbd/fastboot 等）
       └── 终端: rmt-adb / rmt-fastboot（shell 脚本）
```

## 快速开始

### 第一步：Windows 端配置

以管理员身份打开 PowerShell，运行：

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\scripts\setup-windows.ps1
```

脚本会自动：安装 OpenSSH Server → 启动服务 → 防火墙放行 → 设置默认 Shell → 检查 adb/fastboot。

### 第二步：远程端配置

```bash
bash scripts/setup-remote.sh <Windows_IP> <Windows用户名>

# 示例
bash scripts/setup-remote.sh 172.16.22.66 zhourulei
```

脚本会自动：生成 SSH 密钥 → 输出公钥 → 写 SSH config → 测试连接。

按提示将公钥添加到 Windows 端的 `C:\Users\<用户名>\.ssh\authorized_keys`。

### 第三步：注册 MCP Server

```bash
claude mcp add windows-remote -s user \
  -e SSH_HOST_ALIAS=winpc \
  -- /usr/local/meig/python/3.10.15/bin/python3 ~/.ai_utils/mcp/windows-remote/server.py
```

> **注意**：必须使用安装了 `mcp` 模块的 Python 路径。可用 `python3 -c "from mcp.server.fastmcp import FastMCP"` 检测。`setup-remote.sh` 会自动检测。

`-s user` 表示全局生效，所有项目可用。验证注册：

```bash
claude mcp list
```

### OpenCode

在 `~/.opencode/mcp.json` 中添加：

```json
{
  "mcpServers": {
    "windows-remote": {
      "command": "python",
      "args": ["/home/<user>/.ai_utils/mcp/windows-remote/server.py"],
      "env": {
        "SSH_HOST_ALIAS": "winpc"
      }
    }
  }
}
```

### Cursor

在 `~/.cursor/mcp.json` 中添加：

```json
{
  "mcpServers": {
    "windows-remote": {
      "command": "python",
      "args": ["/home/<user>/.ai_utils/mcp/windows-remote/server.py"],
      "env": {
        "SSH_HOST_ALIAS": "winpc"
      }
    }
  }
}
```

> `<user>` 替换为实际用户名，`python` 需指向安装了 `mcp` 模块的 Python（可通过 shebang 或绝对路径指定）。

## 终端 CLI 工具

除了 MCP 工具（在 Claude Code 中使用），还提供终端可直接运行的脚本：

```bash
# 安装（自动检测 SSH 配置并写入 ~/.bashrc）
cd ~/.ai_utils/mcp/windows-remote/cli && bash install.sh

# 使用
rmt-adb devices                          # 透传 adb 命令
rmt-adb push ~/app.apk /sdcard/app.apk    # 自动 SCP 上传 + adb push
rmt-fastboot devices                     # 透传 fastboot 命令
rmt-fastboot flash boot ~/boot.img       # 自动 SCP 上传 + fastboot flash
rmt-uart list                            # 列出 COM 口
rmt-uart start COM3                      # 启动后台捕获
rmt-uart send COM3 "AT"                  # 发送串口命令
rmt-uart read COM3                       # 读取捕获日志
rmt-uart upload COM3                     # 下载日志到本地
rmt-uart stop COM3                       # 停止捕获
```

`install.sh` 自动完成：
- 创建 `rmt-adb` / `rmt-fastboot` / `rmt-uart` 符号链接到 `~/.local/bin/`
- 从 MCP 配置或 SSH config 检测连接方式，写入 `~/.bashrc`
- 处理 PATH 配置

`adb push` / `fastboot flash` 需要本地文件 → Windows 中转，流程：`SCP 上传到 C:\Temp\windows-remote\` → `远程执行 adb push / fastboot flash`。其他命令直接透传到 Windows。`rmt-adb` 还支持 `push` 的选项参数，如 `rmt-adb push -p --sync local.apk /sdcard/app.apk`。

`rmt-uart start` 会自动 SCP 部署 `serial_logger.py` 到 Windows 并通过 WMI 启动独立后台进程，SSH 断开后不受影响。`upload` 通过 SCP 下载日志到本地。详细用法执行 `rmt-uart` 查看。

## 提供的工具

| 工具 | 说明 |
|------|------|
| `exec_command` | 在 Windows 上执行任意命令 |
| `adb` | 执行 adb 命令（快捷方式） |
| `adb_push` | 本地文件 push 到设备（自动 SCP + adb push） |
| `fastboot` | 执行 fastboot 命令（快捷方式） |
| `fastboot_flash` | 本地镜像 flash 到分区（自动 SCP + fastboot flash） |
| `check_connection` | 测试 SSH 连通性 |
| `list_devices` | 列出所有 adb + fastboot 设备 |
| `list_uart_ports` | 列出所有可用 COM 口及设备信息 |
| `uart_send` | 通过串口发送命令，读取设备响应 |
| `uart_log_start` | 启动后台进程持续捕获串口日志 |
| `uart_log_read` | 读取捕获的串口日志 |
| `uart_log_stop` | 停止后台串口捕获进程 |

### exec_command

在 Windows 远程 PC 上执行任意命令。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `cmd` | string | 是 | 要执行的命令 |
| `timeout` | int | 否 | 超时秒数，默认 30 |

### adb

在 Windows 远程 PC 上执行 adb 命令。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `args` | string | 是 | adb 后面的参数，如 `devices`、`shell ls` |
| `timeout` | int | 否 | 超时秒数，默认 30 |

### adb_push

将本地 Linux 文件 push 到 Android 设备。自动完成 SCP 上传到 Windows → adb push 到设备。

文件上传到 Windows 临时目录 `C:\Temp\windows-remote\`，同名文件会覆盖（充当缓存）。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `local_path` | string | 是 | 本地文件路径，如 `/home/user/file.apk` |
| `device_path` | string | 是 | 设备目标路径，如 `/sdcard/file.apk` |
| `timeout` | int | 否 | SCP 传输超时秒数，默认 120 |

### fastboot

在 Windows 远程 PC 上执行 fastboot 命令。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `args` | string | 是 | fastboot 后面的参数，如 `devices`、`flash boot boot.img` |
| `timeout` | int | 否 | 超时秒数，默认 30 |

### fastboot_flash

将本地 Linux 镜像文件 flash 到设备分区。自动完成 SCP 上传到 Windows → fastboot flash。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `partition` | string | 是 | 分区名，如 `boot`、`system`、`vbmeta` |
| `local_path` | string | 是 | 本地镜像文件路径，如 `/home/user/boot.img` |
| `timeout` | int | 否 | SCP 传输超时秒数，默认 120 |

### check_connection

测试与 Windows PC 的 SSH 连通性。无参数。

### list_devices

一键查看 Windows 上所有 adb 和 fastboot 设备。无参数。

### list_uart_ports

列出 Windows PC 上所有可用的 COM 口及设备详细信息。无参数。

### uart_send

通过串口发送命令，可选读取设备响应。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `port` | string | 是 | COM 口，如 `COM3` |
| `command` | string | 是 | 要发送的命令字符串 |
| `baudrate` | int | 否 | 波特率，默认 115200 |
| `read_timeout` | int | 否 | 读取响应超时秒数，默认 3 |
| `read_response` | bool | 否 | 是否读取响应，默认 true |

### uart_log_start

启动后台进程持续捕获串口数据到日志文件。使用 Python + pyserial，Windows 端需 `pip install pyserial`。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `port` | string | 是 | COM 口，如 `COM3` |
| `baudrate` | int | 否 | 波特率，默认 115200 |
| `output_file` | string | 否 | 日志文件路径，默认 `C:\Temp\serial_capture_<port>.log` |

后台进程 PID 写入 `C:\Temp\serial_capture_<port>.pid`。

### uart_log_read

读取串口捕获的日志文件。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `lines` | int | 否 | 读取最后 N 行，默认 100 |
| `port` | string | 否 | COM 口（用于定位默认日志文件） |
| `output_file` | string | 否 | 日志文件路径（与 port 二选一，优先） |

### uart_log_stop

停止后台串口捕获进程，返回最终日志尾部。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `port` | string | 否 | COM 口（用于定位 PID 文件） |
| `pid_file_path` | string | 否 | PID 文件路径（与 port 二选一，优先） |

### 串口工具使用示例

```
# 1. 查看可用串口
list_uart_ports()

# 2. 发送 AT 命令并读取响应
uart_send(port="COM3", command="AT", baudrate=115200)

# 3. 启动后台捕获（如抓取内核启动日志）
uart_log_start(port="COM3", baudrate=115200)

# 4. 随时读取最新日志
uart_log_read(port="COM3", lines=50)

# 5. 停止捕获
uart_log_stop(port="COM3")
```

## 环境变量配置

通过 `claude mcp add -e` 注入，不硬编码：

| 变量 | 必填 | 说明 | 示例 |
|------|------|------|------|
| `SSH_HOST_ALIAS` | 推荐 | `~/.ssh/config` 中的 Host 别名，免密更可靠 | `winpc` |
| `WINDOWS_HOST` | 兜底 | Windows 局域网 IP（未设 SSH_HOST_ALIAS 时使用） | `172.16.22.66` |
| `WINDOWS_USER` | 兜底 | Windows 用户名 | `zhourulei` |
| `WINDOWS_PORT` | 兜底 | SSH 端口 | `22`（默认） |
| `WINDOWS_KEY_PATH` | 兜底 | SSH 私钥路径 | `~/.ssh/id_ed25519`（默认） |

## 前提条件

- **Windows 端**：Windows 10/11，OpenSSH Server 已安装并运行
- **远程端**：Linux（容器即可），需有 `ssh` 客户端
- **网络**：同一局域网，远程端能 ping 通 Windows IP
- **工具**：adb / fastboot 已安装并加入 Windows PATH
- **串口捕获**：Windows 端需 Python + pyserial（`pip install pyserial`）

## 常见问题

**Q: 连接失败？**

1. 检查 Windows SSH 服务：`Get-Service sshd`（应为 Running）
2. 检查网络：从远程端 `ping <Windows_IP>`
3. 检查防火墙：`Get-NetFirewallRule -Name *ssh*`
4. 检查密钥：确认公钥已添加到 Windows 的 `authorized_keys`

**Q: adb/fastboot 命令找不到？**

SSH 登录后的 PATH 可能与桌面环境不同。解决方案：

1. 将 adb/fastboot 所在目录加入系统 PATH（不仅仅是用户 PATH）
2. 或在 Windows 端设置默认 Shell 为 PowerShell（setup-windows.ps1 已自动处理）

**Q: 容器网络不通？**

如果容器网络隔离，可能需要：
- 使用 `--network host` 模式运行容器
- 或配置 Docker 端口映射

**Q: 连接超时断开？**

SSH config 已配置 `ServerAliveInterval 60` 保持连接。如仍断开，可在 Windows 端编辑 `C:\ProgramData\ssh\sshd_config` 添加：

```
ClientAliveInterval 60
ClientAliveCountMax 3
```

然后 `Restart-Service sshd`。

## License

MIT
