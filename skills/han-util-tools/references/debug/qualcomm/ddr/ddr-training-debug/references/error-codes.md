# 常见错误码速查表

## 错误码组成

Qualcomm SBL 错误码 = `错误组 (16bit) | 错误号 (16bit)`

```c
// boot_error_if.h
#define BL_ERROR_GROUP_BOOT   0x01000000  // 启动阶段错误组
#define BL_ERR_CORE_VERIFY    0x0084      // 核心断言失败
```

## DDR Training 相关错误码

| 错误码 | 宏定义 | 含义 | 常见触发场景 |
|--------|--------|------|-------------|
| 84 (0x0084) | `BL_ERR_CORE_VERIFY` | 核心断言失败 | `ddr_abort()` 中 `BL_VERIFY(0, ...)` |
| 82 | `BL_ERR_CORE_BOOT` | 启动核心错误 | DDR 初始化失败 |
| 71 | `BL_ERR_MMU_PGTBL_MAPPING_FAIL` | MMU 页表映射失败 | DDR 地址映射异常 |

## 错误码定位方法

1. 搜索 `boot_error_if.h:BL_ERR_` + 错误码
2. 在代码中 `grep -rn "BL_ERR_XXX"` 找到所有 `BL_VERIFY` 调用点
3. 结合 UART Call Stack 地址反查具体调用路径

## Call Stack 解析

```
Error code 84 at ddr_external_api.c Line 335
^^^^- Printing Call Stack -^^^^
func_addr  :   0C232A1C    ← ddr_abort() / BL_VERIFY
func_addr  :   0C29C6E0    ← DDR_DSF 训练代码（见链接脚本 SBL1_DDR_DSF_ROM）
func_addr  :   0C29B3E8    ← DDR_DSF 训练代码
...
```

- `0x0C22xxxx` 区间 → SBL1_ROM（主启动代码）
- `0x0C29Axxx ~ 0x0C2Bxxxx` 区间 → SBL1_DDR_DSF_ROM（DDR 训练库代码）
- 如需精确解析，使用 `llvm-objdump -t ddi.elf`（需要 unstripped ELF）
