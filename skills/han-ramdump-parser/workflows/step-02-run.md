# Step 2: 执行 ramparse

## 2.1 命令模板（解析模式，默认 -x 全量）

```bash
cd <parser目录> && \
PYTHONPATH=$HOME/.local/lib/python3.8/site-packages \
python3 ramparse.py \
  -v <vmlinux绝对路径> \
  -a <dump目录绝对路径> \
  -o <dump目录>/parser_out \
  -g <aarch64-gdb> -n <aarch64-nm> -j <aarch64-objdump> \
  -x
```

要点：

- **cd 到 parser 目录再跑**——parser_util 用相对路径 `import_all_by_path('parsers')` 加载全部插件，在别处跑会找不到插件
- **路径用绝对路径**——-a/-v 传相对路径时换目录执行容易踩空
- `-g/-n/-j` 填 Step 1 探测到的工具链；objdump 没有可不传（gdb/nm 缺失会直接退出）
- `-x` = everything，跑全部 ~100 个插件，一次出全量产物，后续分析不用补跑

## 2.2 快速模式

用户只要快点看内核日志时，把 `-x` 换成 `--dmesg`（等价短选项 `-d`，只跑 dmesg 插件，几十秒出 dmesg_TZ.txt）。多个精选插件开关可以组合着加；完整开关列表跑 `python3 ramparse.py --help` 看全量，或查 `references/ramparse-options.md`。

## 2.3 运行方式

- 全量 + 大 dump 可能跑几十分钟：**用 run_in_background 跑**，完成后取输出看结果
- 怕单个插件卡死可加 `--timeout <秒>`（需要 func_timeout 库，没装就别加，先裸跑）
- 前几屏输出是关键：ramdump 格式识别、vmlinux 加载、`Using gdb path ...` `Using nm path ...` 都正常才算启动成功

## 2.4 常见补充选项

| 场景 | 选项 |
|------|------|
| target/硬件自动识别失败（报 could not find hardware / SMEM didn't match / offset 探测失败） | **新平台内核常见**（vmlinux 无 struct smem_shared 结构）。`--force-hardware <board_num>`。**board_num 必须跑之前确认**（不能靠产物——产物解不出正是要指定的原因）：① 现场 log（Log/Serial Debug*.txt、*dump-log*.txt）grep `Hardware name` 最快 ② 无现场 log 跑 skill 自带 `scripts/qcom_platform_id.py <dump目录> --parser-dir <parser目录>`（秒级自动消歧出 board_num）③ strings DDRCS*.BIN 慢兜底。事后用产物 dmesg 的 Hardware name 行验证。完整流程见 troubleshoot.md |
| KASLR 偏移已知或自动算错（症状：符号化驴唇不对马嘴） | `--kaslr-offset 0x<offset>`；从 IMEM.BIN 的 0xdead4ead magic 手工提取的方法见 troubleshoot.md |
| 需要模块（.ko）符号 | `-m <模块符号目录>`，指向 .ko.unstripped 所在目录，可多次传 |
| 物理/页偏移自动探测失败 | `--phys-offset` / `--page-offset` |

启动失败（非插件级报错）→ 读 `workflows/troubleshoot.md` 对症。

**跑完后，读取 `workflows/step-03-verify.md` 继续。**
