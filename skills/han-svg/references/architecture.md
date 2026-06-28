# Architecture Layout

Use `architecture` for system components, services, and data flow.

Recommended spec:

- `nodes`: include `id`, `label`, optional `text`, and optional `group`.
- `edges`: include `from`, `to`, and optional `label`.
- Use `group` to create layered regions.

Rendering behavior:

- Groups are arranged left-to-right.
- Nodes within a group stack vertically.
- Edges render behind node boxes.
- `dark-tech` is preferred for technical diagrams; `han-light` is preferred for conceptual architecture.

## 折线优化规则

渲染器产生的边为直线(源右边缘 → 目标左边缘), 跨组对角线不够美观。渲染后需手动优化 SVG 折线路由:

### 规则 1: 不同水平线 → 折线

若源节点与目标节点不在同一水平线(y 不同), 将 `<line>` 替换为 `<path>` 折线。

### 规则 2: 源出口左右方向 → 水平延长后再折

若源节点的连线出口是左/右边缘(水平方向), 先水平延长 20px 再折弯。

```
源右边缘 (x, y) → 水平延长 (x+20, y) → 折弯(上/下)
```

### 规则 3: 目标入口左右方向 → 折线后水平接入

若目标节点的连线入口是左/右边缘(水平方向), 折线最后一段必须水平方向进入。

```
折弯 → (entry_x - 20, target_y) → 水平接入 (entry_x, target_y)
```

### 规则 4: 多线重叠 → 汇聚处合并, 短粗线统一入口

若多条边在目标入口处重叠, 在汇聚点合并为一条加粗短线(`stroke-width="3"`), 仅粗线带箭头。

```
路径A ─→ 汇聚点 ┐
                ╞══ 粗线 sw=3 → 目标(唯一箭头)
路径B ─→ 汇聚点 ┘
```

### 折线路径格式

```svg
<!-- 标准 Z 形折线: 源右边缘→水平延长→折弯→水平走→折弯→水平接入目标左边缘 -->
<path d="M {src_x} {src_y} L {src_x+20} {src_y} L {src_x+20} {bus_y} L {entry_x-20} {bus_y} L {entry_x-20} {target_y} L {entry_x} {target_y}" fill="none" stroke="#64748B" stroke-width="1.6"/>

<!-- 汇聚粗线(唯一箭头入口) -->
<line x1="{entry_x-20}" y1="{target_y}" x2="{entry_x}" y2="{target_y}" stroke="#64748B" stroke-width="3" marker-end="url(#arrow)"/>
```

### 总线选择

- **上总线 y**: 节点第 1 排底部与第 2 排顶部之间的间隙(约 `node_y + 52` 到 `node_y + 105` 之间)
- **下总线 y**: 节点第 2 排底部与第 3 排顶部之间的间隙
- 多条边共享同一总线时, 注意水平段不要重叠; 若重叠, 将其中一条改走其他层级

### 反馈回路

反馈回路(右→左方向)用虚线 + 不同颜色区分, 沿下总线走, 入口通常从目标底部进入:

```svg
<path d="..." fill="none" stroke="#F59E0B" stroke-width="1.8" stroke-dasharray="6,4" marker-end="url(#arrow-feedback)"/>
```
