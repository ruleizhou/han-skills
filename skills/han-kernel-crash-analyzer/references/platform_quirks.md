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

## QCM6490 crash加载（KBA-231023010743）
- KASLR: OCIMEM.BIN搜0xdead4ead后5字节
- crash命令: crash vmlinux "DDRCS@addr,..." --kaslr=X --no_data_debug --machdep vabits_actual=39 --no_panic
- DDRCS物理地址: 源自dump_info.txt中DDR CS Memo行
- 关键命令: kmem -s判UAF, struct看字段, vtop VA→PA, rd读内存
