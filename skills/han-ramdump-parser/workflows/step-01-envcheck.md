# Step 1: 环境自检

逐项检查四个依赖，任一失败先按症状查 `workflows/troubleshoot.md`，修好再进 Step 2。全部检查都是只读操作，不会改动源码树。

## 1.1 python3 版本

```bash
python3 --version    # 需要 >= 3.5（ramparse.py 启动时硬检查）
```

本机实测 Python 3.8.20，满足。

## 1.2 pyelftools（必需依赖）

本机设了 `PYTHONNOUSERSITE=1`，`pip3 --user` 装的包默认 import 不到，必须显式挂 PYTHONPATH：

```bash
PYTHONPATH=$HOME/.local/lib/python3.8/site-packages python3 -c "import elftools; print('OK')"
```

后续跑 ramparse 的命令**同样要带这个 PYTHONPATH**（Step 2 的命令模板已内置）。

注意：网上教程（高通 KBA）让装 psutil + pyelftools——psutil 在这个版本的 parser 里并不需要，装不装都行，别在这上面耗时间。

## 1.3 extensions 目录

检查 `<parser目录>/extensions/board_def.py` 是否存在：

- 存在 → 通过（可能是目录也可能是符号链接，都行）
- 不存在但 proprietary ramdump-parser 目录存在 → 建符号链接。**proprietary 位置有两种布局，都探一下**：
  - 新布局：`<源码树>/vendor/qcom/proprietary/ramdump-parser`（MC5616/LA.VENDOR.1.0.R1 实测）
  - 老布局（KBA 文档写的）：`<源码树>/vendor/qcom-proprietary/ramdump-parser`
  - `ln -s <命中的路径> <parser目录>/extensions`
- 两个都没有 → 问用户 proprietary 部分在哪（parser 的目标板配置、cache/TLB 配置全在 extensions 里，缺了必挂）

## 1.4 交叉工具链（gdb + nm 必须，objdump 可选）

按 `references/toolchain.md` 的探测顺序找 aarch64 的 gdb/nm/objdump（现代高通 dump 都是 arm64；parser 自动从 vmlinux ELF 头判断位数，无需手动传）。

探测结论记下来，Step 2 要用 `-g/-n/-j` 传入。**优先用命令行参数**而不是写 local_settings.py——后者会往源码树里加文件，多项目共用一棵树时会互相打架。

探测不到 aarch64 工具链时（本机已知缺口，见 toolchain.md「本机现状」），给用户两个方案选：

1. `sudo apt install gdb-multiarch`（需要 root，Ubuntu 18.04 自带源里就有）
2. 下载 ARM 官方预编译包解压到 `~/.tools/`（无 root 也能装，命令见 toolchain.md）

## 1.5 自检汇总

输出一行汇总：`python3 ✓ / pyelftools ✓ / extensions ✓ / 工具链 gdb=<路径> nm=<路径> objdump=<路径>`，全绿才进 Step 2。

**完成后，读取 `workflows/step-02-run.md` 继续。**
