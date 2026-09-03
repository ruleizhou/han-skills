# ramparse 命令行选项矩阵

来源：MC9829 基线（LA.VENDOR.16.2.1）ramparse.py，各项目基线可能有增减，跑 `python3 ramparse.py --help` 看当前副本全量。

## 核心选项

| 选项 | 说明 |
|------|------|
| `-v/--vmlinux <path>` | vmlinux 路径（必须，与 dump 严格同版本） |
| `-a/--auto-dump <dir>` | dump 目录（自动探测格式） |
| `-e/--ram-file <file> <start> <end>` | 直接指定单个 ram 文件 + 物理地址范围（无完整 dump 时） |
| `-o/--outdir <dir>` | 输出目录，约定 `<dump目录>/parser_out` |
| `-f/--output-file <file>` | 输出重定向到单文件 |
| `--stdout` | 输出到标准输出 |
| `-x/--everything` | 跑全部插件（默认推荐） |
| `-s/--t32launcher` | 生成 T32 launcher |
| `--force-hardware <target>` | 强制指定平台（自动识别失败时用），target 见 extensions/board_def.py |
| `--force-version <n>` | 强制平台版本 |
| `--kaslr-offset <int>` | 手工指定 KASLR 偏移 |
| `--phys-offset <int>` / `--page-offset <int>` | 手工指定物理/页偏移 |
| `--64-bit` / `--32-bit` | 强制位数（一般不用——parser 自动从 vmlinux ELF 头 offset 4 判断：0x2 为 arm64） |
| `-g/--gdb-path` `-n/--nm-path` `-j/--objdump-path` | 交叉工具链路径（优先级最高，推荐用这组而不是 local_settings.py） |
| `-m/--mod_path <dir>` | 模块 .ko.unstripped 符号目录，可重复传 |
| `--wlan <path>` | wlan.ko 路径（默认 INTEGRATED） |
| `--timeout <sec>` | 单插件超时（需要 func_timeout 库） |
| `--minidump` / `--reduceddump` / `--vmcoredump` / `--svm` | 强制指定 dump 类型（一般不用——-a 自动探测） |
| `--shell` / `--classic-shell` | 进交互 shell |
| `--dump_mod_sym_tbl` / `--dump_krnl_sym_tbl` / `--dump_mod_kallsyms` | 导出符号表 |

## 常用插件开关速查（精选模式用）

每个 `parsers/` 下插件通过 `@register_parser('--xxx')` 注册成开关，可组合。按类别：

| 类别 | 常用开关 |
|------|---------|
| 日志 | `--dmesg`(-d)、`--pstore`、`--ipc_logging`、`--logcat`（变体 v2/v3）、`--journalctl` |
| 进程/调度 | `--taskdump`、`--runqueue`、`--wakeup`、`--binder`、`--lsof` |
| 内存 | `--memusage`、`--memstat`、`--slabinfo`、`--slabsummary`、`--vmalloc`、`--zram`、`--cma`、`--pagetracking`、`--zoneinfo`、`--ion_buffer_parse` |
| 跟踪 | `--ftrace`、`--ftrace_event`、`--rtb` |
| 设备/子系统 | `--ufs-parse`、`--usb`、`--thermal_data`、`--clockdump`、`--regulator`、`--iommu`、`--vidc`、`--gpuinfo` |
| 电源/其他 | `--lpm`、`--spm`、`--watchdog`、`--lockdep`、`--irqstate`、`--workqueue`、`--dtb`、`--coredump` |

开关名以当前副本 `--help` 输出为准，上表是跨基线常见集合。
