# Step 0: 收集测试需求

明确测试类型与规格对标来源。规格的**最终取值**可能在 Step 1 获取 UFS 型号后才确定（按型号匹配分支）。

## 0.1 测试类型

用 `AskUserQuestion` 收集（主路径 `ufs_test.sh` 默认跑完整测试；其余项通过环境变量或单点复测实现）：

```yaml
questions:
  - header: 测试类型
    question: 需要跑哪些测试项？
    multiSelect: false
    options:
      - label: 完整测试（推荐）
        description: ufs_test.sh 全量——顺序读/写各 numjobs=1/2/4/8 四档 + 随机读/写 IOPS。耗时 ~5-8 分钟
      - label: 仅顺序读写
        description: 只跑顺序档（透传环境变量或单点复测跳过随机段）。耗时 ~3 分钟
      - label: 仅随机 IOPS
        description: 只跑随机读/写。耗时 ~1 分钟
      - label: 自定义参数
        description: 自定义 bs/size/numjobs 等环境变量
```

## 0.2 规格对标来源

```yaml
questions:
  - header: 规格对标
    question: 用哪套规格对标？
    multiSelect: false
    options:
      - label: 按型号匹配（推荐）
        description: Step 1 取到 UFS 型号后，查 patterns.json 的 device_profiles.<model>.spec 回填 4 个值
      - label: 我来提供
        description: 你依据数据手册提供顺序读/写 MB/s、随机读/写 IOPS 四个值
      - label: 仅摸底，不对标
        description: 只测实际值，规格传 0 跳过达标判断
```

## 0.3 规格值确定（4 项：SPEC_SEQREAD / SPEC_SEQWRITE / SPEC_RANDREAD / SPEC_RANDWRITE）

- 选「按型号匹配」→ 查 `data/patterns.json` 的 `device_profiles.<model>.spec` 回填（**用户已告知型号则现在就查；否则待 Step 1 获取型号后回填**）。也可先看 SKILL.md「已知 UFS 型号规格」速查表。未收录则回落「我来提供」或默认。
- 选「我来提供」→ 现场收集 4 个值。
- 选「仅摸底」→ 4 个值置 0。
- 兜底默认 CY14-64G：读 820 / 写 520 / 随机读 35000 / 随机写 80000 IOPS。

最终把 4 个值透传给 Step 2.3。

完成后，读取 `workflows/step-01-check-device.md` 继续。
