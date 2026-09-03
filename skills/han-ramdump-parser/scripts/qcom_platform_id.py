#!/usr/bin/env python3
"""从 QPST dump 文件中识别高通 SoC 平台代号（全小写输出）——ramparse --force-hardware 事前确认工具

识别策略（纯二进制搜索，不依赖 strings 命令，数秒级出结果）：
1. Hardware name: 全文件搜索内核日志 "Hardware name: Qualcomm Technologies, Inc. <平台>"
   —— dmesg 权威平台名，优先于此路径；命中即返回
2. DTB compatible: 全文件搜索 FDT magic 收集全部命中，解析 qcom,<platform> compatible
   —— DDR 里有多份 DTB（HLOS/adsp/cdsp），不能首个命中即返回（可能误判为 adsp 代号）
   带 --parser-dir 时与 ramparse board_num 全集取交集消歧（如 parrot 在全集、netrani 不在）

用法:
    python3 qcom_platform_id.py <dump目录> [--parser-dir <linux-ramdump-parser-v2目录>]

已知局限:
    - minidump（md_*.BIN，无 DDR 文件）场景不适用
    - 只认完整 FDT magic（0xd00dfeed 对齐），不处理偏移 FDT
    - --parser-dir 的 boards.py 仅 linux-ramdump-parser-v2 新版（boards.py + board_config/board_def）可用
"""

import argparse
import glob
import os
import re
import struct
import sys

FDT_MAGIC = b'\xd0\x0d\xfe\xed'
HW_NAME_PATTERN = b'Hardware name: Qualcomm Technologies, Inc. '
CHUNK_SIZE = 64 * 1024 ** 2     # 64MB 大块读取，减少 IO 开销

# DTB compatible 中需要过滤的通用名称
GENERIC_NAMES = frozenset({
    'idp', 'qrd', 'mtp', 'cdp', 'hkdk', 'atp', 'rbt', 'soc', 'cpu',
    'gpu', 'i2c', 'spi', 'uart', 'usb', 'pci', 'intc', 'pinctrl',
    'clk', 'reset', 'thermal', 'rpm', 'smp', 'pmic', 'panel', 'dsi',
    'mdp', 'display',
})


def find_ddr_files(dump_dir):
    """完整/reduced dump 的 DDR 镜像文件（按文件名排序）"""
    files = []
    for pat in ('DDR*.BIN', 'EBI*.BIN', 'VMDDR*.BIN'):
        files.extend(glob.glob(os.path.join(dump_dir, pat)))
    files.sort()
    return files


def normalize_platform(raw):
    """将 DTB 提取的原始名规范化为基础平台代号

    parrot-qrd     → parrot
    yupikp-iot-qrd → yupikp → yupik
    khaje-idp      → khaje  → khaje
    bengal-idp     → bengal → bengal
    """
    base = raw.split('-')[0]        # 去掉 -iot, -idp 等板级后缀
    base = re.sub(r'\d+$', '', base)  # 去掉尾部数字 (yupik1 → yupik)
    # 去掉尾部变体字母 (yupikp → yupik, 但保留 len>=4 的如 bengal)
    if len(base) > 4 and base[-1] in 'pPsSlL':
        base = base[:-1]
    return base


def extract_from_dtb(data, pos):
    """从 DTB 数据块中提取平台代号"""
    chunk = data[pos:pos + 4096]
    for m in re.finditer(rb'qcom,([a-z][a-z0-9]+-?[a-z0-9]*)', chunk, re.IGNORECASE):
        raw = m.group(1).decode('ascii', errors='ignore').lower()
        if raw not in GENERIC_NAMES and len(raw) >= 3:
            return normalize_platform(raw)
    return None


def extract_from_hwname(data, pos):
    """从 Hardware name 字符串中提取平台代号"""
    start = pos + len(HW_NAME_PATTERN)
    end = data.find(b' ', start, start + 40)
    if end < 0:
        end = min(start + 30, len(data))
    name = data[start:end].decode('ascii', errors='ignore').strip(' \x00(')
    if name:
        return name.lower()
    return None


