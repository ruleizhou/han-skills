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

## QCM4490 / MC9041 (ravelin) / kernel 5.10.226-android12
- vmlinux: symbols/vmlinux (~441M)；模块 symbols/modules/*.ko
- KASLR: ramparse 从 OCIMEM 0xdead4ead 确定（案 92355: kaslr_offset=0x2cb6c00000, kimage_vaddr=0xffffffecbec00000）
- **pKVM (kvm-arm.mode=protected)**：host(coreX_regs.cmm) 与 guest(corevcpuX_regs.cmm) 两套上下文；fault 分析看 corevcpuX
- **怪癖：ramparse `--check-for-panic` 段可能为空（漏检 remoteproc/子系统 crash 触发的 panic）**——必须手动 grep dmesg_TZ.txt 全文：`remoteproc.*crashed` / `fatal error received` / `Kernel panic - not syncing`
- 区分 HLOS 主动 panic vs 内存 fault：看 corevcpu 寄存器 esr_el1（EC=0x15 SVC=系统调用上下文，非 data abort 0x24/0x25）+ isr_el1（=0 无 pending abort）
- modem(MPSS) crash 路径：smp2p 'q6v5 fatal' 通知 HLOS → qcom_q6v5_crash_handler_work → panic → qcom_wdt_trigger_bite 重启；看门狗 bite 在 panic 之后（是手段非原因）
