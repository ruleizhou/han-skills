# Step 2: 配置测试环境

基于 Step 0 的测试需求（含规格值）和 Step 1 的设备信息，准备测试环境。

**本 skill 以 `ufs_test.sh` 为权威测试主路径**：调度器切换、块设备/rawdump 定位、多档多轮取中位数、CPU 绑核全部由脚本内部完成。本步只负责 push 文件 + 构造非交互调用命令，**不再手动切调度器**——否则与脚本内部的「切 none → 测试 → 恢复原值」叠加，会让原始调度器（如 bfq）被永久丢成 none。

## 2.1 Push 测试文件到设备

先动态定位 skill 基础目录（见 SKILL.md「路径约定」），再推送 fio 二进制和测试脚本：

```bash
SKILL_DIR=$(for d in ~/.claude/skills/han-flash-test ~/.codex/skills/han-flash-test ~/.config/opencode/skills/han-flash-test ~/.ai_utils/skills/han-flash-test; do
  [ -f "$d/references/fio" ] && { echo "$d"; break; }
done)

adb push "$SKILL_DIR/references/fio" /data/local/tmp/fio
adb shell chmod 755 /data/local/tmp/fio

adb push "$SKILL_DIR/references/ufs_test.sh" /data/local/tmp/ufs_test.sh
adb shell chmod 755 /data/local/tmp/ufs_test.sh
```

> ✅ 验证：`adb shell "ls -la /data/local/tmp/fio /data/local/tmp/ufs_test.sh"`
>
> 💡 Windows 远程设备：先在本地跑上面的 `SKILL_DIR=...` 片段拿到绝对路径，再用 MCP 工具 `mcp__windows-remote__adb_push`（local_path / device_path 成对传入）。
>
> ⚠️ 必须用探测出的**绝对路径**（`$SKILL_DIR`）。写空变量或相对路径会导致 `adb push "/references/fio"` 失败；`$SKILL_DIR` 为空说明 skill 没装到位。

## 2.2 预检 root 与块设备

```bash
su root id                                  # 确认 uid=0(root)
readlink /dev/block/by-name/userdata        # 确认 userdata 块设备存在（脚本内部会自定位）
su root /data/local/tmp/fio --version       # 确认 fio 可执行
```

> 调度器切换由脚本内部完成（脚本会保存当前值 → 切 none → 测试完恢复），本步**不要**重复切换。

## 2.3 构造主路径调用命令（非交互 + 规格透传）

把 Step 0 确认的规格值通过**环境变量**传给脚本，`BATCH=1` 跳过交互提示。

用 `env` 前缀把变量注入脚本进程，避免 `sh -c` 的多层引号嵌套（Windows adb 转义友好）：

```bash
adb shell su root env BATCH=1 \
  SPEC_SEQREAD=820 SPEC_SEQWRITE=520 \
  SPEC_RANDREAD=35000 SPEC_RANDWRITE=80000 \
  sh /data/local/tmp/ufs_test.sh
```

**规格值来源**（Step 0 已确认，按优先级）：
1. 按设备型号查 `data/patterns.json` → `device_profiles.<model>.spec`（推荐，如 SDINFDK4-64G = 读1100 / 写550）
2. 用户依据数据手册提供
3. 默认 CY14-64G 兜底（读820 / 写520 / 随机读35000 / 随机写80000 IOPS）

**可选透传**（仅用户自定义时）：`SEQ_BS`、`SEQ_SIZE`、`RAND_BS`、`RAND_SIZE`、`RAND_JOBS`、`ROUNDS`、`CPU_AFFINITY` 等均可同名环境变量覆盖。

> ⚠️ 不要经 adb env 传 `NUMJOBS_LIST`（含空格会被 shell 截断），只用脚本默认四档 `1 2 4 8`。

记录最终命令，交给 Step 3 执行。

## 2.4 单点复测（可选，调试用）

如需绕过脚本、对单条 fio 命令做精细复测（只验证某档/某块大小），可用裸 fio。注意：需自行管理调度器与块设备定位，无多轮取中位数，数据仅供参考。

```bash
BLK=/dev/block/$(readlink /dev/block/by-name/userdata | sed 's|.*/||')
adb shell "su root /data/local/tmp/fio --name=t --rw=randread --bs=4K --size=1G \
  --direct=1 --filename=$BLK --iodepth=1 --runtime=15 --time_based"
```

> Android fio 仅 psync 引擎（QD1），`iodepth` 实际被忽略，靠 `numjobs` 凑并发。单点复测的随机 IOPS 通常远低于规格，属正常（解析见 Step 4）。

完成后，读取 `workflows/step-03-run-tests.md` 继续。
