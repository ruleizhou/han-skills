# Step 5: 案例收录（自学习）

## 任务

把本次排查蒸馏成案例存档 + 更新模式库，让下次更快。

## 5.1 案例存档（双格式，内容一致）

**JSON（机读索引）** → `data/cases/<YYYYMMDD-HHMMSS>-<类别>.json`：

```json
{
  "id": "<YYYYMMDD-HHMMSS>",
  "timestamp": "<ISO8601>",
  "input_summary": "<失败项+器件+平台一句话>",
  "process_steps": ["步骤1", "..."],
  "key_findings": ["发现1", "..."],
  "final_result": "<结果>",
  "result_assessment": "success | partial | failed",
  "platform": "<平台/内核>",
  "flash_device": "<料型号 UFS版本 mid>",
  "fail_tests": ["<test_id>"],
  "root_cause_categories": ["<类别>"],
  "fix": "<修复一句话>",
  "report_path": "<报告路径>"
}
```

**Markdown（人读）** → 已在 Step 4 作为排查报告输出到工作目录，登记路径即可。

## 5.2 更新 patterns.json

- 本次**验证有效**的模式（实验实锤 + 修复见效）：匹配已有 → `confidence += 1, frequency += 1, last_seen 更新`；无匹配 → 追加新模式（confidence: 1）
- 本次**被证伪**的模式：`confidence -= 1`，<0 移除
- diff preview 给用户 review 后再写入

## 5.3 更新领域知识

新机制/新坑（如新料的 quirk 行为、新的测试陷阱）追加到 `references/ufs-clkscale-mechanism.md` 对应章节。

**注意**：patch 见效前的案例 `result_assessment` 记 `partial`（根因实锤但修复未验证），等用户反馈"修好了"由 feedback-loop 升级。

所有步骤完成。如需重新执行从 Step 0 开始。

**反馈闭环由用户主动触发（"修好了/验证通过了/根因确认了"），触发后读取 `workflows/feedback-loop.md`。**
