# Step 3: 评估与迭代

skill 评测走**分层验证**——默认轻量「跑给你看」，重型量化按需。完整方法论见 `references/评测指南.md`，重型量化才复用官方 skill-creator。

## 3.1 创建测试用例

**轻量档（默认）**：
1. 从 `templates/evals/evals.json.template` 复制骨架到 `<skill>/evals/evals.json`
2. 编写 2–3 个真实测试 prompt（具体、带场景）
3. 按 `评测指南.md` 第二章写 expectation——可验证陈述、存疑默认 FAIL、有区分度

**重型档（按需）**：量化断言（assertions）的完整 schema 见官方 skill-creator 的 `references/schemas.md`。

## 3.2 运行评估

**轻量档（默认）**：直接用生成的 skill 跑那 2–3 个 prompt，把输出摆给用户看，问「这样对吗？哪里不对」。零术语、零 JSON，靠用户直觉反馈。

**重型档（进阶）**：要严格量化对比时，复用官方 skill-creator 流程——
1. 并行运行 with-skill 和 baseline 子代理（拆分架构 skill 的 baseline 是「完全没有该 skill」）
2. 运行期间起草量化断言、捕获 `timing.json`
3. `python -m scripts.aggregate_benchmark` 生成 benchmark
4. `eval-viewer/generate_review.py` 启动审阅（headless 用 `--static`）

## 3.3 迭代改进

看结果 → 改 skill → 重跑，直到用户满意。改进方向参考 `改进调试.md` 的诊断决策树和改进建议分类框架。

## 3.4 描述优化（可选）

优化 description 触发率：按 `评测指南.md` 第三章手工设计**触发查询集**（20 条、应触发/不应触发各半、重点设计近似负例），自测 description。

进阶可选：`python -m scripts.run_loop` 自动跑优化循环（耗时较长，仅 Claude Code 可用）。

---

**完成后，读取 `workflows/step-05-package.md`（新建 skill 跳过 Step 4）。**
