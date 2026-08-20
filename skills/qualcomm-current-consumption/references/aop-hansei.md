# AOP Hansei

## 定位脚本

在 AMSS 树中找：`AOP.HO.*/aop_proc/core/bsp/aop/scripts_py3/hansei/hansei.py`

## 命令模板

```bash
export PYTHONPATH="$HOME/.local/lib/python3.8/site-packages${PYTHONPATH:+:$PYTHONPATH}"
python3 hansei.py --elf <AOP_xxx.elf> -t <target> -o <out> <ramdump_dir>
```

- **target**：芯片代号（Parrot/SM6450P 常用 **netrani**），查 `hansei_config.py` 的 `known_targets`  
- dump 传**目录**，不要写字面量 `dumpfile`  

## 依赖

`pyelftools`、`pandas`；若 `ENABLE_USER_SITE=False`，必须设 `PYTHONPATH`。

## 关键输出

`aop-summary.txt`、`sleep_stats.txt`、`npa-dump.txt`、`aop_serv_msgram_parse.txt`、`aop_ddr_logs_msgram11.txt`
