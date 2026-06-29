# Step 5: 反汇编分析

**这是整个分析最关键的一步，不能跳过。**

## 工具链缓存

在执行 `which` 检查之前，先读取 `data/tool_cache.json`。如果当前内核源码路径已有缓存，直接使用缓存的工具名，跳过 `which` 步骤。分析结束后更新缓存。

## 工具选择（按优先级尝试）

`aarch64-linux-gnu-objdump` 不一定安装。按以下优先级选择工具：

```bash
# 优先级 1: 交叉工具链 objdump
aarch64-linux-gnu-objdump -dS vmlinux | grep -A 30 -B 10 '<function_name>'

# 优先级 2: LLVM objdump（通常已安装）
llvm-objdump -dS vmlinux | grep -A 30 -B 10 '<function_name>'

# 优先级 3: 系统 objdump（如果支持 ARM64 目标）
objdump -dS vmlinux | grep -A 30 -B 10 '<function_name>'

# 优先级 4: 从 crash log 中提取内嵌反汇编
# 高通 ramdump 的 dmesg_TZ.txt 通常包含 Code: 行，如:
# Code: f81f83a8 a900ffff f90003ff b4000120 (f9403808)
# 括号中的指令就是崩溃指令，可用 AArch64 手册手动解码
```

**先用 `which` 检测工具是否存在再调用，不要直接假设安装了交叉工具链。**

## 所有工具不可用时的回退

如果上述 4 个优先级全部失败：

1. `python3 -c "import capstone"` 检查 Capstone Python 反汇编库
2. 如果 Capstone 可用，用 Python 脚本反汇编 `Code:` 行中的指令
3. 如果全部不可用：从 ARM Architecture Reference Manual 手动解码 `Code:` 行
4. **诚实报告使用的方法和局限性**

## vmlinux 格式问题

ARM64 内核 vmlinux 可能是 **ELF shared object (PIE)** 格式而非 executable。如果 `nm` 或 `objdump -t` 返回空：

1. 检查 sections：`readelf -S vmlinux | grep -E "\.text|\.symtab"`
2. 若无 `.symtab`，尝试 `readelf -s vmlinux | wc -l` 确认符号总数
3. 符号表可能在独立的 `SymbolTable/` 目录中（高通 ramdump 结构）
4. 如果完全不支持，诚实告知并 fallback 到 crash log 内嵌信息 + 源码分析

## 输出要求

反汇编分析输出：
1. **崩溃指令**：精确的汇编指令和地址
2. **前后 20 条指令**：理解崩溃前的执行上下文
3. **源码行映射**：从 objdump 的 `-S` 输出或符号表映射到 `.c` 源文件的具体行号

## 工具链缓存更新

分析结束后，将本次使用的工具和内核源码路径更新到 `data/tool_cache.json`：
```json
{
  "workspaces": {
    "/path/to/kernel/source": {
      "tools": {
        "llvm-objdump": true,
        "aarch64-linux-gnu-objdump": false
      },
      "cached_at": "<ISO8601 timestamp>"
    }
  }
}
```

**完成后，读取 `workflows/step-06-source.md` 继续。**
