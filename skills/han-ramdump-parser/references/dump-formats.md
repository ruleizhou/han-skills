# ramdump 格式判型

ramparse `-a` 模式下由 ramdump.py 的 AutoDumpInfo 子类自动探测。判型看文件名特征：

| 格式 | 特征文件 | 说明 |
|------|---------|------|
| 完整 dump | `dump_info.txt` + `DDRCS*.BIN`（或 `EBI*.BIN`/`VMDDR*.BIN`）+ 可选 `*IMEM.BIN` | 文件名匹配 `(DDR\|EBI\|VMDDR)[0-9_CS]+[.]BIN`；IMEM.BIN 含 KASLR magic |
| reduced dump | `binoffsets.txt` + `MR_HLOS*.ELF` | 只抓 HLOS 关键区域，体积小 |
| minidump | `md_*.BIN`（如 md_DSP.BIN、md_MODem.BIN）+ `mdASCII.txt` | 各子系统分段；注意确认含 HLOS 段，否则解不出 dmesg |
| VMSSR dump | `VM_SSR_MEM.BIN` + `md_KELF_HDR.BIN` + `dump_info.txt` | VM 死机专用（MC9829 基线定制 AutoDumpInfoVMSSRdump 支持类） |
| load.cmm | `load.cmm` | T32 加载脚本（可反推物理布局） |

## 判型命令

```bash
ls <dump目录> | head -30
```

按上表特征匹配即可。注意一个目录可能同时有 minidump 和完整 dump 的文件（现场抓取工具全带上），此时 ramparse 自动探测可能有歧义，看它启动时打印的识别结果是否符合预期，不符合时用 `--minidump`/`--reduceddump`/`--vmcoredump` 强制指定。

## KASLR 手工提取（IMEM.BIN 路径）

IMEM.BIN 里搜 `0xdead4ead` magic，其结构体附近即 kaslr offset。完整提取步骤见 han-kernel-crash-analyzer 的 crash-parse-raw 工作流（那边用 crash 工具验证过的方法）。
