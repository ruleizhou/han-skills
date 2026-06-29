# /han-llm-wiki mode —— 方法论模式管理

查看或切换 wiki 的组织方法论模式。模式决定后续 ingest、save 创建页面时的归档路径。

**触发条件：**
- `/han-llm-wiki mode` — 查看当前模式
- `/han-llm-wiki mode <模式名>` — 切换到指定模式
- 用户说「切换模式」「当前什么模式」「设置 wiki 模式」「改成 PARA 模式」等

**模式说明：**

| 模式 | 适用人群 | 归档特点 |
|------|---------|---------|
| `engineering` | 嵌入式/内核工程师 | 按领域分类（Issues/Debug/Tools/Domains） |
| `generic` | 通用知识管理 | 标准 source/entity/concept 分类 |
| `lyt` | 概念密集型知识库 | MOC 地图导航，笔记平铺链接 |
| `para` | 项目管理型 | 按可操作性组织（Projects/Areas/Resources/Archives） |
| `zettelkasten` | 学术研究者 | 原子笔记 + 唯一 ID，纯平结构 |

---

## 查看当前模式（无参数）

读取 `wiki/.mode.json`：
- 文件存在 → 输出当前模式名称 + 简短描述
- 文件不存在 → 当前为 `engineering`（默认），建议运行 `init` 或 `switch` 显式设置

输出格式：
```
📂 当前 wiki 模式：engineering
   Engineering — 按工程领域分类（Issues/Debug/Tools/Domains）
   适合：嵌入式/内核工程师
```

---

## 切换模式（有参数）

`/han-llm-wiki mode <模式名>`，如 `/han-llm-wiki mode para`

### 流程

1. **验证模式名**：检查是否在 5 种模式之一。不在则列出可用模式并提示用户
2. **确认切换**：使用 `AskUserQuestion` 工具确认（不要用文本 `yes/no` 输入）：

```
AskUserQuestion:
  question: "确认将 wiki 模式切换为 {新模式}？已有文件不会被移动，仅影响后续 ingest/save 的归档路径。"
  header:  "确认切换"
  multiSelect: false
  options:
    1. label: "确认切换"
       description: "切换到 {新模式} 模式，后续新页面按新模式归档"
    2. label: "取消"
       description: "保持当前模式不变"
```

- 用户选「取消」→ 退出，不修改任何文件
- 用户选「确认切换」→ 继续步骤 3
3. **更新模式文件**：写入 `wiki/.mode.json`，更新 `mode` 和 `configured_at`
4. **创建新模式的目录**（如果尚不存在）：
   - `lyt` → `wiki/mocs/`、`wiki/notes/`
   - `para` → `wiki/projects/`、`wiki/areas/`、`wiki/resources/`、`wiki/archives/`
   - `zettelkasten` → 不需要（纯平结构）
   - `engineering`/`generic` → 补建缺失的标准目录
5. **确认完成**：
   ```
   ✅ 模式已切换为：{新模式}
   新 ingest/save 将按新模式归档页面。
   已有文件保持不变。如需迁移，请手动移动。
   ```

### 模式配置文件格式

`wiki/.mode.json`：
```json
{
  "schema_version": 1,
  "mode": "engineering",
  "configured_at": "2026-06-13T16:00:00"
}
```

---

## 模式路由表

以下表格定义了各模式下新页面的归档路径。ingest 和 save 命令在创建页面时必须参考此表。

| 内容类型 | engineering | generic | lyt | para | zettelkasten |
|---------|------------|---------|-----|------|-------------|
| 来源摘要 | `wiki/sources/` | `wiki/sources/` | `wiki/notes/` | `wiki/resources/<topic>/` | `wiki/<ID>-<slug>.md` |
| 概念页面 | `wiki/concepts/` | `wiki/concepts/` | `wiki/notes/` | `wiki/resources/concepts/` | `wiki/<ID>-<slug>.md` |
| 实体页面 | `wiki/entities/` | `wiki/entities/` | `wiki/notes/` | `wiki/resources/people/` | `wiki/<ID>-<slug>.md` |
| 分析页面 | `wiki/analyses/` | `wiki/analyses/` | `wiki/notes/` | `wiki/resources/` | `wiki/<ID>-<slug>.md` |
| 对话保存 | `*会话目录*` | `wiki/sessions/` | `wiki/notes/` | `wiki/projects/inbox/` | `wiki/<ID>-session-<topic>.md` |
| 知识卡片 | `wiki/cards/` | `wiki/cards/` | `wiki/notes/` | `wiki/resources/cards/` | `wiki/<ID>-card-<slug>.md` |
