# Step 0: 收集场景与材料

**必须先使用 `AskUserQuestion`（或工具不可用时在对话中给出等价选项）收集信息。禁止在提问前 `ls`/`Read`/`Grep`/`Shell` 翻文件。**

## 收集项（一次可多题）

1. **平台/项目**：如 SM6450P / Parrot / MC5616；AOP target 名（netrani 等）是否已知  
2. **材料有哪些**（多选）：AOP/ramdump 目录、AOP `.elf`、UART/GPIO dump、adb 可连、仅口述  
3. **电流**：对标电流 / 问题电流 / 差值（mA）；未知则选「未知」  
4. **测流条件**：`deep` / `s2idle` / 不确定；是否拔 USB  

可选补充：是否已改过 NFC/UFS SPM/STM。

## 交互失败时

参数报错则修正后立即重试 AskUserQuestion，仍不可用则用编号选项请用户回复，**仍不得先翻仓库**。

## 输出（写入后续步骤上下文）

```text
platform / aop_target:
materials: dump=  elf=  uart=  adb=
current_delta_mA:
suspend_mode: deep|s2idle|unknown
usb_unplugged_for_measure: yes|no|unknown
```

若用户已附 dump/路径，记下绝对路径，**等本步交互完成后再读**。

**完成后，读取 `workflows/step-01-sleep-baseline.md` 继续。**
