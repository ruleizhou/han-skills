"""串口日志记录器 — Windows 端运行

通过 SSH 远程启动，持续读取 COM 口数据写入日志文件，
同时通过 cmd.txt/response.txt 接受命令。

用法: python serial_logger.py <port> <baud> <log_file> <pid_file> <cmd_file> <resp_file>
"""

import sys
import os
import time

import serial


def main():
    if len(sys.argv) < 7:
        print(f"用法: {sys.argv[0]} <port> <baud> <log_file> <pid_file> <cmd_file> <resp_file>")
        sys.exit(1)

    port, baud_str, log_file, pid_file, cmd_file, resp_file = sys.argv[1:7]
    baud = int(baud_str)

    # 写入 PID
    with open(pid_file, "w") as f:
        f.write(str(os.getpid()))

    # 打开串口
    try:
        ser = serial.Serial(port, baud, timeout=0.1)
        ser.dtr = True
        ser.rts = True
    except serial.SerialException as e:
        with open(log_file, "w", encoding="utf-8") as f:
            f.write(f"ERROR: Failed to open {port}: {e}\n")
        try:
            os.remove(pid_file)
        except OSError:
            pass
        sys.exit(1)

    # 主循环
    with open(log_file, "a", encoding="utf-8", buffering=1) as log:
        log.write(f"[{time.strftime('%H:%M:%S')}] 串口管理进程启动 PID:{os.getpid()}\n")
        log.flush()

        try:
            while ser.is_open:
                # 1. 读串口数据 -> 写日志
                data = ser.read(4096)
                if data:
                    log.write(data.decode("utf-8", errors="replace"))
                    log.flush()

                # 2. 处理命令文件
                if os.path.exists(cmd_file):
                    try:
                        with open(cmd_file, "r", encoding="utf-8") as cf:
                            content = cf.read().strip()
                        os.remove(cmd_file)
                    except (FileNotFoundError, PermissionError):
                        continue

                    if not content:
                        continue

                    lines = content.split("\n")
                    cmd = lines[0].strip()
                    cmd_timeout = (
                        int(lines[1].strip())
                        if len(lines) > 1 and lines[1].strip().isdigit()
                        else 3
                    )

                    if cmd and cmd_timeout > 0:
                        ser.write((cmd + "\r\n").encode())
                        resp = b""
                        deadline = time.time() + cmd_timeout
                        while time.time() < deadline:
                            time.sleep(0.1)
                            chunk = ser.read(4096)
                            if chunk:
                                resp += chunk
                                log.write(chunk.decode("utf-8", errors="replace"))
                                log.flush()
                        with open(resp_file, "w", encoding="utf-8") as rf:
                            rf.write(resp.decode("utf-8", errors="replace"))
                    elif cmd:
                        ser.write((cmd + "\r\n").encode())

        except Exception as e:
            log.write(f"\n[{time.strftime('%H:%M:%S')}] Error: {e}\n")

    ser.close()
    try:
        os.remove(pid_file)
    except OSError:
        pass


if __name__ == "__main__":
    main()
