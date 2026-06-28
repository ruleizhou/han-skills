# Step 2: 生成提示词并出图

套模板生成提示词,调 `han-imagen` 出图。

## 2.1 生成提示词

读取并组合:
- [references/prompt-template.md](../references/prompt-template.md) —— 提示词骨架
- [references/text-legibility.md](../references/text-legibility.md) —— 中文清晰度约束(防乱码)
- `structured-content.md` —— 实际内容
- `analysis.md` 里 Step 1 确认的参数

生成 `prompts/infographic.md`,结构:

- **Image Specs**:Type=infographic / Layout / Style / Aspect / Language
- **Visual Direction**:来自所选 style 的视觉描述
- **Layout Structure**:来自所选 layout 的结构描述
- **Content**:`structured-content.md` 的各模块
- **Required Text Labels**:所有要显示的中文文字(逐条列出,原样保留)
- **Rendering Requirements**:中文清晰度约束(标准黑体类字体、禁装饰字体等)

## 2.2 角色参考图(可选)

- 若 `assets/` 下放了参考图(如 `mascot.png`)→ 复制到 `refs/01-ref.png`,在提示词 frontmatter 声明 `references`,正文说明作为风格锚点。
- 无图 → 跳过,提示词不含任何角色绑定(skill 保持中立)。

## 2.3 调 han-imagen 出图

**优先 Python 后端**(有 han 作用域 key 时):

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/han-imagen/scripts/main.py \
  --promptfiles infographic/{slug}/prompts/infographic.md \
  --image {slug}-infographic.png \
  --ar <aspect> --quality 2k --json
```

- provider 由 han-imagen 自动检测(按可用 key);可用 `--provider openai|google` 强制。
- 有参考图则追加 `--ref infographic/{slug}/refs/01-ref.png`。
- 产物由 han-imagen 落到 `~/Downloads/han-skill-imagen/{slug}-infographic.png`(自动按内容 slug 命名 + 去重)。

**无 key 时 fallback**:

1. Codex 内置 imagen / 生图工具,或当前运行时的生图工具;
2. 把 `prompts/infographic.md` 的内容作为提示词喂给它,并把产物移动/保存到 `~/Downloads/han-skill-imagen/{slug}-infographic.png`。

若既无 key 又无运行时工具,把准备好的提示词输出给用户,说明缺少后端。

**完成后,读取 [step-03-report.md](step-03-report.md) 继续。**
