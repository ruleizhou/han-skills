# 平台怪癖

按平台/芯片/内核版本累积的已知怪癖。首次分析新平台时读取此文件，发现新怪癖时追加。

## QCM6490 / LA.UM.9.14.1 / kernel msm-5.4
- vmlinux 格式：PIE ELF shared object
- 符号表位置：symbols/vmlinux
- dmesg_TZ.txt 通常位于 parser_out/ 或当前目录
- 常见 crash 场景：USB 热插拔、display panel 初始化、power key 唤醒

## SM6225 / LA.VENDOR.13.2.1 / kernel msm-5.10
- vmlinux 格式：PIE ELF shared object
- 符号表位置：symbols/vmlinux
- dmesg_TZ.txt 通常位于 parser_out/Small/ 子目录

## 通用 Qualcomm 平台
- Android event log 通常为 UTF-16LE 编码
- ramdump 解析后目录结构：parser_out/ + symbols/ (或 SymbolTable/)
- `Code:` 行包含崩溃指令的 hex dump，括号内为崩溃指令
