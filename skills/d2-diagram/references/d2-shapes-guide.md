# D2 Shapes 语法指南

## 基础形状

### rectangle（默认）
```d2
box: 矩形
```

### square
```d2
sq: 正方形 {
  shape: square
}
```

### oval
```d2
start: 开始 {
  shape: oval
}
```

### circle
```d2
node: 节点 {
  shape: circle
}
```

### diamond
```d2
decision: 决策 {
  shape: diamond
}
```

### hexagon
```d2
process: 处理 {
  shape: hexagon
}
```

## 文档和信息

### text
```d2
desc: 说明文字 {
  shape: text
}
```

### code
```d2
snippet: 代码片段 {
  shape: code
  language: python
}
```

### document
```d2
doc: 文档 {
  shape: document
}
```

### page
```d2
pg: 页面 {
  shape: page
}
```

### callout
```d2
tip: 提示 {
  shape: callout
}
```

## 数据存储

### cylinder（数据库）
```d2
db: 数据库 {
  shape: cylinder
}
```

### sql_table（ER 图）
```d2
users: users {
  shape: sql_table
  id: int {constraint: primary_key}
  name: string
  email: string {constraint: unique}
}
```

### stored_data
```d2
cache: 缓存 {
  shape: stored_data
}
```

## 系统架构

### cloud（外部服务）
```d2
aws: AWS {
  shape: cloud
}
```

### queue（消息队列）
```d2
mq: 消息队列 {
  shape: queue
}
```

### package（模块）
```d2
module: 核心模块 {
  shape: package
}
```

### step（步骤）
```d2
s1: 步骤一 {
  shape: step
}
```

## UML

### class（类图）
```d2
User: {
  shape: class
  +id: int
  -name: string
  #email: string
  +login(): bool
}

# 继承
Admin -> User: 继承 {
  target-arrowhead.shape: triangle
  target-arrowhead.style.filled: false
}

# 组合
User -> Order: 下单 {
  source-arrowhead: 1
  target-arrowhead: 1..*
}
```

可见性修饰符：`+` public, `-` private, `#` protected

### sequence_diagram（序列图）
```d2
x: {
  shape: sequence_diagram
  # 序列图有专用的生命线和消息语法
}
```

## 特殊

### person
```d2
user: 用户 {
  shape: person
}
```

### image
```d2
logo: {
  shape: image
  icon: https://example.com/logo.png
}
```

### parallelogram
```d2
io: 输入输出 {
  shape: parallelogram
}
```
