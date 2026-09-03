# Step 0: 收集三要素与判型

收集解析所需的三要素：**dump 目录、vmlinux、parser 源码**，并识别 dump 格式、确认运行模式。

## 0.1 收集 dump 目录（必须）

用户消息里通常已给路径。若只给了单个文件（如 DDRCS0.BIN），dump 目录取其所在目录。

确认存在后 `ls` 一遍，按 `references/dump-formats.md` 判型：

- `dump_info.txt` + `DDRCS*.BIN` → 完整 dump
- `binoffsets.txt` + `MR_HLOS*.ELF` → reduced dump
- `md_*.BIN` → minidump
- `VM_SSR_MEM.BIN` + `md_KELF_HDR.BIN` → VMSSR（VM 死机 dump）

判不了型（文件都不匹配）时停下来问用户 dump 从哪来的，不要硬跑。

## 0.2 定位 vmlinux（必须，严格匹配）

优先级：

1. 用户显式给的路径 → 直接用
2. dump 目录里自带 vmlinux（部分现场打包会带上）→ 校验符号后用
3. 按项目定位：知道项目名时先调 project-info skill 拿源码树/out 路径，找 `out/<board>/obj/KERNEL/vmlinux` 或 `out/../common/build/vmlinux` 一类编译产物
4. 都定位不到 → **用 AskUserQuestion 问**，同时给出"从出 dump 的那台设备对应项目的编译产物里拿"的提示

校验：`file <vmlinux>` 确认 `not stripped`（stripped 的 vmlinux 无法符号化，ramparse 会跑但结果全错）；ELF 头 offset 4 == 0x02 即 arm64（ramparse 自动识别，无需手动传）。

**版本匹配铁律**：vmlinux 必须来自出 dump 设备刷的同一版本固件的编译产物。dump 里 dmesg 首行的内核版本串（如 `Linux version 5.15.x ...`）应与 vmlinux 的版本一致，不一致必换。

## 0.3 定位 parser 源码

优先级：

1. 用户显式给的路径
2. vmlinux / dump 所属项目的源码树：`<源码树>/vendor/qcom/opensource/tools/linux-ramdump-parser-v2`（项目源码树路径可联动 project-info skill 查询）
3. 已知项目路径直接探（如 MC9829 → `/home5/zhourulei/code/MC9829/LA.VENDOR.16.2.1`）
4. 找不到 → 问用户

**为什么要用 dump 所属项目自带的 parser 副本**：各项目基线的 parser 会带该平台的 board_def/board_config 定制（如 MC9829 基线含 VMSSR 支持），跨项目混用容易 target 识别失败。

## 0.4 确认模式与输出目录

- 模式：默认**解析模式（-x 全量）**；用户明确要快时用**快速模式（--dmesg 精选）**
- 输出目录固定约定：`<dump目录>/parser_out`（与 han-kernel-crash-analyzer step-01 的检测约定对齐）。目录已存在时问用户复用还是重跑

三要素齐备后回述一遍（dump 路径 + 判型结论、vmlinux 路径、parser 路径、模式），简短确认即可进入下一步。

**完成后，读取 `workflows/step-01-envcheck.md` 继续。**
