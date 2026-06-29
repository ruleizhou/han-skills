# Step 2: 编写 D2 代码

根据 Step 1 选择的 shapes，编写正确的 D2 代码。

## 编写流程

### 2.1 使用模板（推荐）

如果 Step 1 确认有对应模板，直接复制修改：
- 流程图 → `assets/templates/flowchart.d2`
- ER图 → `assets/templates/er-diagram.d2`
- 架构图 → `assets/templates/system-architecture.d2`
- 网络拓扑 → `assets/templates/network-topology.d2`
- 序列图 → `assets/templates/sequence-diagram.d2`
- 状态机 → `assets/templates/state-machine.d2`
- 甘特图 → `assets/templates/gantt-chart.d2`
- 类图 → `assets/templates/class-diagram.d2`

### 2.2 基础结构

```d2
# 1. 布局方向
direction: down  # 流程图/状态机用 down，架构图用 right

# 2. 全局样式（可选）
style: {
  fill: "#E3F2FD"
  stroke: "#1976D2"
  stroke-width: 2
}

# 3. 定义节点
node1: 节点1
node2: 节点2

# 4. 定义连接
node1 -> node2: 连接标签
```

### 2.3 节点语法

```d2
# 简单节点
server: 服务器

# 带样式
database: 数据库 {
  shape: cylinder
  style.fill: "#E8F5E9"
}

# 容器分组
frontend: {
  label: 前端层
  style.fill: "#E3F2FD"
  web: Web应用
  mobile: 移动应用
}
```

### 2.4 连接语法

```d2
a -> b              # 基础
a -> b: 发送数据    # 带标签
a <-> b             # 双向
a -> b -> c         # 链式
a -> b: {           # 样式化
  style.stroke: "#FF0000"
  style.stroke-dash: 5
}
```

### 2.5 中文标签规范

- 所有节点标签使用中文
- 技术术语可保留英文（PID、CPU、IPC 等）
- 描述性文字必须中文

### 2.6 布局尺寸规范

**核心原则：宽高适中，优先多行多列，拒绝单行/单列。**

| 布局模式 | 判断 | 说明 |
|----------|------|------|
| 多行多列（≥2 行 × ≥2 列） | ✅ 推荐 | 宽高均衡，视觉舒适 |
| 单行超宽（节点横向一字排开） | ❌ 避免 | 画面过扁，浪费纵向空间 |
| 单列超长（节点纵向一字排开） | ❌ 避免 | 画面过长，阅读体验差 |

**实现手段（按优先级）：**

1. **容器分组拆分行列** — 最有效的方法。用 `{}` 将节点按逻辑分组，D2 会自动将分组排列为多行多列：

```d2
# ❌ 单列超长
direction: down
a -> b -> c -> d -> e -> f

# ✅ 用容器分组实现多行多列
direction: down
group1: {
  a -> b -> c
}
group2: {
  d -> e -> f
}
group1 -> group2
```

2. **调整 direction** — `direction: right` 配合容器分组，形成「行内纵向、行间横向」的自然多列效果。

3. **near 定位约束** — 对大节点强制指定就近位置，打破默认线性排列：

```d2
a -> b
a -> c: { near: top-left }
```

**经验数值：**
- 理想宽高比：约 4:3 ~ 16:9
- 节点数 > 6 时不使用单行/单列
- 优先让 D2 自动布局，仅在必要时手动干预

## 代码质量检查

- [ ] 所有节点标签是否中文？
- [ ] 是否使用了正确的 shape？
- [ ] 连接关系是否正确？
- [ ] 大括号是否配对？
- [ ] 布局方向是否设置？
- [ ] 布局是否多行多列？（拒绝单行/单列）
- [ ] 宽高比是否适中？

## 常见错误

| 错误 | 正确做法 |
|------|----------|
| rectangle 手动拼接类图 | 使用 `shape: class` |
| 标签全英文 | 改为中文 |
| 连接没有标签 | 添加描述性标签 |
| 大括号未闭合 | 检查配对 |
| 忘记设置 direction | 根据图表类型添加 |
| 单行/单列一字排开 | 用容器分组拆成多行多列 |

---

**完成后，读取 workflows/step-03-apply-styling.md 继续**
