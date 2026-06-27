#!/usr/bin/env bash
# SessionStart hook — print available han skills as a quick reference.
# Runs once per session start. Output goes to the user-visible session log.

cat <<'EOF'
🛠 han skills available — 触发关键词速查:
  skill-creator-plus  创建自学习 (feedback loop) + 按需拆分 (SKILL.md 路由 + workflows/) 的 skill
    触发:"创建一个能自学习的 skill"、"拆解 SKILL.md"、"skill 怎么做按需加载"、
         "为已有 skill 添加自学习/拆分架构"、"改进调试已有 skill"
EOF
