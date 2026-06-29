# Step 8: 提出修复建议

修复建议以 **unified diff** 格式呈现，但**不自动应用**。等用户确认后再改代码。

对于 init/probe 阶段的修复，**在 diff 前附上执行顺序分析**：
```
init_call 序列:
  module_init()          → 你的修复放在这里
  └─ xxx_probe()         → cfg_update 在这里会覆盖你的设置
     └─ xxx_post_init()  → log 在这里打印，修复当时还没跑

时间线验证: [PASS/FAIL - 说明]
```

**完成后，读取 `workflows/adversarial-verify.md` 的 B 节，启动修复方案对抗验证。**
