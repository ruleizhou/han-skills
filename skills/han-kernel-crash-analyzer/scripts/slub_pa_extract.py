#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# slub_pa_extract.py — 从串口 log 提取 SLUB "overwritten" 事件，算 PA，判 DRAM-SEU / CPU-UAF / DMA。
# 对齐 han-kernel-crash-analyzer skill 的 patterns.json ptrn-007 判别法：
#   红区完整 + bit 跨样本一致 + 物理区域聚集 → DRAM SEU（硬件），勿误判为软件越界。
#
# 用法：
#   python3 slub_pa_extract.py <串口log> [<log2> ...] [选项]
#   python3 slub_pa_extract.py 15/crash_dump.txt 15_1/crash_dump.txt
#   python3 slub_pa_extract.py log.txt --va-bits 48 --phys-offset 0x80000000
#   python3 slub_pa_extract.py log.txt --json
#
# 职责边界（references/tool_chain.md 铁律）：本脚本只做"启发式倾向"，对象边界 /
# freelist / slab 健康度 / alloc-free 栈归属归 `crash kmem` / `kmem -s`。
# PA 换算走 linear map，不受 KASLR 影响（Kernel Offset 是 text 的）。

import re
import argparse
import json

# ---- 默认平台常量（SM6115 / VA_BITS=39，可被命令行覆盖）----
PAGE_OFFSET_BY_VABITS = {39: 0xffffff8000000000, 48: 0xffff000000000000}
DEFAULT_PHYS_OFFSET = 0x40000000
DEFAULT_DMA_REGIONS = [
    ("swiotlb",   0xe6800000, 0xe6c00000),
    ("audio_cma", 0xec800000, 0xee400000),
    ("linux_cma", 0xf0000000, 0xf2000000),
]

# ---- SLUB 报告正则（内核标准格式，跨平台通用）----
BUG_RE     = re.compile(r"BUG (\S+).*?\): (\S.*?overwritten)")
FAULT_RE   = re.compile(r"(0x[0-9a-f]+)-0x[0-9a-f]+ @offset=(\d+)\. First byte (0x[0-9a-f]+) instead of (0x[0-9a-f]+)")
SLAB_RE    = re.compile(r"Slab \S+ objects=(\d+) used=(\d+)")
OBJ_RE     = re.compile(r"Object (0x[0-9a-f]+) @offset=(\d+)")
ALLOC_RE   = re.compile(r"Allocated in (\S+) .*?age=(\d+) cpu=(\d+) pid=(\d+)")
FREE_RE    = re.compile(r"Freed in (\S+) .*?age=(\d+) cpu=(\d+) pid=(\d+)")
REDZONE_RE = re.compile(r"Redzone\s+[0-9a-f]+:\s+([0-9a-f]{2}(?:\s[0-9a-f]{2})*)")


def va_to_pa(va, page_offset, phys_offset):
    return (va - page_offset) + phys_offset


def in_dma(pa, dma_regions):
    for name, lo, hi in dma_regions:
        if lo <= pa < hi:
            return name
    return None


def bit_diff(good, bad):
    g, b = int(good, 16), int(bad, 16)
    d = g ^ b
    return d, bin(d).count("1")


def parse(path, page_offset, phys_offset, dma_regions):
    events = []
    with open(path, errors="replace") as f:
        lines = f.readlines()
    i, n = 0, len(lines)
    while i < n:
        if "overwritten" in lines[i] and "BUG" in lines[i]:
            ev = {"file": path, "redzone_ok": True, "redzone_seen": False}
            m = BUG_RE.search(lines[i])
            if m:
                ev["cache"], ev["what"] = m.group(1), m.group(2)
            bad_hex = None
            j = i
            for j in range(i, min(i + 250, n)):   # 窗口需覆盖长 padding dump(可达 ~200 行)
                fl = lines[j]
                if "fault_va" not in ev:
                    fm = FAULT_RE.search(fl)
                    if fm:
                        ev["fault_va"]  = int(fm.group(1), 16)
                        ev["offset"]    = int(fm.group(2))
                        ev["bad_byte"]  = fm.group(3)
                        ev["good_byte"] = fm.group(4)
                        bad_hex = fm.group(3)[2:]            # "0x58" -> "58"
                if "slab" not in ev:
                    sm = SLAB_RE.search(fl)
                    if sm:
                        ev["slab"] = "objects=%s used=%s" % (sm.group(1), sm.group(2))
                if "obj_va" not in ev:
                    om = OBJ_RE.search(fl)
                    if om:
                        ev["obj_va"] = om.group(1)
                if "alloc" not in ev:
                    am = ALLOC_RE.search(fl)
                    if am:
                        ev["alloc"] = "%s pid=%s cpu=%s age=%s" % (am.group(1), am.group(4), am.group(3), am.group(2))
                if "free" not in ev:
                    frm = FREE_RE.search(fl)
                    if frm:
                        ev["free"] = "%s pid=%s cpu=%s age=%s" % (frm.group(1), frm.group(4), frm.group(3), frm.group(2))
                # 红区完整性：Redzone 行任一字节非 0xbb → 红区被踩
                rm = REDZONE_RE.search(fl)
                if rm:
                    ev["redzone_seen"] = True
                    bs = rm.group(1).split()
                    if any(b != "bb" for b in bs):
                        ev["redzone_ok"] = False
                # dump 行：在 "ADDR: " 后的 hex 字节里找 bad_hex（修原版 "58" 硬编码 + 排除时间戳误匹配）
                if "dump_row" not in ev and bad_hex and ("Padding " in fl or "Object  " in fl):
                    hm = re.search(r":\s+([0-9a-f]{2}(?:\s[0-9a-f]{2})*)", fl)
                    if hm and bad_hex in hm.group(1).split():
                        ev["dump_row"] = fl.strip()
            if "fault_va" in ev:
                ev["pa"] = va_to_pa(ev["fault_va"], page_offset, phys_offset)
                ev["dma_region"] = in_dma(ev["pa"], dma_regions)
                ev["xor"], ev["bit_count"] = bit_diff(ev["good_byte"], ev["bad_byte"])
                ev["crash_kmem_required"] = True
                events.append(ev)
            i = j + 1
        else:
            i += 1
    return events


