# Step 1: 读取源内容

根据 Step 0 确定的输入来源，读取并解析源内容。

## 1.1 粘贴内容（已在对话中）

- 直接从对话历史中提取用户粘贴的技术文档内容
- 估算内容规模：短(<500行)、中(500-2000行)、长(>2000行)
- 如果内容非常长(>2000行)，警告用户上下文可能溢出，建议改用文件方式

## 1.2 URL 链接

### 微信公众号文章

如果 URL 是 `mp.weixin.qq.com` 域名，使用 wechat-reader MCP 工具：

```
mcp__wechat-reader__read_article(url="<url>")
```

### 普通网页

使用 `WebFetch` 工具：

```
WebFetch(url="<url>", prompt="提取这篇技术文章的完整内容，包括标题、章节结构、代码块和关键概念")
```

### 抓取失败处理

- 如果 WebFetch 返回空或报错，告知用户并建议：
  - 手动复制粘贴内容到对话中
  - 提供替代 URL
  - 如果文章需要登录，请用户截图或手动粘贴

## 1.3 本地文件

### 文件读取

- 使用 `Read` 工具读取文件
- 根据扩展名判断类型：
  - `.md` / `.txt` / `.rst` — 直接读取全文
  - `.pdf` — 使用 Read 工具，大文件指定 `pages` 参数分页读取
  - `.c` / `.h` / `.py` / `.java` 等代码文件 — 提取注释和关键结构
  - `.json` / `.yaml` — 解析配置/数据结构

### 编码检测

- 如果 Read 出现乱码，用 `file <path>` 命令检测编码
- UTF-16LE 用 `iconv -f UTF-16LE -t UTF-8` 转换
- 其他编码按 `file` 输出处理

## 1.4 内容解析

无论哪种来源，读取后提取以下信息：

1. **文档标题** — 从 h1 标题或文件/文章标题获取
2. **章节结构** — 提取全部 h1/h2/h3 标题，形成原始结构树
3. **关键术语** — 识别技术术语（函数名、类名、API 名、协议名、模块名）
4. **代码块** — 记录代码块位置和语言类型
5. **图表提示** — 标记原文中已有的图表或明显需要配图的概念

## 1.5 知识领域识别

分析源内容是否涵盖多个独立的知识领域。这对后续 Step 2 决定是否拆分输出至关重要。

### 识别方法

- **标题扫描**：扫描 h1/h2 标题，判断是否涉及多个独立主题/子系统/模块
- **术语聚类**：识别关键术语的自然聚类（如 `gpio/pinctrl/tlmm/irq` vs `i2c/qup/sda/scl` vs `spi/qup/dma/transfer`）
- **判断阈值**：如果章节数 > 5 且涉及 > 2 个明显独立的子系统或模块，标记为"多领域"

### 识别结果格式

如果识别到多领域，输出如下结构传递给 Step 2：

```
源文件: <文件名>
识别到 N 个知识领域:
  1. <领域名> — 第X-Y章, 术语: keyword1, keyword2, ...
  2. <领域名> — 第X-Y章, 术语: keyword1, keyword2, ...
  ...
```

### 识别结果示例

```
源文件: qualcomm-peripherals.md
识别到 4 个知识领域:
  1. GPIO 子系统 — 第2-4章, 术语: gpio, pinctrl, tlmm, irq, gpiochip
  2. I2C 总线 — 第5-7章, 术语: i2c, qup, sda, scl, i2c_msg, bitrate
  3. SPI 控制器 — 第8-10章, 术语: spi, qup, dma, transfer, cs, mosi
  4. UART 串口 — 第11-12章, 术语: uart, baud, console, msm_geni, tx/rx
```

### 单领域处理

如果源内容为单一主题（章节内聚、术语无明显聚类），传递 `single_area: true` 给 Step 2，Step 2 直接走原有单文档流程，不弹出分拆询问。

## 1.6 按内容确定 Notes 输出子路径

读取完源并完成领域识别后，确定最终写入路径。详见 `references/obsidian-guide.md` §6。

### a. 扫描 Notes 已有结构

```bash
# notes_root 来自 Step 0.4（80-Notes 或已检测到的 NN-Notes）
find "<notes_root>" -type d -maxdepth 3 2>/dev/null | head -80
```

同时可参考 vault 顶层领域目录名（如 `03-Kernel/`、`06-Debug/`、`05-Hardware/`）作为子路径命名提示。

### b. 提出推荐子路径

根据标题、术语聚类、领域名，生成推荐，例如：

| 内容特征 | 推荐子路径（相对 notes_root） |
|---------|------------------------------|
| MMU / 页表 / TLB | `Kernel/MMU/` |
| DMA / IOMMU | `Kernel/DMA/` |
| GPIO / pinctrl | `Drivers/GPIO/` 或 `Hardware/GPIO/` |
| KASAN / crash / panic | `Debug/` |
| I2C / SPI / UART | `Hardware/I2C/` 等 |

向用户确认推荐路径：

```
question: "建议输出到「80-Notes/Kernel/MMU/」，是否采用？"
header: "输出子路径"
options:
  - label: "采用推荐路径"
    description: "写入 80-Notes/Kernel/MMU/<标题>.md"
  - label: "改用已有目录"
    description: "从 Notes 下已有子目录中选"
  - label: "自定义子路径"
    description: "相对 Notes 根输入子路径，如 Drivers/USB/"
```

若 Step 0.5 标题已定，最终文件为 `<notes_root>/<子路径>/<标题>.md`。

### c. 目录不存在 → 必须交互（禁止静默创建）

推荐或自定义子路径中，任一缺失层级：

```
question: "目录「80-Notes/Kernel/DMA/」不存在，如何处理？"
header: "创建目录"
options:
  - label: "创建该目录"
    description: "mkdir -p 后继续"
  - label: "改用已有目录"
    description: "选一个已存在的 Notes 子目录"
  - label: "自定义路径"
    description: "重新指定子路径"
```

**仅在用户选择「创建该目录」或选定已有/有效自定义路径后**，才 `mkdir -p` 并继续。用户拒绝创建且未给替代路径 → 停在本步，不写文件。

### d. 多领域 / 多文档

若 Step 1.5 识别多领域且后续拆分为多篇：为**每一篇**独立跑 b→c，各自确认子路径。

将最终 `output_dir`（含 notes_root + 子路径）传给 Step 2–6。

将提取结果、领域识别结果和 `output_dir` 作为上下文传递给 Step 2。

**完成后，读取 `workflows/step-02-outline.md` 继续。**
