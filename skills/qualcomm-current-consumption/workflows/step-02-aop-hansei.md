# Step 2: AOP Dump / Hansei 解析

若无 AOP dump / ELF，记录 `AOP_SKIP`，直接进入下一步。

## 2.1 解析命令

```bash
export PYTHONPATH="${PYTHONPATH}:$HOME/.local/lib/python3.8/site-packages"
# 按树内实际路径定位 hansei.py（AOP.HO.*/aop_proc/.../hansei/hansei.py）
python3 hansei.py \
  --elf <AOP>.elf \
  -t <target> \          # 例：netrani；禁止无依据使用 845
  -o <out_dir> \
  <ramdump_folder>
```

依赖：`pyelftools`、`pandas`；user site 关闭时设 `PYTHONPATH`。

## 2.2 必看产出

| 文件 | 看什么 |
|:---|:---|
| `aop-summary.txt` | AOP ok？ |
| `sleep_stats.txt` | aosd/cxsd/ddr 与内核是否一致 |
| `npa-dump.txt` | `/sleep/aoss`、`cx.lvl`、业务轨 |
| `aop_serv_msgram_parse.txt` | Idle / DDR off / DBG |
| `aop_ddr_logs_msgram11.txt` | Collapse D4 / Restore |

## 2.3 典型信号

- `/sleep/aoss` active=0 且 `cx.lvl` 由 `cx_ret` 维持 → 与 `CLASS_AOSS_STUCK` 一致  
- CODERAM mismatch → 先换匹配 ELF  
- RPMH/ARC/BCM 未恢复 → 注明可见性不足，勿臆造子系统投票  

**完成后，读取 `workflows/step-03-board-gpio.md` 继续。**
