# 交叉工具链：配置方式与探测顺序

ramparse 符号化依赖 gdb + nm（必须）和 objdump（可选）。优先级：**命令行 `-g/-n/-j` > local_settings.py > CROSS_COMPILE 环境变量**（ramparse.py:418-437 实测逻辑）。

位数自动判断：parser 读 vmlinux ELF 头 offset 4（0x2=arm64），自动选 32/64 位工具链配置。现代高通平台几乎全是 arm64 → 需要 **aarch64** 工具链。

## 推荐配置方式：命令行参数

```bash
-g /path/to/aarch64-gdb -n /path/to/aarch64-nm -j /path/to/aarch64-objdump
```

不动源码树（local_settings.py 会往 parser 目录写文件，多项目共用时互相覆盖），也不依赖环境变量。

## 探测顺序

1. **项目源码树 prebuilts**：`ls <源码树>/prebuilts/gcc/linux-x86/aarch64/*/bin/` 找 nm/objdump。**注意：AOSP prebuilts 从不带 gdb**——nm/objdump 常有，gdb 必缺，gdb 要走 2/3
2. **系统 PATH**：`which aarch64-linux-gnu-gdb gdb-multiarch aarch64-linux-gnu-nm`
3. **~/.tools/**：`ls ~/.tools/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/`（已装过就不用再装）
4. 都没有 → 问用户（给下面的获取方案）

## 本机现状（2026-09-03 实测，探测时先验证再信）

- MC9829 源码树 prebuilts **只有 32 位** `arm-eabi-4.8`——64 位 dump 用不了
- MC5616 源码树 prebuilts 有 `aarch64-linux-android-4.9`（nm/objdump 可用，无 gdb）
- 系统 `which` 无 aarch64-linux-gnu-gdb / gdb-multiarch
- `~/.tools/gdb-multiarch/usr/bin/gdb-multiarch` 已装（8.1.1，deb 解包方案）——**gdb 首选这里**。运行该 gdb 必须带：
  ```bash
  export LD_LIBRARY_PATH=$HOME/.tools/gdb-multiarch/usr/lib/x86_64-linux-gnu
  ```
  （libbabeltrace/libdw 也解包在 ~/.tools/gdb-multiarch/usr/lib/ 下）
- nm/objdump 用项目源码树 prebuilts（如 MC5616 的 `aarch64-linux-android-4.9/bin/aarch64-linux-android-{nm,objdump}`）

即：gdb 全机来源是 ~/.tools/gdb-multiarch（LD_LIBRARY_PATH 依赖），没装就按下面方案装。

## 获取方案

### 方案 A：apt（要 root）

```bash
sudo apt install gdb-multiarch binutils-aarch64-linux-gnu
```

gdb-multiarch 覆盖 gdb；binutils 包给 aarch64-linux-gnu-nm/objdump。

### 方案 B：ARM 官方预编译包（无 root）

```bash
mkdir -p ~/.tools && cd ~/.tools
wget https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz
tar xf gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz
# 之后工具链路径：
# ~/.tools/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-{gdb,nm,objdump}
```

装好后更新本文件的「本机现状」，并把路径记入 `data/patterns.json`（下次直接命中）。

## 常见坑

- 32 位 arm-eabi-nm 读 64 位 vmlinux → 报格式错误或符号全错。位数以 vmlinux 为准选工具链
- glibc 过老跑不了新工具链时：`patchelf --set-rpath $HOME/.tools/glibc-2.39/lib <目标>`（全局 CLAUDE.md 的通用修法）
