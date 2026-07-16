# Step 3: 追溯 abort 触发链

## 3.1 定位 ddr_abort() 调用者

在已加载的平台 DSF 训练代码中，搜索所有 `ddr_abort()` 调用：

```bash
grep -rn "ddr_abort()" SocPkg/{Platform}Pkg/Library/DSFTargetLib/
```

## 3.2 区分两种 abort 路径

### 路径 A：small_eye_abort 机制（最常见）

最终检查点在 `ddrss_boot_training_init_lpddr4.c:518-522`：

```c
if (training_params_ptr->small_eye_abort == 1)
{
    ddr_abort();
}
```

此场景下 `small_eye_abort` 由训练阶段设置：
- Read 训练：`ddrss_rd_dqdqs_lpddr4.c`（19 处）
- Write 训练：`ddrss_wr_dqdqs_lpddr4.c`（14 处）
- RCW 训练：`ddrss_rcw_lpddr4.c`（1 处）
- WRLVL 训练：`ddrss_wrlvl_lpddr4.c`（1 处）
- DCC 校准：`ddrss_dcc.c`（8 处）

### 路径 B：直接 abort（少见）

训练代码中直接 `ddr_abort()` 调用（通常是不可恢复错误如零眼宽）：
- `ddrss_rd_dqdqs_lpddr4.c:511, 895`
- `ddrss_wr_dqdqs_lpddr4.c:345, 1130`
- `ddrss_wrlvl_lpddr4.c:415, 730`
- `ddrss_common.c:2358`
- `ddr_target.c:265, 1257`

## 3.3 分析触发条件

读取对应文件的 small_eye_abort 行周围代码（前后各 5 行），理解触发条件：

**Read DQ-DQS DCC 检查示例（ddrss_rd_dqdqs_lpddr4.c:569-576）**：
```c
if((dqsdcc_adj >= training_params_ptr->ddr_abort.max_rd_dqs_dcc) &&
   (prfs_index==MAX_TRAINING_FREQ_INDEX))
{
    g_abort_flag = 1;
    training_params_ptr->small_eye_abort = 1;
}
```

对照 `references/threshold-guide.md` 理解每个检查的含义。

### 3.4 判断是否需要加诊断日志

- **当前无 SMALL_EYE_* 日志**：无法区分具体触发点 → 需要 Step 4 注入诊断日志
- **有 SMALL_EYE_* 日志但只有粗分类**（如只有 `RD_DQDQS`）→ 跳到 Step 5 进一步分类
- **已有精确分类日志**（如 `RD_DQDQS_DCC`）→ 跳到 Step 6 参数调优

## 下一步

- 需要加诊断 → 读取 `workflows/step-04-inject-diag.md`
- 已有精确日志 → 读取 `workflows/step-05-classify-rootcause.md`
