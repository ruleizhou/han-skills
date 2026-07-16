# DDR Training 流程与数据结构

## 启动流程

```
sbl1_do_ddr_training()                        [sbl1_hw.c:331]
  ├── boot_ddr_params_is_training_required()  [检查是否需要训练]
  ├── boot_log_message("do_ddr_training, Start")
  ├── boot_ddr_do_phy_training_restore()      [恢复上次训练数据，失败则全量训练]
  ├── ddr_training_entry()                    [sbl1_ddr_training.c:83]
  │   └── boot_ddr_do_phy_training_init()
  │       └── ddr_do_phy_training_init()
  │           └── DDRSS_boot_training_lpddr4() [ddrss_boot_training_init_lpddr4.c]
  │               ├── 频率循环 (prfs_index 0→MAX)
  │               │   ├── DDRSS_rcw()         [RCW 训练]
  │               │   ├── DDRSS_wrlvl()       [写均衡训练]
  │               │   ├── DDRSS_rd_dqdqs_*()  [读 DQ-DQS 训练]
  │               │   ├── DDRSS_wr_dqdqs_*()  [写 DQ-DQS 训练]
  │               │   └── DDRSS_dcc_*()       [DCC 校准]
  │               └── 检查 small_eye_abort == 1?
  │                   └── YES → ddr_abort() → BL_VERIFY(0, BL_ERR_CORE_VERIFY) → Error 84
  ├── boot_ddr_post_training()
  └── sbl1_save_ddr_training_data()           [保存训练数据，DDI 构建跳过]
```

## 核心数据结构

### training_params_t (ddrss_training.h)

```c
typedef struct {
    // 训练阶段参数
    struct { ... } dit, dcc, ca_vref, wrlvl, rcw, rd_dqdqs, wr_dqdqs;

    // Spec-Check Abort 阈值
    struct {
        uint8 g_sed_flag;          // SED 日志开关
        uint8 rcw_range_enable;    // RCW 范围检查使能
        uint32 min_tDQSCK;         // RCW tDQSCK 最小值 (ps)
        uint32 max_tDQSCK;         // RCW tDQSCK 最大值 (ps)
        uint8 tdqs2dq_range_enable;
        uint32 min_tdqs2dq, max_tdqs2dq;
        uint8 wrlvl_delta_enable;  // WRLVL delta 检查使能
        uint8 max_dqs_cm_dcc_enable;
        uint8 max_dqs_cm_dcc;      // DQS CM DCC 上限
        uint8 max_dqs_io_dcc_enable;
        uint8 max_dqs_io_dcc;      // DQS IO DCC 上限
        uint8 max_ck_cm_dcc_enable;
        uint8 max_ck_cm_dcc;       // CK CM DCC 上限
        uint8 max_ck_io_dcc_enable;
        uint8 max_ck_io_dcc;       // CK IO DCC 上限
        uint8 max_rd_dqs_dcc_enable;
        uint8 max_rd_dqs_dcc;      // ** Read DQS DCC 上限（本次问题）**
        uint8 min_rd_eye_width_enable;
        uint8 min_rd_eye_width;    // Read 眼宽下限
        uint8 min_rd_eye_height_HP_enable;
        uint8 min_rd_eye_height_HP; // Read 眼高下限 (HP VREF)
        uint8 min_rd_eye_height_MP_enable;
        uint8 min_rd_eye_height_MP; // Read 眼高下限 (MP VREF)
        uint8 min_rd_setup_enable;
        uint8 min_rd_setup;        // Read Setup 时间下限
        uint8 min_rd_hold_enable;
        uint8 min_rd_hold;         // Read Hold 时间下限
        // ... write 方向类似字段
        uint8 small_eye_abort;     // **运行期标志：任何阶段设为 1 即触发 abort**
    } ddr_abort;

    uint8 small_eye_abort;         // 全局 small eye 标志
} training_params_t;
```

### DCC 校准流程

```
DDRSS_rd_dqdqs_1D_pbcf()  [per-bit coarse/fine]
  ├── DQS DCC 检查: dqsdcc_adj >= max_rd_dqs_dcc → SMALL_EYE_ABORT: RD_DQDQS_DCC
  ├── DQ DCD 检查:  dq_dcc_abs >= max_rd_dqs_dcc  → SMALL_EYE_ABORT: RD_DQDQS_DCC
  ├── SCREEN 5:     dq_dcc_abs >= max_dq_dcc       → SMALL_EYE_ABORT: RD_DQDQS_DCC
  ├── SCREEN 1:     眼宽 < min_rd_eye_width        → SMALL_EYE_ABORT: RD_DQDQS_EYE_WIDTH
  ├── Setup 检查:   set_up <= min_rd_setup         → SMALL_EYE_ABORT: RD_DQDQS_SETUP_HOLD
  └── Hold 检查:    hold <= min_rd_hold            → SMALL_EYE_ABORT: RD_DQDQS_SETUP_HOLD
```

## small_eye_abort 触发点统计

| 训练阶段 | 文件 | 触发点数 |
|----------|------|---------|
| RD_DQDQS | ddrss_rd_dqdqs_lpddr4.c | 19 |
| WR_DQDQS | ddrss_wr_dqdqs_lpddr4.c | 14 |
| DCC | ddrss_dcc.c | 8 |
| RCW | ddrss_rcw_lpddr4.c | 1 |
| WRLVL | ddrss_wrlvl_lpddr4.c | 1 |
| **最终检查** | ddrss_boot_training_init_lpddr4.c | 1 |
