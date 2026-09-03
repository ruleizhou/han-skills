# 排坑手册（按症状索引）

ramparse 失败时按症状找条目。解决后若为新坑，收录进 `data/patterns.json`（见 step-03）。

## ModuleNotFoundError: No module named 'elftools'

本机设了 `PYTHONNOUSERSITE=1`，`--user` 装的包默认不可见。跑 ramparse 的命令必须显式带：

```bash
PYTHONPATH=$HOME/.local/lib/python3.8/site-packages
```

（step-02 命令模板已内置，手敲命令时容易漏。）

## 教程让装 psutil 却装不上

不需要。这份 parser 只必需 pyelftools；func_timeout 仅 `--timeout` 才用。高通 KBA 文档的 psutil 是过时信息。

## 找不到 parser 插件 / parsers 目录加载失败

没有 `cd` 到 parser 目录就跑了。parser_util 用相对路径 `import_all_by_path('parsers')` 加载插件，必须 `cd <parser目录>` 后执行。

## board_def.py / extensions 相关 ImportError

`<parser目录>/extensions/board_def.py` 不存在。proprietary 扩展没接上（位置两种布局都探）：

```bash
ln -s <源码树>/vendor/qcom/proprietary/ramdump-parser <parser目录>/extensions        # 新布局（MC5616 实测）
ln -s <源码树>/vendor/qcom-proprietary/ramdump-parser <parser目录>/extensions       # 老布局（KBA 写法）
```

proprietary 目录本身都没有 → 源码树没下全（只拉了 opensource 部分），要用户补拉 proprietary。

## Could not get a necessary offset / Could not find hardware / SMEM didn't match

**新平台内核的通病**：vmlinux 里 gdb `ptype struct smem_shared` 查不到（smem 驱动结构改名，如 SM6450P/parrot 5.10 android12-9 内核），auto detection 三连败，产物 dmesg_TZ.txt 只有头 ~10 行（无 panic 内容）。**跳过 auto detection 直接指定平台**。但注意：**不能靠 ramparse 产物确认平台——产物解不出来正是要指定平台的原因（鸡生蛋）**。平台名必须在跑之前用下面证据链确认：

### 事前确认平台（按优先级，全都能在跑 parser 前完成）

1. **现场串口/抓 dump log**：高通抓 dump 基本伴随现场 log，如 issue 目录的 `Log/Serial Debug *.txt`、`*dump-log*.txt`。直接 `grep -a "Hardware name" <现场log>`，如：
   `[   82.526501][ T1349] Hardware name: Qualcomm Technologies, Inc. Parrot QRD PM7250B (DT)` → 平台 **Parrot**
2. **qcom_platform_id.py（秒级，无现场 log 时首选）**：skill 自带脚本，二进制搜 DDR dump 的 Hardware name / DTB compatible，带 `--parser-dir` 自动用 board_num 全集消歧：
   ```bash
   python3 ~/.claude/skills/han-ramdump-parser/scripts/qcom_platform_id.py <dump目录> --parser-dir <parser目录>
   # → parrot（stdout 一行小写平台名；识别方式进 stderr）
   ```
   两条路径：先全文件搜 dmesg `Hardware name: Qualcomm Technologies, Inc. <平台>`（权威名，实测可到 1.9GB 偏移，故全文件扫）；未命中再收集全部 DTB compatible 候选（DDR 里有 HLOS/adsp/cdsp 多份 DTB，adsp 的会抢先——如 netrani 与 parrot 并存），有 `--parser-dir` 时与 board_num 全集取交集消歧。输出候选列表（exit 1）时人工对照 board 全集挑
3. **dump 原始 bin 兜底**：`strings <DDRCS bin> | grep -a "Qualcomm Technologies, Inc"`（6GB 全扫慢；dmesg 环形缓冲在 DDRCS 里，CD_STRCT/OCIMEM 不含 dmesg 别浪费时间）
4. **boot log / kbootlog**：现场若有 `boot_log`、`kernel_boot_log`、`dmesg.log` 等同样 grep

### 平台名 → board_num

- `grep -in "class Board<平台名>" <parser目录>/extensions/board_def.py`（老式类）或 `board_config.py`（新式类），取 `self.board_num` 字段（parrot → "parrot"）
- 或者程序化列全集缩小：`python3 -c "import sys; sys.path.insert(0,'<parser目录>'); from boards import get_supported_boards; print(sorted(set(b.board_num for b in get_supported_boards())))"`（MC5616 基线 137 个）
- 平台名与 board_num 可能不完全同名（如 dts model 写 Parrot QRD，board_num 恰为 "parrot"；也有 ravelin/waipio 之类衍生名），拿不准就把相近的都列出来对照 board 字段

### 事后验证（确认猜对）

跑通后 dmesg_TZ.txt 的 `Hardware name:` 行应与现场 log 一致。符号化栈（`func+0xoffset/0xsize` 合理）也证明内存参数正确——不同平台 ram_start/phys_offset 多不同，猜错一般直接解不出。

会打 "socinfo values given are bogus" 警告，属预期。参考案例：MC5616/SM6450P = **parrot**（socid 537/613，与 diwali 同内存布局参数，所以 diwali 也能蒙对）。

## local_settings 缺失报 ModuleNotFoundError（--help 就挂）

部分基线（MC5616/LA.VENDOR.1.0.R1）的 debug_image_v2.py 顶层 import local_settings（非 try/except），必须写 `<parser目录>/local_settings.py`：gdb64_path/nm64_path/objdump64_path 三个必填 + 32 位三字段兜底（scandump/cpuss 字段可选，用到才查）。写前确认 gdb 路径的 LD_LIBRARY_PATH 依赖（toolchain.md）。MC9829 那份是 try/except 可选——各基线行为不同。

## ModuleNotFoundError: No module named 'tabulate'

MC5616 基线的 parsers/pm_genpd_parser.py 顶层 import tabulate，缺了就 --help 都挂。`python3 -m pip install --user tabulate`（注意 pip3 指向 py2.7，必须 python3 -m pip）。

## Incorrect path for toolchain specified / gdb 不存在

`-g/-n` 两个必须都给且文件存在可执行。64 位 vmlinux 要 aarch64 工具链，32 位 arm-eabi 的不行（读 64 位 ELF 会挂）。工具链获取方案见 `references/toolchain.md`。

## 符号化结果驴唇不对马嘴（地址对不上符号 / 栈全是乱码）

九成是 vmlinux 与 dump 版本不匹配——换 dump 对应项目同 commit 编译产物的 vmlinux。匹配还错 → KASLR 偏移问题，加 `--kaslr-offset`；手工提取法：在 IMEM.BIN 里搜 `0xdead4ead` magic，其附近结构含 kaslr offset（han-kernel-crash-analyzer 的 crash-parse-raw 工作流有完整提取步骤）。

## dmesg_TZ.txt 为空或缺失

- vmlinux 不匹配（最常见）
- KASLR 错（同上条）
- dump 不含 HLOS 区域：minidump 只抓了部分分区时，检查 dump_info.txt / mdASCII.txt 里有没有 HLOS 段；确认是 VMSSR 类 dump（VM_SSR_MEM.BIN）时走的解析路径不同

## 单个插件卡死拖垮全量

去掉 `-x`，用精选开关组合（如 `--dmesg`）。或装 func_timeout 后加 `--timeout <秒>`（不装 func_timeout 就别加 --timeout，会 ImportError）。

## 大 dump 跑到一半磁盘满

`-o` 输出目录换到空间大的盘（parser_out 全量产物可能几十 GB 级别取决于 dump 内容）。`df -h` 先看一眼目标盘。
