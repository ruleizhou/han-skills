# Step 7: 案例沉淀 + 更新模式库

## 7.1 生成案例 JSON

将当前调试结果整理为案例文件，保存到 `data/cases/{platform}-{root-cause-slug}.json`：

```json
{
  "id": "{platform}-{root_cause}-{date}",
  "timestamp": "YYYY-MM-DD",
  "platform": "{平台名_PlatformPkg}",
  "project": "{项目名，如 MT582}",
  "scenario": "QDUTT DDI / 冷启动 / 其他",
  "error_code": 84,
  "trigger": "small_eye_abort",
  "root_cause_phase": "{RD_DQDQS_DCC / WR_DQDQS / RCW / WRLVL / DCC}",
  "root_cause_detail": "{具体检查条件}",
  "param_adjusted": "{参数名}",
  "threshold_before": "{旧值}",
  "threshold_after": "{新值}",
  "fix_verified": true,
  "risk_assessment": "{风险评估摘要}",
  "lessons": [
    "{经验教训 1}",
    "{经验教训 2}"
  ],
  "keywords": ["small_eye_abort", "{phase}", "{param}"]
}
```

案例文件命名示例：
- `MT582_DivarPkgLAA-RD_DQDQS_DCC.json`

## 7.2 更新 patterns.json

1. 读取 `data/patterns.json`
2. 找到匹配的 `error_code` 和 `phase`
3. 如果已存在：
   - `confidence` +1
   - 更新 `last_seen` 日期
   - 更新 `platform` 字段
4. 如果不存在：
   - 添加新 `cause` 条目
   - `confidence` 设为 `LOW`
   - 设置 `first_seen` / `last_seen`

**置信度规则**：
```
首次记录 → LOW
2 次确认 → MEDIUM
≥3 次且修复成功 → HIGH
修复失败 → confidence -1
confidence < 0 → 移除该条目
```

## 7.3 输出学习摘要

模板：

```markdown
## 案例已沉淀

**案例 ID**：[id]
**存入路径**：`data/cases/{filename}.json`
**模式更新**：patterns.json → {phase} confidence: {old}→{new}

### 可复用经验

1. [从本次调试中提取的通用经验]
2. [下次类似问题可跳过的步骤]

---
所有步骤完成。如需处理新的 DDR 训练问题，从 Step 0 重新开始。
```
