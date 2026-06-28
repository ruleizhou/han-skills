"""Windows 远程控制 MCP Server

通过 SSH 连接局域网内的 Windows PC，远程执行 adb/fastboot 等命令。
优先使用 ~/.ssh/config 中的 Host 配置（免密登录更可靠），环境变量做兜底。
"""

import os
import time
import hashlib
import asyncio

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("windows-remote")

# SSH 连接模式：优先用 SSH config 中的 Host 别名，其次用环境变量拼参数
SSH_HOST_ALIAS = os.environ.get("SSH_HOST_ALIAS", "")  # 如 "winpc"
WINDOWS_HOST = os.environ.get("WINDOWS_HOST", "")
WINDOWS_USER = os.environ.get("WINDOWS_USER", "")
WINDOWS_PORT = int(os.environ.get("WINDOWS_PORT", "22"))
WINDOWS_KEY_PATH = os.environ.get(
    "WINDOWS_KEY_PATH", os.path.expanduser("~/.ssh/id_ed25519")
)


def _get_ssh_target() -> tuple[list[str], str | None]:
    """返回 (ssh 命令前缀参数, 错误信息)"""
    # 优先使用 SSH config 中的 Host 别名（免密登录最可靠）
    if SSH_HOST_ALIAS:
        return [
            "ssh",
            "-o", "StrictHostKeyChecking=no",
            "-o", "ConnectTimeout=10",
            SSH_HOST_ALIAS,
        ], None
    # 兜底：用环境变量拼参数
    if not WINDOWS_HOST:
        return [], "错误：未配置连接信息。请设置 SSH_HOST_ALIAS 或 WINDOWS_HOST 环境变量"
    if not WINDOWS_USER:
        return [], "错误：未配置 WINDOWS_USER"
    return [
        "ssh",
        "-o", "StrictHostKeyChecking=no",
        "-o", "ConnectTimeout=10",
        "-o", "ServerAliveInterval=30",
        "-i", os.path.expanduser(WINDOWS_KEY_PATH),
        "-p", str(WINDOWS_PORT),
        f"{WINDOWS_USER}@{WINDOWS_HOST}",
    ], None


def _config_missing() -> str | None:
    """检查必要配置是否存在"""
    _, err = _get_ssh_target()
    return err


