# Step 5: 输出报告与落库

汇总 Step 4 的达标结论与异常，输出报告，并写入自学习数据（patterns.json + cases）。

## 5.1 输出测试报告

向用户输出结构化报告：

```
## UFS 测试报告：<型号> (<日期>)

### 规格 vs 实测
| 测试项 | 规格 | 实测(中位数) | 范围(min~max) | 判定 |
|--------|------|-------------|---------------|------|
| 顺序读 nj8 | 820 MB/s | 945 MB/s | 920~953 | ✅ pass |
| 顺序写 nj8 | 520 MB/s | 451 MB/s | 448~454 | ❌ fail |
| 随机读 | 35000 IOPS | 6191 IOPS | 6050~6320 | ⚠️ warn(psync) |
| 随机写 | 80000 IOPS | 5381 IOPS | 5300~5450 | ⚠️ warn(psync) |

### 关键发现
- ...

### 建议
- ...
```

> 随机 IOPS 的 warn 必须标注「psync QD1 限制」。

## 5.2 落库 patterns.json

更新 `data/patterns.json`（schema v2）：

1. **device_profiles**：型号未收录则新增（含 `spec` 块：seqread/seqwrite/randread/randwrite）。
2. **test_results**：新增本次记录，key = `<MODEL>_<YYYYMMDD>`：
   ```json
   {
     "device": "CY14-64G", "date": "2026-06-19", "method": "ufs_test_sh",
     "scheduler": "none",
     "spec": {"seqread": 820, "seqwrite": 520, "randread": 35000, "randwrite": 80000},
     "results": {
       "seqread_nj1_mbps":  {"min":920.3,"median":945.0,"max":953.1},
       "seqread_nj2_mbps":  {"min":...,"median":...,"max":...},
       "seqread_nj4_mbps":  {...}, "seqread_nj8_mbps": {...},
       "seqwrite_nj1_mbps": {...}, "seqwrite_nj2_mbps": {...}, "seqwrite_nj4_mbps": {...}, "seqwrite_nj8_mbps": {...},
       "randread_iops":     {...}, "randwrite_iops": {...}
     },
     "verdict": {"seqread":"pass","seqwrite":"fail","randread":"warn","randwrite":"warn"}
   }
   ```
   > 每项均为 `{min,median,max}` 三元组。**只记录实际跑了的项**——选子集（如「仅随机」）时直接省略对应 key，不要填 0。`scheduler` 字段记**测试时**的值（脚本统一切到 `none`），非设备原始调度器。
3. **alerts**：Step 4 检出异常则追加结构化条目 `{"text": "...", "confidence": 1, "frequency": 1}`（已存在则 frequency+1）。

更新顶层 `last_updated`。历史记录（`method: legacy_per_cmd`）保留不动。

## 5.3 写历史案例

在 `data/cases/` 新建 `<model>-<date>.md`（沿用现有 case 模板：设备信息 + 规格对标表 + 关键发现 + 建议），字段用脚本格式（`seqread_nj*` / `randread` / `randwrite`）。

完成后，本次测试闭环结束。可提示用户：换芯片或复测后说「再看结果」触发反馈闭环。
