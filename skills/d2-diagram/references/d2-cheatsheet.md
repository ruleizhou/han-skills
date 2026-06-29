# D2 Syntax Cheatsheet

## Basic Structure

```d2
direction: down  # or right, left, up

node1: Label text
node2: Another node

node1 -> node2: connection label
```

## Shapes

```d2
# Rectangle (default)
box: Rectangle

# Oval/Circle
oval: Oval shape {
  shape: oval
}

# Cylinder (database)
db: Database {
  shape: cylinder
}

# Diamond (decision)
decision: Decision {
  shape: diamond
}

# Circle
circle: Circle {
  shape: circle
}

# Square
square: Square {
  shape: square
}

# Document
doc: Document {
  shape: document
}

# Parallelogram
para: Parallelogram {
  shape: parallelogram
}
```

## Styling

```d2
style: {
  fill: "#E3F2FD"        # Background color
  stroke: "#1976D2"      # Border color
  stroke-width: 2        # Border thickness
  stroke-dash: 5         # Dashed border
  fill-pattern: dots     # dots, lines, grain
  border-radius: 10      # Rounded corners
  shadow: true           # Drop shadow
  opacity: 0.8          # Transparency
}
```

## Container Groups

```d2
frontend: {
  label: Frontend Layer
  style.fill: "#E3F2FD"
  
  web: Web App
  mobile: Mobile App
}

backend: {
  label: Backend Layer
  
  api: API Server
  worker: Background Worker
}

frontend.web -> backend.api
```

## Connections

```d2
# Basic connection
a -> b

# Bidirectional
a <-> b

# Multiple connections
a -> b -> c
a -> c

# Connection with label
a -> b: sends data

# Styled connection
a -> b: {
  style: {
    stroke: "#FF0000"
    stroke-width: 3
    stroke-dash: 5
  }
}
```

## Markdown Labels

```d2
node: |md
  **Bold Title**
  - Bullet point 1
  - Bullet point 2
  
  `code snippet`
|
```

## Variables

```d2
colors: {
  primary: "#1976D2"
  secondary: "#388E3C"
}

node: {
  style.fill: colors.primary
}
```

## Icons

```d2
# Using online icons
server: Server {
  icon: https://icons.terrastruct.com/aws/Compute/EC2.svg
}
```

## Layout Options

```d2
direction: right  # Flow direction

# Layout engines:
# - dagre (default, good for flowcharts)
# - elk (good for complex diagrams)
# - tala (premium, best layouts)
```

## CLI Commands

```bash
# Basic compilation
d2 input.d2 output.png

# Sketch style
d2 --sketch input.d2 output.png

# Choose theme
d2 --theme neutral input.d2 output.png

# SVG output
d2 input.d2 output.svg

# PDF output
d2 input.d2 output.pdf

# Watch mode (auto-regenerate)
d2 --watch input.d2 output.png
```

## Common Patterns

### System Architecture
```d2
direction: down

user: User
frontend: Frontend
backend: Backend
database: Database {
  shape: cylinder
}

user -> frontend -> backend -> database
```

### Flowchart
```d2
direction: down

start: Start {
  shape: oval
}
process: Process
decision: Decision {
  shape: diamond
}
end: End {
  shape: oval
}

start -> process -> decision
decision -> end: Yes
decision -> process: No
```

### Class Diagram
```d2
User: {
  shape: class
  -id: int
  -name: string
  +login(): bool
  +logout(): void
}

Order: {
  shape: class
  -id: int
  -total: float
  +place(): bool
}

User -> Order: has many
```
