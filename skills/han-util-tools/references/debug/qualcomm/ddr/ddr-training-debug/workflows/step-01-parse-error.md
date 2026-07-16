# Step 1: 解析错误码

## 1.1 识别错误码

从 UART 日志中找到 `Error code` 行：

```
B -  XXXXXXXX - Error code 84 at ddr_external_api.c Line 335
```

提取：**错误码 = 84**，**触发文件 = ddr_external_api.c:335**

## 1.2 查找错误码定义

读取 `{boot_images}/QcomPkg/Include/api/boot/boot_error_if.h`，搜索对应错误码：

```bash
grep -n "0X0084\|BL_ERR_CORE_VERIFY" {boot_images}/QcomPkg/Include/api/boot/boot_error_if.h
```

常见映射：
| 错误码 | 宏 | 含义 |
|--------|---|------|
| 84 | `BL_ERR_CORE_VERIFY` | 核心断言失败 |
| 82 | `BL_ERR_CORE_BOOT` | 启动核心错误 |

详见 `references/error-codes.md`。

## 1.3 定位触发函数

读取 `ddr_external_api.c:332-336`：

```c
void ddr_abort(void)
{
  BL_VERIFY(0,BL_ERR_CORE_VERIFY);
}
```

错误码 84 = `ddr_abort()` 被调用。

## 1.4 解析 Call Stack（可选）

如有 Call Stack 打印，根据地址区间初步判断：

- `0x0C22xxxx ~ 0x0C24xxxx` → SBL1 主代码
- `0x0C29Axxx ~ 0x0C2Bxxxx` → DDR DSF 训练库（`SBL1_DDR_DSF_ROM`）
- 如需精确解析 → 使用 `llvm-objdump -t ddi.elf`（需 unstripped ELF）

## 1.5 判断 abort 类型

- 日志中有 `SMALL_EYE_*` → small_eye_abort 机制触发（见 Step 3）
- 无 `SMALL_EYE_*` 日志 → 直接 `ddr_abort()` 调用或未加诊断日志

## 下一步

完成后，读取 `workflows/step-02-load-platform.md` 继续。
