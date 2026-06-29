# Step 1: 选择图形对象（MANDATORY）

**这是最关键的一步！选对 shape，事半功倍。选错 shape，后续全部重来。**

## 可用 Shapes

D2 内置 shapes：`rectangle`, `square`, `page`, `parallelogram`, `document`, `cylinder`, `queue`, `package`, `step`, `callout`, `stored_data`, `person`, `diamond`, `oval`, `circle`, `hexagon`, `text`, `code`, `class`, `sql_table`, `image`, `sequence_diagram`, `cloud`

详细语法见 `references/d2-shapes-guide.md`

## 图表类型 → Shape 映射表

| 图表类型 | 推荐 shapes | 核心语法 | 模板 |
|----------|------------|----------|------|
| 流程图 | `oval` + `rectangle` + `diamond` | diamond=决策, oval=起止 | `flowchart.d2` |
| 架构图 | `rectangle` + `cylinder` + `cloud` | cylinder=数据库, cloud=外部服务 | `system-architecture.d2` |
| ER 图 | `sql_table` | sql_table 内置字段支持 | `er-diagram.d2` |
| **UML 类图** | **`shape: class`** | 字段/方法/可见性/继承 | **`class-diagram.d2`** |
| 序列图 | `sequence_diagram` | 内置生命线/消息语法 | `sequence-diagram.d2` |
| 状态机 | `oval` + `rectangle` | oval=状态, rectangle=转换 | `state-machine.d2` |
| 甘特图 | `rectangle` + 时间轴 | 横向时间线布局 | `gantt-chart.d2` |
| 网络拓扑 | `rectangle` + `cloud` + `cylinder` | 物理设备+网络连接 | `network-topology.d2` |

**参考文档**: https://d2lang.com/tour/text/

## UML 类图特殊语法

**必须**使用 `shape: class`，参考 https://d2lang.com/tour/uml-classes/

```d2
User: {
  shape: class
  +id: int              # + = public
  -name: string         # - = private
  #email: string        # # = protected
  +login(): bool        # 方法：括号+返回类型
}

# 继承箭头（空心 triangle）
Admin -> User: 继承 {
  target-arrowhead.shape: triangle
  target-arrowhead.style.filled: false
}

# 组合关系
User -> Order: 下单 {
  source-arrowhead: 1
  target-arrowhead: 1..*
}
```

**禁止**：用 `shape: rectangle` + 手动 label 拼接类图。

## 检查清单

- [ ] 图表类型是否明确？
- [ ] 是否选择了对应的 shape？（如类图必须用 `shape: class`）
- [ ] 是否有对应模板可复用？（查 `assets/templates/`）
- [ ] 是否需要组合多个 shapes？

## 下一步准备

确认 shape 后，准备好：节点列表、关系列表、布局方向（`direction: down` 或 `right`）

---

**完成后，读取 workflows/step-02-write-code.md 继续**
