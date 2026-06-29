#!/usr/bin/env bash
# SessionStart hook — print available han skills as a quick reference.
# Runs once per session start. Output goes to the user-visible session log.

cat <<'EOF'
🛠 han skills available — 触发关键词速查:
  skill-creator-plus  创建自学习 (feedback loop) + 按需拆分 (SKILL.md 路由 + workflows/) 的 skill
    触发:"创建一个能自学习的 skill"、"拆解 SKILL.md"、"skill 怎么做按需加载"、
         "为已有 skill 添加自学习/拆分架构"、"改进调试已有 skill"
  llm-wiki            个人知识库 Wiki 维护 (init/ingest/query/lint/card/weekly/research/mode/think/save)
    触发:"/llm-wiki"、"收录到 wiki"、"wiki 健康检查"、"抽一张卡"、"写周报"、
         "研究一下"、"保存这段"、"深度思考"、"切换到 PARA"
  kernel-crash-analyzer-v2  Linux 内核崩溃分析 (高通/Android: NULL 指针/KASAN UAF/SLUB/ABBA 死锁/panic/ramdump)
    触发:"kernel crash"、"死机"、"ramdump"、"KASAN"、"kernel panic"、
         "NULL pointer"、"deadlock"、"问题解决了"、"修好了"
  d2-diagram           D2 声明式图表 (流程图/架构图/ER/类图, sketch 手绘风, PNG+SVG)
    触发:"画个流程图"、"架构图"、"ER 图"、"类图"、"把这段转成图表"、
         "D2 怎么画"、"sketch 手绘风"、"生成手绘风格"
  git-commit           交互式 Git 提交信息生成器 (基于 ~/.git-template)
    触发:"git commit"、"提交代码"、"生成 commit"、"写 commit message"、"帮我提交"
  flash-test           UFS/eMMC 读写速率测试 (顺序/随机, 规格对标)
    触发:"测 UFS 速度"、"测闪存"、"跑性能"、"看带宽"、"存储测试"、
         "跑 fio 测试"、"flash benchmark"、"再看结果"
EOF
