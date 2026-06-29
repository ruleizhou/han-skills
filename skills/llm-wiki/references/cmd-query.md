# /llm-wiki query —— 查询

基于 wiki 内容回答用户的问题。采用三阶段混合检索管线。

**触发条件：**
- 用户显式执行 `/llm-wiki query`
- 用户向 wiki 提问，如「帮我解释一下」「wiki 里有什么关于...」
- `/llm-wiki query --think` → 在回答前先过 think 循环，确保深度审视

---

## 预处理：读取热缓存

读取 `wiki/hot.md`（不存在则跳过），了解：
- **最近活跃主题** → 用于 Stage 1 上下文前缀
- **最近查询热点** → 辅助定位相关页面

---

## 三阶段检索管线

```
用户问题
   │
   ▼
Stage 1: Contextual Prefix（上下文前缀增强）
   ├─ 从 hot.md 提取「最近活跃主题」中的相关关键词
   ├─ 将上下文关键词追加到原始查询
   │   例：用户问"DMA" + hot.md 显示最近在研究"cache coherency"
   │   增强查询 → "DMA cache coherency DMA 驱动 IOMMU"
   └─ 目的：利用会话上下文提升 BM25 召回率
   │
   ▼
Stage 2: BM25 稀疏检索
   ├─ python3 wiki/scripts/wiki-search.py search "<增强后查询>" --top-k 20 --wiki .
   ├─ 取 Top-20 候选（足够的候选集用于重排序）
   └─ 如果索引不存在 → 降级：读 index.md 定位
   │
   ▼
Stage 3: Cosine Rerank（TF-IDF 余弦重排序）
   ├─ python3 wiki/scripts/wiki-search.py rerank "<原始查询>" --candidates '[...]' --top-k 5 --wiki .
   ├─ 用原始查询（不含 prefix）做语义匹配，避免前缀噪音
   ├─ 输出重排序后的 Top-5
   └─ 如果 rerank 失败 → 降级：用 BM25 原始排序
```

### 降级策略

| 故障点 | 降级行为 |
|--------|---------|
| 检索索引不存在 | 跳过 Stage 2+3，读 index.md 定位页面 |
| BM25 返回空结果 | 同降级到 index.md |
| rerank 失败/超时 | 用 BM25 Top-5 原始排序（无重排序） |
| hot.md 不存在 | Stage 1 跳过，直接用原始查询 |

---

## 流程

1. **定位相关页面**——按 Stage 3 rerank 得分顺序读取页面。得分断崖处停止（如 Top-1 0.15、Top-2 0.12、Top-3 0.01 → 只读前 2 个）。如需更广覆盖，补读 index.md
2. **综合回答**——基于多个页面的信息，给出有深度的回答
3. **标注引用**——说明信息来自哪些 wiki 页面，格式 `> 来源：[[页面名]]`
4. **建议存页**——如果查询产生了有价值的分析，主动建议 `/llm-wiki save <标题>` 归档到 `wiki/analyses/`

---

## 后处理：更新热缓存

更新 `wiki/hot.md`（不存在则跳过）：

1. 在「最近查询热点」追加本次查询关键词——如关键词已存在则频次 +1
2. 「最近查询热点」保留最近 10 条，超出时移除频次最低的旧条目
3. `session_count` +1 / 总长度 ≤ 500 词

---

**输出格式灵活：** Markdown / 比较表格 / 时间线 / Mermaid 概念图

**如果相关 wiki 页面不存在**，回退到 note 目录获取信息，明确告知用户哪些页面待建。
