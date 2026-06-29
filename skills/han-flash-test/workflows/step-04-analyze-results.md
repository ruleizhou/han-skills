# Step 4: 分析结果

解析设备拉回的 `.ufs_stat.tmp`，做达标判断与异常检测。

## 4.1 解析统计文件

`.ufs_stat.tmp` 每行 4 列：`key min median max`。组织为结构化数据：

| key | 指标 | 单位 |
|-----|------|------|
| `seqread_nj{1,2,4,8}` | 顺序读带宽 | MB/s |
| `seqwrite_nj{1,2,4,8}` | 顺序写带宽 | MB/s |
| `randread` | 随机读 IOPS | IOPS |
| `randwrite` | 随机写 IOPS | IOPS |

每项取 **median**（中位数）作代表值，min/max 反映稳定性。

> 解析：文件固定单空格分隔（4 列），可直接 `awk '{print $1, $3}'` 取 key + median。

## 4.2 达标判断（中位数 vs 规格）

取 numjobs 最高档（nj8）做顺序达标：

| 测试项 | 判定规则 | verdict |
|--------|----------|---------|
| 顺序读 | `seqread_nj8.median ≥ SPEC_SEQREAD` | pass / fail |
| 顺序写 | `seqwrite_nj8.median ≥ SPEC_SEQWRITE` | pass / fail |
| 随机读 | 实测 vs SPEC_RANDREAD | **warn（不 fail）** |
| 随机写 | 实测 vs SPEC_RANDWRITE | **warn（不 fail）** |

> ⚠️ **psync 限制（必读）**：Android fio 仅有 psync 引擎（QD1），随机 IOPS 实测通常只有规格的 **10-20%**，这是测试方法限制而非器件问题。故随机 IOPS 一律 `warn`，报告必须标注「psync QD1 限制，实测低属正常」。否则自学习库会被错误结论污染。

若 Step 0 选「仅摸底」（规格=0），跳过达标判断，只报实测值。

## 4.3 异常检测

| 异常 | 判定 | 含义 |
|------|------|------|
| SLC 断崖 | `seqwrite_nj8.median < seqwrite_nj4.median × 0.6` | 高档累积写入耗尽 SLC 缓存，暴露 TLC 直写 |
| 带宽不随并发增 | `seqread_nj8 ≤ seqread_nj2`（基本无提升） | CPU/队列瓶颈或 read-ahead 已封顶 |
| 结果不稳定 | `(max - min) / median > 0.30` | 抖动大，建议重测或排查后台负载 |
| CPU 瓶颈 | `cpu: usr+sys` 接近 100%（见 result.txt） | 测试受限于 CPU 而非存储 |

## 4.4 横向对比（自学习）

查 `data/patterns.json`：
- 同型号历史 `test_results`：本次是否退化/提升。
- `alerts` 历史异常（该型号已知的 SLC 断崖、IOPS 限制）：本次复现则提升 confidence。

把达标结论 + 异常清单整理好，交给 Step 5 出报告并落库。

完成后，读取 `workflows/step-05-report.md` 继续。
