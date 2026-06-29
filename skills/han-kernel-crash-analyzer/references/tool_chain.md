# 工具链备忘

ARM64 反汇编工具链的使用备忘。具体缓存数据（按工作区）参见 `data/tool_cache.json`。

## 工具优先级

| 优先级 | 工具 | 检测方式 | 说明 |
|---|---|---|---|
| 1 | `aarch64-linux-gnu-objdump` | `which aarch64-linux-gnu-objdump` | ARM64 交叉工具链 |
| 2 | `llvm-objdump` | `which llvm-objdump` | LLVM 工具链，通常已安装 |
| 3 | `objdump` | `which objdump` | 系统自带，需验证支持 ARM64 |
| 4 | crash log 内嵌 `Code:` 行 | grep `Code:` | 高通 dmesg_TZ.txt 特有 |
| 5 | Python Capstone | `python3 -c "import capstone"` | 反汇编库 |
| 6 | ARM ARM 手动解码 | — | 最后手段 |

## vmlinux 格式处理

- **PIE (shared object)**：ARM64 内核 vmlinux 常见格式，objdump 可正常处理，但 `nm` 可能返回空
- **符号表缺失**：检查 `SymbolTable/` 独立目录，或使用 `readelf -s vmlinux`
- **Section 检查**：`readelf -S vmlinux | grep -E "\.text|\.symtab"`

## 安装命令参考

```bash
# ARM64 交叉工具链 (Ubuntu/Debian)
sudo apt install binutils-aarch64-linux-gnu

# LLVM 工具链
sudo apt install llvm

# Python Capstone
pip3 install capstone
```
