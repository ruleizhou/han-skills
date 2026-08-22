# 反馈闭环(自学习)

用户说「搞定/修好了/根因确认/复测通过」时执行。目标:把本次分析的真实结果
回灌 patterns.json,让下次同类问题分流更准。

## 流程

1. **回顾本次分析**:用了哪些指纹/哪条路径定级/哪些假说被什么证据排除
2. **向用户确认**(结构化提问):
   - 最终根因与报告结论一致吗?(一致/部分一致/不一致+实际根因)
   - 哪个信号组合是定案的关键?
3. **存案例卡**到 `data/cases/<bug_id>.md`:
   - 症状(票面一句话)→ 关键信号(指纹+统计特征)→ 根因类 → 定案证据
   - 被证伪的假说及证伪证据(最有价值的部分)
4. **更新 `data/patterns.json`**:
   - 命中现有 pattern:confidence +0.1(上限 0.95),frequency +1
   - 新信号组合:新建 pattern(confidence 0.5 起步)
   - 误判记录:被证伪的分流信号 → 在对应 pattern 加 `negative_signals`
5. **报告闭环**(若在塔台体系内):`report close --status verified`,
   校准 `triage_correct`

## patterns.json 结构约定

```json
{
  "version": 1,
  "patterns": [
    {
      "id": "pmic-spmi-probe-stall",
      "symptoms": ["开关机压测偶发进recovery", "boot卡死无指纹"],
      "signals": ["could not increase module refcount", "同mfd父设备兄弟驱动齐-517", "reboot command 'RescueParty'"],
      "root_class": "pmic-spmi-probe时序",
      "confidence": 0.7,
      "frequency": 2,
      "negative_signals": ["recovery分区损坏(4096Bytes是读首块)", "defer timeout刷屏(常态)"],
      "cases": ["95916"]
    }
  ]
}
```

所有步骤完成,如需重新执行从 Step 0 开始。