def file_platform_candidates(filepath, hw_priority=True):
    """扫单个文件，返回 (hardware_name 平台, dtb 候选列表)

    全文件扫描（不再限制 1GB——实测 dmesg buffer 可到 1.9GB 偏移）。
    """
    hw_name = None
    dtb_candidates = []
    with open(filepath, 'rb') as f:
        offset = 0
        while True:
            f.seek(offset)
            data = f.read(CHUNK_SIZE)
            if not data:
                break

            # Hardware name（优先级最高，命中即可返回；第二遍收 DTB 时不重复搜）
            if hw_priority:
                hw_pos = data.find(HW_NAME_PATTERN)
                if hw_pos >= 0:
                    hw_name = extract_from_hwname(data, hw_pos)
                    if hw_name:
                        return hw_name, dtb_candidates

            # DTB (FDT magic)：收集全部候选
            pos = 0
            while True:
                pos = data.find(FDT_MAGIC, pos)
                if pos < 0:
                    break
                if pos + 40 <= len(data):
                    totalsize = struct.unpack('>I', data[pos + 4:pos + 8])[0]
                    if 10000 < totalsize < 2000000:
                        platform = extract_from_dtb(data, pos)
                        if platform:
                            dtb_candidates.append(platform)
                pos += 4

            offset += CHUNK_SIZE - 4
    return hw_name, dtb_candidates


def load_board_nums(parser_dir):
    """从 ramparse 的 boards.py 取 board_num 全集（--force-hardware 合法值）"""
    try:
        sys.path.insert(0, parser_dir)
        from boards import get_supported_boards
        nums = sorted(set(b.board_num for b in get_supported_boards()))
        sys.path.remove(parser_dir)
        return nums
    except Exception as e:
        if parser_dir in sys.path:
            sys.path.remove(parser_dir)
        print(f'警告: 无法从 {parser_dir} 加载 boards.py ({e})，跳过 board 消歧', file=sys.stderr)
        return None


def detect_platform(dump_dir, parser_dir=None):
    """返回 (platform|None, method, board_nums|None)

    - 成功: platform 为 str（全小写），method 为识别方式
    - 失败: platform 为 None；method 为失败原因串或 DTB 候选列表；board_nums 可能为 None
    """
    ddr_files = find_ddr_files(dump_dir)
    if not ddr_files:
        return None, 'no-ddr-files', None

    board_nums = load_board_nums(parser_dir) if parser_dir else None

    # 第一遍：Hardware name 优先（逐文件，命中即返回）
    for f in ddr_files:
        hw_name, _ = file_platform_candidates(f, hw_priority=True)
        if hw_name:
            return hw_name, 'Hardware name', board_nums

    # 第二遍：DTB 候选收集 + 消歧
    all_dtb = []
    for f in ddr_files:
        _, dtb_cands = file_platform_candidates(f, hw_priority=False)
        all_dtb.extend(dtb_cands)

    candidates = []
    for c in all_dtb:
        if c not in candidates:
            candidates.append(c)

    if board_nums:
        # 候选 ∩ board_num 全集：交集唯一则直出
        intersect = [c for c in candidates if c in board_nums]
        if len(intersect) == 1:
            return intersect[0], 'DTB compatible (board 交集消歧)', board_nums
        if intersect:
            candidates = intersect  # 多个交集项：缩小到交集再列

    if len(candidates) == 1:
        return candidates[0], 'DTB compatible', board_nums
    return None, candidates, board_nums


def main():
    ap = argparse.ArgumentParser(description='识别 QPST dump 的 SoC 平台代号（--force-hardware 参数）')
    ap.add_argument('dump_dir', help='dump 目录（含 DDR*.BIN）')
    ap.add_argument('--parser-dir', help='linux-ramdump-parser-v2 目录，给出时用 board_num 全集消歧')
    args = ap.parse_args()

    if not os.path.isdir(args.dump_dir):
        print(f'错误: 目录不存在: {args.dump_dir}', file=sys.stderr)
        sys.exit(1)

    platform, method, board_nums = detect_platform(args.dump_dir, args.parser_dir)
    if platform:
        print(platform)
        print(f'# 识别方式: {method}', file=sys.stderr)
        sys.exit(0)

    print('无法识别平台代号', file=sys.stderr)
    if method == 'no-ddr-files':
        print('错误: 目录下没有 DDR*.BIN/EBI*.BIN/VMDDR*.BIN（minidump 场景本工具不适用）', file=sys.stderr)
    elif method:
        print(f'DTB 候选: {", ".join(method) if method else "(无)"}', file=sys.stderr)
        if board_nums:
            print(f'board_num 全集 {len(board_nums)} 个，候选均不在其中或交集不唯一', file=sys.stderr)
    sys.exit(1)


if __name__ == '__main__':
    main()
