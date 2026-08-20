# Step 3: 板级 GPIO / 外设常开

## 3.1 材料

- Suspend UART / `gpiodump` 中的 `gpioN : ...` 行  
- 板级 DTS：`gpio-userspace`、NFC（`qcom,sn-nci`）、HUB 供电脚  

## 3.2 优先检查

| 类型 | 动作 |
|:---|:---|
| **out high** 供电/使能 | 对照 DT label；无硬件则禁用驱动并默认拉低 |
| NFC `nq@` / `nfc_i2c.ko` | 无 NFC → DTS `status=disabled` + VEN GPIO low |
| USB HUB 3V3 等 | 测流前拉低，记 mA 收益 |
| func≠0 且可疑 | 查是否应进 sleep pinctrl |

## 3.3 记录

每项：改前状态 → 改后状态 → **实测 ΔmA**（无实测则标 unmeasured）。

无收益的板级项不要升为主因；有收益（如 ~2mA）记入 patterns。

**完成后，读取 `workflows/step-04-debug-qdss.md` 继续。**
