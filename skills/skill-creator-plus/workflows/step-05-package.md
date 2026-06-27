# Step 5: 打包

打包流程**直接复用官方 skill-creator**。

## 5.1 打包

检查是否有 `present_files` 工具可用。如果有，运行：

```bash
python <skill-creator-path>/scripts/package_skill.py <path/to/skill-folder>
```

`package_skill.py` 位于官方 skill-creator 的 scripts 目录：
`~/.claude/plugins/marketplaces/anthropic-agent-skills/skills/skill-creator/scripts/package_skill.py`

打包产出 `.skill` 文件，告知用户路径。

## 5.2 最终检查清单

打包前确认：

- [ ] SKILL.md ≤ 100 行（路由层精简）
- [ ] 每个步骤末尾有正确的 `完成后，读取 XXX 继续` 链接
- [ ] Workflow 表格完整覆盖所有步骤
- [ ] 如启用了自学习：`data/patterns.json` 已初始化，feedback-loop.md 已生成
- [ ] description 包含完整的触发信号列表（含反馈闭环信号）
- [ ] `evals/evals.json` 有测试用例

---

**打包完成。读取 `workflows/step-06-ship.md` 继续——把 skill 装好、自测触发。**
