# Step 2: 生成提示词并出图

套手绘模板生成提示词,调 han-imagen 出图。

## 2.1 生成提示词

读取并组合:
- [references/prompt-template.md](../references/prompt-template.md) —— 手绘提示词骨架(Image settings/Style/Density/Color/Design/Typography/Details/Footer/Content)
- [references/text-legibility.md](../references/text-legibility.md) —— 中文清晰度约束
- `structured-content.md` —— 实际内容
- `analysis.md` 里 Step 1 确认的参数

生成 `prompts/hand-write-pic.md`,把选定的 layout/style/aspect/lang/density + style guidance + density guidance 放在顶部,structured content 填入 Content 段。

## 2.2 风格参考图(可选)

- 选 `chubby-sketch` → 复制 [references/chubby-sketch-style.jpeg](../references/chubby-sketch-style.jpeg) 到 `refs/01-ref.png`,在提示词说明作为风格锚点。
- 其他风格 → 无参考图,提示词不含角色绑定(skill 中立,默认不绑任何角色)。

## 2.3 调 han-imagen 出图

**优先 Python 后端**(有 key 时):

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/han-imagen/scripts/main.py \
  --promptfiles hand-write-pic/{slug}/prompts/hand-write-pic.md \
  --image {slug}-hand-write-pic.png \
  --ar <aspect> --quality 2k --json
```

- 有参考图则追加 `--ref hand-write-pic/{slug}/refs/01-ref.png`。
- 产物落到 `~/Downloads/han-skill-imagen/{slug}-hand-write-pic.png`。

**无 key 时 fallback**:Codex 内置生图工具 / 当前运行时生图工具,把提示词内容喂给它,产物保存到上述路径。都没有就输出提示词并说明缺后端。

**完成后,读取 [step-03-report.md](step-03-report.md) 继续。**
