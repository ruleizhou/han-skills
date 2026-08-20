# UFS Clock Scaling 机制知识

> 本文件是 skill 的领域知识库，来自 MC5616 parrot 案例（2026-08）实测逆向。反馈闭环中确认有效的新知识追加到本文。

## 1. 两棵驱动树（第一件事：确认哪棵在跑）

GKI 架构下存在两份 UFS 驱动，**参数差异巨大**：

| | kernel_platform/common/drivers/scsi/ufs | kernel_platform/msm-kernel/drivers/scsi/ufs |
|---|---|---|
| 角色 | GKI 侧（一般不编入） | **vendor 模块，实际运行** |
| 确认方式 | - | `CONFIG_SCSI_UFS_QCOM=m`（qcom 平台基本都是） |
| downdifferential | 5 | **65** |
| polling_ms | 60 | 60（DEVFREQ_TIMER_DELAYED） |

**看错树 = 结论全偏**。分析前先在 defconfig（如 `parrot_GKI.config`）确认编译形态。

## 2. governor 三分支（msm-kernel governor_simpleondemand.c L56-74）

```
busy% > 70                        → 升频（300MHz，恢复 G3，WB enable）
busy% > (70 - downdifferential)   → 保持当前频率     ← 死区条件（65 时 = busy>5）
busy% ≤ (70 - downdifferential)   → 降频（75MHz，降 G1，WB disable）
```

- busy% = 60ms 窗口内 UFS 请求在途时间占比（`ufshcd_devfreq_get_dev_status`），**由 flash 单 IO 延迟决定**
- 快料（UFS 3.x）：burst 冲 70+、停后归 0，每周期双向穿越 → 高频切换
- 慢料（UFS 2.2，延迟×2）：burst 后拖尾 load 10~47 → 钉死死区 → 变频饿死

## 3. 变频动作链（ufshcd.c）

```
devfreq target → ufshcd_devfreq_scale(scale_up)
  → ufshcd_clock_scaling_prepare:
      if (!clk_scaling.is_allowed || wait_doorbell_clr 超时) return -EBUSY   ← 静默无日志！
  → scale down: 先降 gear 到 min_gear(G1) 再降时钟 75M
  → scale up:   先升时钟 300M 再恢复 saved pwr mode(G3)
  → ufshcd_wb_ctrl(scale_up)   # Write Booster 随动
```

**runtime suspend 吞降频**：UFS 挂起后 `is_allowed=false`，所有 scaling 请求 -EBUSY 静默失败。唯一可见症状：trans_stat 不增长。

**suspend_work 不做最终降频**：`ufshcd_clk_scaling_suspend_work`（IO 空时触发）只做 `devfreq_suspend_device`，挂起前不补一次降频——参考代码行为。

## 4. quirks 白名单（msm 版 ufs_qcom_dev_fixups[]）

| id | quirk |
|---|---|
| SAMSUNG (0x1AD 之外另有值) | PA_HIBER8TIME \| PA_TX_HSG1_SYNC_LENGTH |
| MICRON (0x12C) | DELAY_BEFORE_LPM |
| SKHYNIX (**0x1AD**) | DELAY_BEFORE_LPM |
| WDC | HOST_PA_TACTIVATE |

**关键陷阱**：Hynix UFS 2.2 料（如 HBN1901280CHBC）报 **0x0CD6**，不等于 UFS_VENDOR_SKHYNIX(0x1AD) → quirk 全 miss → 无 LPM 延迟 → IO 停立即挂起。**换料必核 quirks 表**。

## 5. UFS 2.x/3.x 硬件识别（SDAM 位）

- DT：`ufs-dev-types = <2>` + `qcom,ufs-dev-revert` + nvmem（PMIC SDAM）
- `ufs_qcom_read_nvmem_cell()` → `host->limit_phy_submode`：**1 = UFS 3.x，0 = UFS 2.x**
- 比 manufacturer_id 查表更稳（id 表会漏，SDAM 是贴料烧死的）
- 验证：`dmesg | grep 'UFS device is'`

## 6. flashval 测试黑盒（逆向结论）

- 负载：**180ms 间隔队列化 IO**（ftrace 抓到 512KB WRITE_10 × 32 队列 + 4KB 微 IO 混合）
- 检测：轮询 `qcom/bus_speed_mode`（fallback 链终点，实为 gear G3↔G1 切换）
- 判定：每方向 1000 次；**10s 无切换 WARN，30s 无切换 ERROR 放弃该方向**（2.1/2.2 报同一计数；-1 = 前置失败未执行，test_ran=0）
- 逆向方法：设备上 `strings /data/fv_test/flashval` 搜 sysfs 路径和错误串 + pylog 里 `clkscale_core_test` 进度日志

## 7. 已验证的修复模式

| 模式 | 做法 | 适用 |
|---|---|---|
| governor 参数分流 | `ufs_qcom_config_scaling_param` 里按 `limit_phy_submode` 设 downdifferential（2.x=45，3.x=65） | 慢料拖尾死区 |
| quirk 补条目 | `UFS_FIX(0x0CD6, ANY, DELAY_BEFORE_LPM)` | 新料 id 掉出白名单 |

**规避陷阱**：`echo on > power/control` 禁挂起可救 test2（28→50）但会弄死依赖 suspend 前置的 test10（-1）——**不可作为规避方案**，只能用于对照实验。
