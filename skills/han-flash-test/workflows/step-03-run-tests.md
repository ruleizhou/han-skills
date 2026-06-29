# Step 3: 执行测试

运行 Step 2 构造的脚本调用命令，拉取结果。本 skill 以 `ufs_test.sh` 为主路径（多档 numjobs × 预热1+正式3轮取中位数 + CPU 绑核 + 裸块设备读写），单条 fio 仅作单点复测辅助。

## 3.1 主路径：运行 ufs_test.sh

执行 Step 2.3 构造的命令（约 5-8 分钟：顺序读/写各 4 档 + 随机读/写，每档预热1轮+正式3轮）：

```bash
adb shell su root env BATCH=1 \
  SPEC_SEQREAD=820 SPEC_SEQWRITE=520 \
  SPEC_RANDREAD=35000 SPEC_RANDWRITE=80000 \
  sh /data/local/tmp/ufs_test.sh
```

执行前告知用户预期耗时。

> 💡 Windows 远程设备用 `mcp__windows-remote__adb`，`args` 是单个字符串参数，整串传入即可（无需续行符）：
> `args="shell su root env BATCH=1 SPEC_SEQREAD=820 SPEC_SEQWRITE=520 SPEC_RANDREAD=35000 SPEC_RANDWRITE=80000 sh /data/local/tmp/ufs_test.sh"`

## 3.2 拉取结果文件

脚本在设备上产出两个文件，拉回本地供 Step 4 解析：

```bash
adb pull /data/local/tmp/ufs_test_result.txt .
adb pull /data/local/tmp/.ufs_stat.tmp .       # 机器可读：每行 "key min median max"
```

> 💡 MCP：`mcp__windows-remote__adb_pull`（device_path / local_path）。

**`.ufs_stat.tmp` 格式**（4 列空格分隔，供程序解析）：
```
seqread_nj1   920.3   945.0   953.1
seqwrite_nj1  448.2   451.0   454.0
randread      6050    6191    6320
randwrite     5300    5381    5450
```
key 取值：`seqread_nj{1,2,4,8}` / `seqwrite_nj{1,2,4,8}` / `randread` / `randwrite`。

`ufs_test_result.txt` 含完整 fio 原始输出 + 测试参数 + Flash 信息 + 结果摘要（带 `[规格 X]` 对标）。

## 3.3 执行注意事项

| 情况 | 处理 |
|------|------|
| 命令超时（>600s） | 终止，检查设备是否卡死 / fio 是否在跑超大文件 |
| 设备断开 | 提示重连，重新 push 后从脚本重跑（脚本幂等） |
| `ERROR: cannot find userdata partition` | 块设备路径异常，回 Step 1 核查 |
| `WARN: rawdump 不可用，写回退文件` | 写测试经 f2fs+dm 有衰减，结果需标注（非裸写） |

## 3.4 单点复测（可选）

仅当需要绕过脚本对某一项做精细复测时，参考 Step 2.4 的裸 fio 用法。单条命令无多轮取中位数，数据仅供参考。

完成后，读取 `workflows/step-04-analyze-results.md` 继续。
