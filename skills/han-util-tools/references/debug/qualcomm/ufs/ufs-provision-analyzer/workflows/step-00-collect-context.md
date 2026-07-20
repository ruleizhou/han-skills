# Step 0: 收集上下文

分析开始前，收集以下信息。**用 `AskUserQuestion` 一次问清，不要逐条逼问。**

## 需要收集的信息

1. **trace 文件**：是否有 `port_trace*.txt`（fh_loader port trace）？路径？
2. **provision XML**：当前用的 `provision_ufs.xml` 路径？
3. **设备 UFS 容量**：失败设备的 UFS 总容量（8/16/32/64/128/256 GB 或不确定）
4. **UFS 厂家**：失败设备 UFS 厂家（Samsung / Micron / Kioxia / YMTC / SKhynix / 不确定）
5. **报错信息**：完整报错文本（如 `UFS Error -22 (3)` / `Configure Failed slot 0`）
6. **对比设备**（可选）：是否有 OK 设备的 trace/容量/厂家作对比？

## 交互方式

用 `AskUserQuestion` 一次提 2-4 个问题，每题给 2-5 个选项 + "不确定/其他"。例如：

```
question: "失败设备的 UFS 总容量？"
options: [8GB, 16GB, 32GB, 64GB, 128GB, 不确定需先查]

question: "失败设备的 UFS 厂家？"
options: [Samsung, Micron, Kioxia, YMTC, SKhynix, 不确定]
```

## 收集完成后

把信息整理成上下文摘要，写入 `memory-bank/activeContext.md`（如存在），然后：

- 若有 trace 文件 → 读取 `workflows/step-01-trace-analysis.md` 继续
- 若无 trace 但要生成 XML → 读取 `workflows/step-03-param-tuning.md` 继续
- 若只问参数含义 → 直接读 `references/` 下对应文件回答，不走主流程

**完成后，读取 `workflows/step-01-trace-analysis.md` 继续（或按上面分支跳转）。**
