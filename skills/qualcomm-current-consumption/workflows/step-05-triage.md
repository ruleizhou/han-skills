# Step 5: 定位矩阵与根因类

综合 Step 1–4，给出**唯一主因类** + 次要项（含已验证 ΔmA）。

## 5.1 矩阵

| 现象 | 根因类 | 下一步 |
|:---|:---|:---|
| 子系统 Count≈0 | `CLASS_SS_AWAKE` | 查未 sleep 子系统 |
| cxsd/ddr=0 | `CLASS_CX_DDR_BLOCKED` | CX/DDR 链路、投票 |
| UFS spm&lt;4 且 L13/L19 仍 EN，抬到 5 后电流大降 | `CLASS_UFS_SPM` | 固化 spm-level，回归 |
| UFS 已到 5 / regulator 已空，电流几乎不变 | 排除 UFS 主因 | 升到 AOSS 线 |
| GPIO/NFC 常高，拉低有 mA | `CLASS_BOARD_GPIO` | DTS/默认态固化 |
| STM/debug 开，关掉仅 ~1mA 且 aosd 仍 0 | `CLASS_DEBUG_MINOR` | 非主因 |
| **aosd=0 且 cxsd&gt;0 且 ddr&gt;0** | **`CLASS_AOSS_STUCK`** | 对标机 aosd；休眠中 AOP；AOSS 常开/硬件 |

## 5.2 输出模板

```markdown
## 分诊结论
- 主因类: ...
- 已验证收益: ...
- 排除项: ...
- 证据: sleep_stats / hansei / gpio / qdss ...
- 下一步 P0/P1: ...
```

先读 `data/patterns.json`，匹配 keywords 提升置信提示（勿替代证据）。

**完成后，读取 `workflows/step-06-report.md` 继续。**
