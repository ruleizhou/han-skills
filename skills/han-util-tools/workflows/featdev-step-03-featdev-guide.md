# FeatDev Step 3: 通用内核功能开发框架

## 目标

当没有对应子 skill 时，通过 6 阶段框架引导完成内核功能开发。
完成后进入反馈闭环，生成经验文档并引导创建子 skill。

## 阶段 1 — 需求分析（不可跳过）

用 AskUserQuestion 收集需求信息：

- **问题 1 — header: "功能目标"**
  - 功能描述、预期行为、应用场景
- **问题 2 — header: "约束条件"**
  - 内核版本、平台、性能要求、兼容性约束

## 阶段 2 — 代码研究

1. **定位相关子系统**：
   ```bash
   find <kernel_src> -type d -name "<subsystem>" | head -10
   ```

2. **阅读核心数据结构和 API**：
   - 头文件（`include/linux/*.h`）
   - 核心实现文件
   - 现有驱动如何使用该子系统

3. **找集成点和依赖关系**：
   ```bash
   grep -r "<api_name>" --include="*.c" -l <kernel_src>/
   grep -r "EXPORT_SYMBOL.*<api>" --include="*.c" <kernel_src>/
   ```

## 阶段 3 — 方案设计

基于代码研究，输出设计方案摘要供用户确认：

1. **数据结构**：新增/修改的结构体
2. **接口设计**：新增的函数签名、导出符号
3. **集成方式**：钩子点、回调注册、Kconfig 依赖
4. **锁策略**：需要保护的共享数据、选择的锁类型
5. **错误处理**：错误路径、资源释放策略

用 AskUserQuestion 请用户确认方案或提出修改。

## 阶段 4 — 编码实现

按确认的方案编码，关键点：

1. **Kernel Coding Style**：
   - 缩进用 Tab（8 字符宽）
   - 行宽 80 字符
   - 变量命名 snake_case
   - `checkpatch.pl` 验证

2. **资源管理**：
   - 成对分配/释放（kmalloc/kfree、get/put）
   - 使用 `devm_*` 系列函数简化资源管理
   - `goto` 错误处理模式（统一出口）

3. **并发控制**：
   - 选择合适的锁（mutex vs spinlock vs RCU）
   - 注意中断上下文限制
   - 避免死锁（锁顺序一致）

4. **日志**：
   - `dev_dbg()` / `dev_info()` / `dev_err()`
   - 支持 dynamic debug 可控输出

5. **编译集成**：
   - Kconfig / Makefile / defconfig 配置
   ```bash
   make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
   ```

## 阶段 5 — 测试验证

1. **功能测试**：
   ```bash
   # 基本加载
   insmod <module>.ko && dmesg | tail -20
   # 功能验证
   cat /sys/<interface>
   echo <command> > /sys/<interface>
   ```

2. **回归测试**：确认不影响现有功能

3. **静态检查**：
   ```bash
   scripts/checkpatch.pl --strict <patch_file>
   ```

4. **压力测试**（如适用）：长时间运行、高并发

## 阶段 6 — 学习归档

功能开发完成后，**等待用户反馈功能是否上线**。

- 用户发出"功能上线了/开发完成了/测试通过" → 读取 `workflows/feedback-loop.md`
- 用户发出其他信号 → 继续迭代

---

开发引导完成后等待用户反馈。用户发出"上线/完成"信号时，读取 `workflows/feedback-loop.md` 进入反馈闭环。
