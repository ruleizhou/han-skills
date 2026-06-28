# Step 3: 输出报告

出图完成,汇报产物。

## 3.1 报告内容

向用户输出:

- **主题**:来自 analysis.md
- **参数**:layout / style / aspect / lang
- **最终图片**: `~/Downloads/han-skill-imagen/{slug}-infographic.png`
- **生成文件清单**:
  - `infographic/{slug}/source-{slug}.md`
  - `infographic/{slug}/analysis.md`
  - `infographic/{slug}/structured-content.md`
  - `infographic/{slug}/prompts/infographic.md`
  - (可选)`infographic/{slug}/refs/01-ref.png`

## 3.2 后续提示

- 不满意 → 调整参数(换 layout/style/aspect)后重跑 Step 2,无需重做 Step 0。
- 满意 → 可主动说「这版不错 / 就用这版」触发反馈闭环,把经验沉淀到 patterns.json。

**完成后,读取 [step-04-learn.md](step-04-learn.md) 继续(自动收录,不弹反馈)。**