async def _ssh_exec(cmd: str, timeout: int = 30, tty: bool = False) -> str:
    """底层 SSH 执行，调用系统 ssh 命令。tty=True 时分配伪终端。"""
    ssh_prefix, err = _get_ssh_target()
    if err:
        return err
    if tty:
        # 在 ssh 后插入 -t 以分配伪终端，使终端程序（如 ls）输出原生格式
        ssh_cmd = [ssh_prefix[0], "-t"] + ssh_prefix[1:] + [cmd]
    else:
        ssh_cmd = ssh_prefix + [cmd]
    try:
        proc = await asyncio.create_subprocess_exec(
            *ssh_cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, stderr = await asyncio.wait_for(
            proc.communicate(), timeout=timeout + 10
        )
    except asyncio.TimeoutError:
        return f"错误：命令超时（{timeout}s）"

    result = stdout.decode("utf-8", errors="replace")
    if tty:
        # TTY 输出使用 \r\n 换行，统一转为 \n
        result = result.replace("\r\n", "\n").replace("\r", "\n")
    result = result.strip()
    err_text = stderr.decode("utf-8", errors="replace").strip()

    if proc.returncode != 0:
        return f"错误 (exit {proc.returncode}): {err_text}\n{result}" if result else f"错误 (exit {proc.returncode}): {err_text}"
    return result


@mcp.tool()
async def exec_command(cmd: str, timeout: int = 30) -> str:
    """在 Windows 远程 PC 上执行任意命令。返回命令输出或错误信息。"""
    if err := _config_missing():
        return err
    return await _ssh_exec(cmd, timeout)


@mcp.tool()
async def adb(args: str, timeout: int = 30) -> str:
    """在 Windows 远程 PC 上执行 adb 命令。
    args 为 adb 后面的参数，如 'devices'、'shell ls'、'install app.apk'。"""
    if err := _config_missing():
        return err

    # adb shell 不带命令时，交互式 shell 会挂起等待输入。
    # 改为快速验证连接并显示设备提示符信息。
    if args.strip() == "shell":
        return await _ssh_exec(
            'adb shell "echo \\$ && pwd"', timeout
        )

    # adb shell 后跟命令时，使用 -tt 强制分配 PTY 以获取原生终端输出格式
    #   - ls 多列显示（-tt 让 Android 侧 shell 检测到 TTY，ls 自动切换多列模式）
    #   - 其他交互式命令的格式保真
    if args.startswith("shell "):
        return await _ssh_exec(f"adb shell -tt {args[6:]}", timeout)

    return await _ssh_exec(f"adb {args}", timeout)


@mcp.tool()
async def fastboot(args: str, timeout: int = 30) -> str:
    """在 Windows 远程 PC 上执行 fastboot 命令。
    args 为 fastboot 后面的参数，如 'devices'、'flash boot boot.img'。"""
    if err := _config_missing():
        return err
    return await _ssh_exec(f"fastboot {args}", timeout)


@mcp.tool()
async def check_connection() -> str:
    """测试与 Windows 远程 PC 的 SSH 连通性，返回连接状态。"""
    if err := _config_missing():
        return err
    try:
        result = await _ssh_exec("echo CONNECTION_OK", timeout=10)
        if "CONNECTION_OK" in result:
            return f"连接正常 ✓\n主机: {WINDOWS_USER}@{WINDOWS_HOST}:{WINDOWS_PORT}"
        return f"连接异常: {result}"
    except Exception as e:
        return f"连接失败: {e}"


@mcp.tool()
async def list_devices() -> str:
    """列出 Windows 远程 PC 上所有 adb 和 fastboot 设备。"""
    if err := _config_missing():
        return err
    adb_out = await _ssh_exec("adb devices", 10)
    fb_out = await _ssh_exec("fastboot devices", 10)
    return f"【ADB 设备】\n{adb_out}\n\n【Fastboot 设备】\n{fb_out}"


# ──────────────────────────────────────
# 文件传输 + adb push / fastboot flash
# ──────────────────────────────────────

WINDOWS_TEMP_DIR = "C:\\Temp\\windows-remote"


def _local_sha256(local_path: str) -> str:
    h = hashlib.sha256()
    with open(local_path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest().upper()


async def _remote_sha256(remote_path: str) -> str:
    ps = (
        "powershell -Command \""
        "(Get-FileHash -Path '" + remote_path + "' -Algorithm SHA256).Hash"
        "\""
    )
    result = await _ssh_exec(ps, 15)
    return result.strip().upper()


async def _remote_file_exists(remote_path: str) -> bool:
    """检查 Windows 远程文件是否存在"""
    ps = (
        "powershell -Command \""
        "if (Test-Path '" + remote_path + "') { Write-Host 'EXISTS' } else { Write-Host 'NOT_FOUND' }"
        "\""
    )
    result = await _ssh_exec(ps, 10)
    return "EXISTS" in result


async def _remote_file_size(remote_path: str) -> int:
    """获取 Windows 远程文件大小（字节），失败返回 -1"""
    ps = (
        "powershell -Command \""
        "if (Test-Path '" + remote_path + "') { (Get-Item '" + remote_path + "').Length } else { Write-Host '-1' }"
        "\""
    )
    result = await _ssh_exec(ps, 10)
    try:
        return int(result.strip())
    except ValueError:
        return -1


async def _remote_delete(remote_path: str) -> str:
    """删除 Windows 远程临时文件"""
    return await _ssh_exec(
        "powershell -Command \"Remove-Item '" + remote_path + "' -Force -ErrorAction SilentlyContinue\"",
        10,
    )


def _build_scp_cmd(local_path: str, remote_path: str) -> tuple[list[str], str | None]:
    """构造 SCP 上传命令，返回 (scp 命令参数列表, 错误信息)"""
    ssh_prefix, err = _get_ssh_target()
    if err:
        return [], err
    # ssh_prefix 最后一个元素是 host_alias 或 user@host，其余是选项
    host = ssh_prefix[-1]
    opts = ssh_prefix[1:-1]  # 跳过 "ssh" 和 host
    # SSH 用 -p 指定端口，SCP 用 -P
    scp_opts = []
    i = 0
    while i < len(opts):
        if opts[i] == "-p" and i + 1 < len(opts):
            scp_opts.extend(["-P", opts[i + 1]])
            i += 2
        else:
            scp_opts.append(opts[i])
            i += 1
    scp_cmd = ["scp"] + scp_opts + [local_path, f"{host}:{remote_path}"]
    return scp_cmd, None


async def _scp_upload(local_path: str, remote_path: str, timeout: int = 120) -> str:
    """通过 SCP 上传本地文件到 Windows PC，返回成功信息或错误"""
    if not os.path.exists(local_path):
        return f"错误：本地文件不存在: {local_path}"
    scp_cmd, err = _build_scp_cmd(local_path, remote_path)
    if err:
        return err
    try:
        proc = await asyncio.create_subprocess_exec(
            *scp_cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=timeout + 30)
    except asyncio.TimeoutError:
        return f"错误：SCP 传输超时（{timeout}s）"
    if proc.returncode != 0:
        err_msg = stderr.decode("utf-8", errors="replace").strip()
        return f"错误：SCP 传输失败 (exit {proc.returncode}): {err_msg}"

    # 完整性验证
    local_hash = _local_sha256(local_path)
    remote_hash = await _remote_sha256(remote_path)
    if "错误" in remote_hash:
        return f"错误：SCP 上传后无法获取远程文件哈希: {remote_hash}"
    if local_hash != remote_hash:
        return (
            f"错误：SCP 上传完整性验证失败\n"
            f"  本地 SHA256: {local_hash}\n"
            f"  远程 SHA256: {remote_hash}"
        )

    size_mb = os.path.getsize(local_path) / (1024 * 1024)
    return f"SCP 上传成功: {local_path} → {remote_path} ({size_mb:.1f}MB, SHA256: {local_hash[:16]}...)"


def _build_scp_download_cmd(remote_path: str, local_path: str) -> tuple[list[str], str | None]:
    """构造 SCP 下载命令（Windows → Linux），返回 (scp 命令参数列表, 错误信息)

    Windows OpenSSH SCP 要求路径使用正斜杠，这里自动将反斜杠转换。
    """
    ssh_prefix, err = _get_ssh_target()
    if err:
        return [], err
    host = ssh_prefix[-1]
    opts = ssh_prefix[1:-1]
    # SSH 用 -p，SCP 用 -P
    scp_opts = []
    i = 0
    while i < len(opts):
        if opts[i] == "-p" and i + 1 < len(opts):
            scp_opts.extend(["-P", opts[i + 1]])
            i += 2
        else:
            scp_opts.append(opts[i])
            i += 1
    # Windows OpenSSH SCP 要求正斜杠
    remote_path_fixed = remote_path.replace("\\", "/")
    scp_cmd = ["scp"] + scp_opts + [f"{host}:{remote_path_fixed}", local_path]
    return scp_cmd, None


async def _scp_download(remote_path: str, local_path: str, timeout: int = 120) -> str:
    """通过 SCP 从 Windows PC 下载文件到本地，返回成功信息或错误"""
    # 确保本地父目录存在
    local_dir = os.path.dirname(local_path)
    if local_dir:
        os.makedirs(local_dir, exist_ok=True)

    # 检查远程文件是否存在
    if not await _remote_file_exists(remote_path):
        return f"错误：远程文件不存在: {remote_path}"

    # 获取远程文件哈希（下载前）
    remote_hash = await _remote_sha256(remote_path)
    if "错误" in remote_hash:
        return f"错误：无法获取远程文件哈希: {remote_hash}"

    remote_size = await _remote_file_size(remote_path)

    # 执行 SCP 下载
    scp_cmd, err = _build_scp_download_cmd(remote_path, local_path)
    if err:
        return err
    try:
        proc = await asyncio.create_subprocess_exec(
            *scp_cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=timeout + 30)
    except asyncio.TimeoutError:
        return f"错误：SCP 下载超时（{timeout}s）"
    if proc.returncode != 0:
        err_msg = stderr.decode("utf-8", errors="replace").strip()
        return f"错误：SCP 下载失败 (exit {proc.returncode}): {err_msg}"

    # 完整性验证
    local_hash = _local_sha256(local_path)
    if local_hash != remote_hash:
        return (
            f"错误：SCP 下载完整性验证失败\n"
            f"  远程 SHA256: {remote_hash}\n"
            f"  本地 SHA256: {local_hash}"
        )

    size_mb = (remote_size or os.path.getsize(local_path)) / (1024 * 1024)
    return f"SCP 下载成功: {remote_path} → {local_path} ({size_mb:.1f}MB, SHA256: {local_hash[:16]}...)"


async def _ensure_windows_temp_dir() -> str | None:
    """确保 Windows 临时目录存在，返回错误信息或 None"""
    return await _ssh_exec(
        "powershell -Command \"New-Item -Path '"
        + WINDOWS_TEMP_DIR
        + "' -ItemType Directory -Force | Out-Null\"",
        10,
    )


@mcp.tool()
async def adb_push(local_path: str, device_path: str, timeout: int = 120) -> str:
    """将本地 Linux 文件 push 到 Android 设备。
    自动完成：SCP 上传到 Windows → adb push 到设备。
    local_path: 本地文件路径，如 '/home/user/file.apk'
    device_path: 设备目标路径，如 '/sdcard/file.apk'
    timeout: SCP 传输超时秒数，默认 120"""
    if err := _config_missing():
        return err
    filename = os.path.basename(local_path)
    win_path = WINDOWS_TEMP_DIR + "\\" + filename

    # 确保临时目录存在
    await _ensure_windows_temp_dir()

    # SCP 上传
    result = await _scp_upload(local_path, win_path, timeout)
    if "错误" in result:
        return result

    # adb push
    push_result = await _ssh_exec(f"adb push \"{win_path}\" \"{device_path}\"", timeout)
    if "错误" in push_result:
        return f"{result}\n{push_result}"
    return f"{result}\nadb push: {push_result}"


@mcp.tool()
async def adb_pull(device_path: str, local_path: str, timeout: int = 120) -> str:
    """将 Android 设备上的文件 pull 到本地 Linux。
    自动完成：adb pull 到 Windows 临时目录 → SCP 下载到本地 → 清理 Windows 临时文件。
    device_path: 设备上的文件路径，如 '/sdcard/file.txt'
    local_path: 本地目标路径，如 '/home/user/file.txt'
    timeout: SCP 下载超时秒数，默认 120"""
    if err := _config_missing():
        return err
    filename = os.path.basename(device_path)
    win_path = WINDOWS_TEMP_DIR + "\\pulled_" + filename

    # 确保临时目录存在
    await _ensure_windows_temp_dir()

    # adb pull 到 Windows 临时目录
    pull_result = await _ssh_exec(f"adb pull \"{device_path}\" \"{win_path}\"", timeout)
    if "错误" in pull_result:
        return f"adb pull 失败: {pull_result}"

    # SCP 下载到本地
    result = await _scp_download(win_path, local_path, timeout)
    if "错误" in result:
        return f"adb pull: {pull_result}\n{result}"

    # 清理 Windows 临时文件
    await _remote_delete(win_path)

    return f"adb pull: {pull_result}\n{result}"


@mcp.tool()
async def fastboot_flash(partition: str, local_path: str, timeout: int = 120) -> str:
    """将本地 Linux 镜像文件 flash 到设备分区。
    自动完成：SCP 上传到 Windows → fastboot flash。
    partition: 分区名，如 'boot'、'system'、'vbmeta'
    local_path: 本地镜像文件路径，如 '/home/user/boot.img'
    timeout: SCP 传输超时秒数，默认 120"""
    if err := _config_missing():
        return err
    filename = os.path.basename(local_path)
    win_path = WINDOWS_TEMP_DIR + "\\" + filename

    # 确保临时目录存在
    await _ensure_windows_temp_dir()

    # SCP 上传
    result = await _scp_upload(local_path, win_path, timeout)
    if "错误" in result:
        return result

    # fastboot flash
    flash_result = await _ssh_exec(
        f"fastboot flash {partition} \"{win_path}\"", timeout
    )
    if "错误" in flash_result:
        return f"{result}\n{flash_result}"
    return f"{result}\nfastboot flash {partition}: {flash_result}"


# ──────────────────────────────────────
# 串口 (UART) 操作工具
# 利用 Python + pyserial 在 Windows 端持续捕获，通过 SSH 远程管理
# Windows 前置条件: pip install pyserial
# ──────────────────────────────────────

SERIAL_CAPTURE_DIR = "C:\\Temp"


def _serial_work_dir(port: str) -> str:
    """串口工作目录（每个端口独立目录）"""
    return SERIAL_CAPTURE_DIR + "\\serial_" + port


def _serial_manager_pid_file(port: str) -> str:
    """管理进程 PID 文件路径"""
    return _serial_work_dir(port) + "\\manager.pid"


def _serial_log_file(port: str) -> str:
    """捕获日志文件路径"""
    return _serial_work_dir(port) + "\\capture.log"


async def _serial_current_log_file(port: str) -> str:
    """从 current.txt 读取当前活跃日志路径，不存在则 fallback 到 capture.log"""
    pointer = _serial_work_dir(port) + "\\current.txt"
    ps = (
        "if (Test-Path '" + pointer + "') { "
        "Get-Content '" + pointer + "' -Raw "
        "} else { Write-Host 'NONE' }"
    )
    result = await _ssh_exec("powershell -Command \"" + ps + "\"", 5)
    path = result.strip()
    return path if path and path != "NONE" else _serial_log_file(port)


async def _serial_manager_running(port: str) -> bool:
    """检查管理进程是否存活（读 PID 文件 → 检查进程是否存在）"""
    pid_file = _serial_manager_pid_file(port)
    ps = (
        "if (Test-Path '" + pid_file + "') { "
        "$mpid = (Get-Content '" + pid_file + "').Trim(); "
        "$proc = Get-Process -Id $mpid -ErrorAction SilentlyContinue; "
        "if ($proc) { Write-Host 'ALIVE' } else { Write-Host 'DEAD' } "
        "} else { Write-Host 'NONE' }"
    )
    result = await _ssh_exec("powershell -Command \"" + ps + "\"", 10)
    return "ALIVE" in result


async def _ensure_port_available(port: str, baudrate: int = 115200) -> str | None:
    """尝试打开串口确认可用，返回 None 表示可用，否则返回错误信息"""
    ps = (
        "try { "
        "$p = New-Object System.IO.Ports.SerialPort('" + port + "', " + str(baudrate) + "); "
        "$p.Open(); $p.Close(); Write-Host 'PORT_OK' "
        "} catch { Write-Host ('PORT_BUSY: ' + $_.Exception.Message) }"
    )
    result = await _ssh_exec("powershell -Command \"" + ps + "\"", 10)
    if "PORT_OK" in result:
        return None
    return result


async def _kill_orphan_serial_processes(port: str) -> None:
    """强制停止管理进程及可能持有串口的残留进程（兼容 python/powershell 两种管理进程）"""
    pid_file = _serial_manager_pid_file(port)
    work_dir = _serial_work_dir(port)
    # 1. 停止已知的管理进程
    stop_ps = (
        "if (Test-Path '" + pid_file + "') { "
        "$mpid = (Get-Content '" + pid_file + "').Trim(); "
        "Stop-Process -Id $mpid -Force -ErrorAction SilentlyContinue; "
        "Remove-Item '" + pid_file + "' -Force -ErrorAction SilentlyContinue "
        "}"
    )
    await _ssh_exec("powershell -Command \"" + stop_ps + "\"", 10)
    await asyncio.sleep(1)
    # 2. 如果端口仍被占，兜底杀残留进程（匹配 python/powershell 两种管理进程）
    if await _ensure_port_available(port):
        kill_cmd = (
            "Get-CimInstance Win32_Process -Filter \"Name='python.exe' OR Name='powershell.exe'\" | "
            "Where-Object { $_.CommandLine -like '*" + work_dir + "*' } | "
            "ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"
        )
        await _ssh_exec("powershell -Command \"" + kill_cmd + "\"", 10)
        await asyncio.sleep(1)
        if await _ensure_port_available(port):
            kill_pattern = (
                "Get-CimInstance Win32_Process -Filter \"Name='python.exe' OR Name='powershell.exe'\" | "
                "Where-Object { $_.CommandLine -match 'serial_logger|manager\\.ps1|capture_loop\\.ps1' } | "
                "ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"
            )
            await _ssh_exec("powershell -Command \"" + kill_pattern + "\"", 10)
            await asyncio.sleep(1)


@mcp.tool()
async def list_uart_ports() -> str:
    """列出 Windows 远程 PC 上所有可用的串口（COM 口）及设备信息。"""
    if err := _config_missing():
        return err
    ps = (
        "Write-Host '=== 串口列表 ==='; "
        "[System.IO.Ports.SerialPort]::GetPortNames() | ForEach-Object { Write-Host $_ }; "
        "Write-Host ''; "
        "Write-Host '=== 详细信息 ==='; "
        "Get-CimInstance Win32_SerialPort | "
        "Format-Table DeviceID, Description, Status, MaxBaudRate -AutoSize"
    )
    return await _ssh_exec("powershell -Command \"" + ps + "\"", 15)


@mcp.tool()
async def uart_send(
    port: str,
    command: str,
    baudrate: int = 115200,
    read_timeout: int = 3,
    read_response: bool = True,
    timeout: int = 30,
) -> str:
    """通过 Windows 远程 PC 的串口发送命令，可读取设备响应。
    管理进程运行时通过文件通道委托发送，否则直接打开串口。
    port: COM 口，如 "COM3"
    command: 要发送的命令字符串
    baudrate: 波特率，默认 115200
    read_timeout: 读取响应超时秒数，默认 3
    read_response: 是否读取响应，默认 True
    """
    if err := _config_missing():
        return err

    # ── 管理进程模式：通过 cmd/response 文件通信 ──
    if await _serial_manager_running(port):
        work_dir = _serial_work_dir(port)
        cmd_file = work_dir + "\\cmd.txt"
        resp_file = work_dir + "\\response.txt"

        # 1. 清理旧 response 文件
        await _ssh_exec(
            "powershell -Command \"Remove-Item '" + resp_file + "' -Force -ErrorAction SilentlyContinue\"",
            5,
        )

        # 2. 写命令到 cmd 文件（第一行：命令，第二行：超时秒数）
        safe_cmd = command.replace("'", "''")
        timeout_val = str(read_timeout) if read_response else "0"
        # PowerShell 数组语法写两行内容：命令 + 超时秒数
        ps = (
            "Set-Content -Path '" + cmd_file + "' "
            "-Value @('" + safe_cmd + "', '" + timeout_val + "') -Encoding UTF8 -Force"
        )
        await _ssh_exec("powershell -Command \"" + ps + "\"", 5)

        if not read_response:
            return "已发送命令（管理进程模式，不等待响应）: " + command

        # 3. 轮询 response 文件（每 500ms 检查一次）
        total_wait = read_timeout + 5  # 额外 5 秒缓冲
        elapsed = 0.0
        while elapsed < total_wait:
            await asyncio.sleep(0.5)
            elapsed += 0.5
            check = await _ssh_exec(
                "powershell -Command \"if (Test-Path '" + resp_file
                + "') { 'EXISTS' } else { 'NONE' }\"",
                5,
            )
            if "EXISTS" in check:
                resp = await _ssh_exec(
                    "powershell -Command \"Get-Content '" + resp_file + "' -Raw -Encoding UTF8\"",
                    10,
                )
                await _ssh_exec(
                    "powershell -Command \"Remove-Item '" + resp_file + "' -Force -ErrorAction SilentlyContinue\"",
                    5,
                )
                return "已发送: " + command + "\n响应:\n" + resp.strip()

        return "已发送: " + command + "\n响应: 命令超时（" + str(read_timeout) + "秒）"

    # ── 直接模式：无管理进程时，直接打开串口 ──
    safe_cmd = command.replace("'", "''")
    parts = [
        "try {",
        "  $p = New-Object System.IO.Ports.SerialPort('" + port + "', " + str(baudrate) + ");",
        "  $p.Encoding = [System.Text.Encoding]::UTF8;",
        "  $p.ReadTimeout = " + str(read_timeout * 1000) + ";",
        "  $p.Open();",
        "  $p.WriteLine('" + safe_cmd + "');",
        "  Write-Host '已发送: " + safe_cmd + "';",
    ]
    if read_response:
        parts += [
            "  Start-Sleep -Seconds " + str(read_timeout) + ";",
            "  $r = $p.ReadExisting();",
            "  if ($r) { Write-Host '响应:'; Write-Host $r } else { Write-Host '无响应数据' };",
        ]
    parts += [
        "  $p.Close()",
        "} catch { Write-Host '错误:' $_.Exception.Message }",
    ]
    ps = " ".join(parts)
    return await _ssh_exec("powershell -Command \"" + ps + "\"", timeout)


@mcp.tool()
async def uart_log_start(
    port: str,
    baudrate: int = 115200,
    output_file: str = "",
    timeout: int = 15,
) -> str:
    """在 Windows 远程 PC 上启动串口管理进程，持续捕获数据到日志文件，
    同时接受 uart_send 通过文件通道发来的命令。
    port: COM 口，如 "COM3"
    baudrate: 波特率，默认 115200
    output_file: 日志输出文件路径，默认 C:\\Temp\\serial_<port>\\capture_YYYYMMDD_HHMMSS.log
    返回管理进程 PID 和日志文件路径。"""
    if err := _config_missing():
        return err

    work_dir = _serial_work_dir(port)
    if output_file:
        log_file = output_file
    else:
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        log_file = work_dir + f"\\capture_{timestamp}.log"
    pid_file = _serial_manager_pid_file(port)
    cmd_file = work_dir + "\\cmd.txt"
    resp_file = work_dir + "\\response.txt"

    # 检查是否已有管理进程在运行
    if await _serial_manager_running(port):
        return "管理进程已在运行（端口 " + port + "），如需重启请先 uart_log_stop"

    # 确保串口不被占用，自动清理残留进程
    port_err = await _ensure_port_available(port, baudrate)
    if port_err:
        await _kill_orphan_serial_processes(port)
        port_err = await _ensure_port_available(port, baudrate)
        if port_err:
            return "错误：串口 " + port + " 被占用，无法打开。\n详情: " + port_err

    # 确保工作目录存在
    await _ssh_exec(
        "powershell -Command \"New-Item -Path '" + work_dir + "' -ItemType Directory -Force | Out-Null\"",
        10,
    )

    # 清理旧文件
    for f in [cmd_file, resp_file]:
        await _ssh_exec(
            "powershell -Command \"Remove-Item '" + f + "' -Force -ErrorAction SilentlyContinue\"",
            5,
        )

    # 检查 Python + pyserial 可用性
    check_py = await _ssh_exec("python --version 2>&1", 5)
    if "Python" not in check_py:
        return "错误：Windows 端未安装 Python。请安装 Python 并运行: pip install pyserial\n" + check_py
    check_pys = await _ssh_exec(
        "python -c \"import serial; print('PYSERIAL_OK')\"", 5
    )
    if "PYSERIAL_OK" not in check_pys:
        return "错误：Windows 端未安装 pyserial。请运行: pip install pyserial\n" + check_pys

    # SCP 部署串口日志脚本
    script_file = work_dir + "\\serial_logger.py"
    local_script = os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "scripts", "serial_logger.py"
    )
    if not os.path.exists(local_script):
        return "错误：串口脚本不存在: " + local_script
    scp_result = await _scp_upload(local_script, script_file, 30)
    if "错误" in scp_result:
        return scp_result

    # 用 WMI 创建进程（脱离 SSH session，SSH 断开后进程不受影响）
    # 注：Start-Process 创建的进程属于 SSH session，SSH 断开后会被终止
    cmd_line = (
        "python " + script_file + " " + port + " " + str(baudrate)
        + " " + log_file + " " + pid_file + " " + cmd_file + " " + resp_file
    )
    wmi_ps = (
        "$r = Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList '" + cmd_line + "'; "
        "if ($r.ReturnValue -eq 0) { "
        "  $r.ProcessId | Out-File -FilePath '" + pid_file + "' -Encoding UTF8 -Force; "
        "  Write-Host '串口管理进程已启动'; "
        "  Write-Host ('PID: ' + $r.ProcessId); "
        "  Write-Host ('端口: " + port + "'); "
        "  Write-Host ('波特率: " + str(baudrate) + "'); "
        "  Write-Host ('日志文件: " + log_file + "'); "
        "  Write-Host ('工作目录: " + work_dir + "') "
        "} else { "
        "  Write-Host ('启动失败：WMI 返回码 ' + $r.ReturnValue) "
        "}"
    )
    launch_result = await _ssh_exec(
        "powershell -Command \"" + wmi_ps + "\"", timeout
    )

    # 等待后台进程初始化（最多 5 秒），确认日志文件已创建
    log_ready = False
    for _ in range(10):
        await asyncio.sleep(0.5)
        check = await _ssh_exec(
            "powershell -Command \"if (Test-Path '" + log_file
            + "') { (Get-Item '" + log_file + "').Length } else { 'NONE' }\"",
            5,
        )
        check = check.strip()
        if "NONE" not in check and check.isdigit() and int(check) > 0:
            content = await _ssh_exec(
                "powershell -Command \"Get-Content '" + log_file
                + "' -Raw -Encoding UTF8\"",
                5,
            )
            if "ERROR:" in content:
                return (
                    launch_result
                    + "\n\n⚠ 后台进程启动失败: "
                    + content.strip()
                )
            log_ready = True
            break
    if not log_ready:
        return (
            launch_result
            + "\n\n⚠ 后台进程已启动，但日志文件尚未出现（可能端口已被占用）"
        )

    # 二次确认：等 2 秒后检查进程是否仍存活，防止 manager 悄悄崩溃
    await asyncio.sleep(2)
    if not await _serial_manager_running(port):
        error_tail = await _ssh_exec(
            "powershell -Command \"if (Test-Path '" + log_file
            + "') { Get-Content '" + log_file + "' -Tail 5 -Encoding UTF8 } else { '日志文件不存在' }\"",
            5,
        )
        return (
            launch_result
            + "\n\n⚠ 管理进程启动后异常退出（PID 已不存在），日志尾部:\n"
            + error_tail
        )
    # 写指针文件，供 uart_log_read / uart_log_stop 定位当前日志
    pointer_file = work_dir + "\\current.txt"
    await _ssh_exec(
        "powershell -Command \"Set-Content -Path '" + pointer_file
        + "' -Value '" + log_file + "' -Encoding UTF8\"", 5,
    )
    return launch_result + "\n\n✓ 串口捕获已就绪，日志持续写入中"


@mcp.tool()
async def uart_log_read(
    lines: int = 100,
    port: str = "",
    output_file: str = "",
    timeout: int = 15,
) -> str:
    """读取 Windows 远程 PC 上串口捕获的日志文件。
    lines: 读取最后 N 行，默认 100
    port: COM 口（用于定位默认日志文件），如 "COM3"
    output_file: 日志文件路径（与 port 二选一，output_file 优先）
    """
    if err := _config_missing():
        return err
    if not output_file and port:
        output_file = await _serial_current_log_file(port)
    if not output_file:
        return "错误：请提供 port 或 output_file 参数来定位日志文件"
    ps = (
        "if (Test-Path '" + output_file + "') { "
        "Get-Content '" + output_file + "' -Tail " + str(lines) + " -Encoding UTF8"
        + " } else { Write-Host '日志文件不存在: " + output_file + "' }"
    )
    return await _ssh_exec("powershell -Command \"" + ps + "\"", timeout)


@mcp.tool()
async def uart_log_stop(
    port: str = "",
    pid_file_path: str = "",
    timeout: int = 15,
) -> str:
    """停止 Windows 远程 PC 上的串口管理进程。
    port: COM 口（用于定位管理进程），如 "COM3"
    pid_file_path: PID 文件路径（与 port 二选一，pid_file_path 优先）
    返回最终日志尾部。"""
    if err := _config_missing():
        return err
    if not pid_file_path and port:
        pid_file_path = _serial_manager_pid_file(port)
    if not pid_file_path:
        return "错误：请提供 port 或 pid_file_path 参数来定位管理进程"

    log_file = await _serial_current_log_file(port) if port else ""

    # 停止管理进程
    ps = (
        "if (Test-Path '" + pid_file_path + "') { "
        "$mpid = (Get-Content '" + pid_file_path + "').Trim(); "
        "$proc = Get-Process -Id $mpid -ErrorAction SilentlyContinue; "
        "if ($proc) { Stop-Process -Id $mpid -Force; Write-Host ('已停止管理进程 PID: ' + $mpid) } "
        "else { Write-Host ('进程已不存在 PID: ' + $mpid) }; "
        "Remove-Item '" + pid_file_path + "' -Force "
        "} else { "
        "Write-Host 'PID 文件不存在: " + pid_file_path + "' "
        "}"
    )
    result = await _ssh_exec("powershell -Command \"" + ps + "\"", timeout)

    # 读取最终日志尾部
    if log_file:
        tail_ps = (
            "if (Test-Path '" + log_file + "') { "
            "Write-Host '=== 最终日志（最后 20 行） ==='; "
            "Get-Content '" + log_file + "' -Tail 20 -Encoding UTF8"
            " } else { Write-Host '日志文件不存在' }"
        )
        tail = await _ssh_exec("powershell -Command \"" + tail_ps + "\"", 10)
        result = result + "\n\n" + tail

    return result


if __name__ == "__main__":
    mcp.run()
