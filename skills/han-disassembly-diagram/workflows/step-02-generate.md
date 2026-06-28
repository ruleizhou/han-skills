# Step 2: 生成提示词并出图

套拆解图模板生成提示词,调 han-imagen 出图。

## 2.1 生成提示词

读取并组合:
- [references/prompt-template.md](../references/prompt-template.md) —— 拆解图模板(target_object / aspect / lang / mode / structured_content / accuracy_note)
- [references/text-legibility.md](../references/text-legibility.md) —— 中文清晰度约束
- `structured-content.md` —— 实际内容
- `analysis.md` 里 Step 1 确认的参数

生成 `prompts/disassembly-diagram.md`。提示词必须明确要求:

- 清晰简体中文排版,无乱码/重叠/微小不可读标签
- 外观视图 + 爆炸/剖面结构 + 局部放大 + 材料提示 + 功能区域 + 原理流程箭头(mode 允许时)
- 干净白色 / 浅灰 / 浅蓝灰背景
- 不确定内部 → 标注为示意图解说

## 2.2 参考图(可选)

`assets/` 下若有对象实物图 → 复制到 `refs/01-ref.png`,提示词说明作为视觉锚点。无则不用。

## 2.3 调 han-imagen 出图

**优先 Python 后端**(有 key 时):

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/han-imagen/scripts/main.py \
  --promptfiles disassembly-diagram/{slug}/prompts/disassembly-diagram.md \
  --image {slug}-disassembly-diagram.png \
  --ar <aspect> --quality 2k --json
```

- 有参考图追加 `--ref disassembly-diagram/{slug}/refs/01-ref.png`。
- 产物落 `~/Downloads/han-skill-imagen/{slug}-disassembly-diagram.png`。

**无 key 时 fallback**:Codex 内置生图工具 / 运行时生图工具。都没有就输出提示词并说明缺后端。

**完成后,读取 [step-03-report.md](step-03-report.md) 继续。**