def is_clustered(pas, block_size=0x8000):
    """区域聚集：所有 PA 落在同一 block_size(默认 32KB ≈ 一个 slab page) 对齐块内。"""
    if len(pas) < 2:
        return False
    return len(set(p // block_size for p in pas)) == 1


# TODO(human): classify(events) —— 综合 verdict（核心设计决策，对齐 ptrn-007）
def classify(events):
    """综合 红区完整性 / bit 一致性 / 区域聚集 / DMA 区，输出 (verdict, confidence)。

    判别矩阵（对齐 patterns.json ptrn-007）：
      - 任一事件红区被踩(非0xbb)         → CPU 越界/UAF（软件）
      - 红区全完整 + bit 一致 + 区域聚集   → DRAM SEU/位线（硬件，强）
      - 红区全完整 + bit 一致 + 不聚集     → DRAM SEU（位线跨区）
      - 红区全完整 + bit 不一致            → 信息不足，攒更多样本
      - 任一 PA 落 DMA 区                  → DMA stray write（红区完整时才考虑）
      - 仅 1 个事件                        → 需 ≥2 事件才能判一致性

    字段访问提示：
      - 红区被踩：any(not e.get("redzone_ok", True) for e in events)
      - bit 一致：len(set(e["xor"] for e in events)) == 1
      - 区域聚集：is_clustered([e["pa"] for e in events])
      - DMA：     any(e.get("dma_region") for e in events)
    返回 (verdict_str, confidence_str)；未实现时返回 None。
    """
    if len(events) < 2:
        return ("需 ≥2 个事件才能判 bit 一致性/区域聚集 — 继续压测攒样本", "低(样本不足)")

    redzone_corrupt = any(not e.get("redzone_ok", True) for e in events)
    xor_consistent = len(set(e["xor"] for e in events)) == 1
    clustered = is_clustered([e["pa"] for e in events])
    in_dma_region = any(e.get("dma_region") for e in events)

    # ① 红区被踩 → CPU 软件越界/UAF（最强反证，优先级最高）
    if redzone_corrupt:
        return ("CPU 越界/UAF（软件嫌疑）— 红区被踩符合线性越界；用 KASAN_GENERIC 抓 writer",
                "中(需 KASAN 定位 writer)")

    # 红区全完整 → 排除 CPU 线性越界，往下按 bit / 聚集 / DMA 判
    if xor_consistent:
        if clustered:
            return ("DRAM SEU / 位线缺陷（硬件）— 红区完整 + bit 跨样本一致 + 物理区域聚集",
                    "高")
        return ("DRAM SEU / 位线缺陷（硬件）— 红区完整 + bit 跨样本一致（区域分散，位线级）",
                "中-高")

    # bit 跨样本不一致
    if in_dma_region:
        return ("DMA stray write 嫌疑（PA 落 DMA 区）— 查 venus/BAM DMA + arm-smmu context-fault",
                "中")
    return ("信息不足 — bit 跨样本不一致且无 DMA 命中；继续攒样本观察 bit/区域模式",
            "低(待样本)")


def fmt_event(k, e):
    rz = "intact(全0xbb)" if e.get("redzone_ok") else "CORRUPTED(非0xbb)→CPU越界/UAF嫌疑"
    out = [
        "[#%d] %s  %s" % (k, e.get("cache", "?"), e.get("what", "?")),
        "    fault VA  = %s  @offset=%d" % (hex(e["fault_va"]), e["offset"]),
        "    PA        = %s   (DMA: %s)" % (hex(e["pa"]), e["dma_region"] or "no"),
        "    byte      = %s -> %s  (XOR=%s, %d bit flip)" % (e["good_byte"], e["bad_byte"], hex(e["xor"]), e["bit_count"]),
        "    redzone   = %s" % rz,
        "    slab      = %s  obj=%s" % (e.get("slab", "-"), e.get("obj_va", "-")),
        "    alloc     = %s" % e.get("alloc", "-"),
        "    free      = %s" % e.get("free", "-"),
    ]
    if "dump_row" in e:
        out.append("    dump      = %s" % e["dump_row"])
    return "\n".join(out)


def to_evidence(e):
    """对齐 data/cases/*.json 的 two_sample_evidence 字段结构。"""
    return {
        "cache": e.get("cache"), "type": e.get("what"),
        "VA": hex(e["fault_va"]), "PA": hex(e["pa"]), "offset": e["offset"],
        "flip": "%s→%s (XOR=%s)" % (e["good_byte"], e["bad_byte"], hex(e["xor"])),
        "alloc": e.get("alloc"), "free": e.get("free"),
        "slab": e.get("slab"), "redzone_intact": e.get("redzone_ok"),
        "crash_kmem_required": True,
    }


def main():
    ap = argparse.ArgumentParser(
        description="提取 SLUB overwritten 事件 + 算 PA + 判 DRAM-SEU/CPU-UAF/DMA (对齐 ptrn-007)")
    ap.add_argument("logs", nargs="+", help="串口 log 文件(可多个)")
    ap.add_argument("--page-offset", type=lambda s: int(s, 0), default=None,
                    help="PAGE_OFFSET（默认按 --va-bits）")
    ap.add_argument("--phys-offset", type=lambda s: int(s, 0), default=DEFAULT_PHYS_OFFSET,
                    help="PHYS_OFFSET（默认 0x40000000）")
    ap.add_argument("--va-bits", type=int, choices=[39, 48], default=39,
                    help="VA_BITS → PAGE_OFFSET（39=0xffffff8000000000, 48=0xffff000000000000）")
    ap.add_argument("--dma-region", action="append", default=[], metavar="NAME:LO:HI",
                    help="DMA 区，可多次（如 swiotlb:0xe6800000:0xe6c00000）")
    ap.add_argument("--json", action="store_true", help="JSON 输出(对齐 two_sample_evidence)")
    args = ap.parse_args()

    page_offset = args.page_offset or PAGE_OFFSET_BY_VABITS[args.va_bits]
    dma_regions = []
    for spec in (args.dma_region or []):
        name, lo, hi = spec.split(":")
        dma_regions.append((name, int(lo, 0), int(hi, 0)))
    if not dma_regions:
        dma_regions = DEFAULT_DMA_REGIONS

    all_ev = []
    for p in args.logs:
        all_ev += parse(p, page_offset, args.phys_offset, dma_regions)

    if not all_ev:
        print("No SLUB 'overwritten' events found.")
        return

    if args.json:
        print(json.dumps({"events": [to_evidence(e) for e in all_ev]}, indent=2, ensure_ascii=False))
        return

    print("Found %d SLUB overwrite event(s):\n" % len(all_ev))
    for k, e in enumerate(all_ev, 1):
        print(fmt_event(k, e))
        print()

    print("=== 软硬判别（对齐 ptrn-007）===")
    xor_set = set(e["xor"] for e in all_ev)
    print("  bit 一致性 : XOR=%s %s" % ([hex(x) for x in xor_set], "→ 一致" if len(xor_set) == 1 else "→ 不一致"))
    print("  区域聚集   : %s" % ("是(同 32KB ≈ slab page 块)" if is_clustered([e["pa"] for e in all_ev]) else "否"))
    rz_bad = [k for k, e in enumerate(all_ev, 1) if not e.get("redzone_ok", True)]
    print("  红区完整性 : %s" % ("全部完整(0xbb)" if not rz_bad else "事件 %s 红区被踩" % rz_bad))

    result = classify(all_ev)
    if result is None:
        print("\nVerdict: [classify 未实现 — 请完成脚本中 TODO(human)]")
    else:
        verdict, conf = result
        print("\nVerdict: %s" % verdict)
        if conf:
            print("Confidence: %s" % conf)
    print("\n(启发式倾向；对象边界/freelist/slab 健康度请用 crash kmem/kmem -s 复核 — tool_chain.md)")


if __name__ == "__main__":
    main()
