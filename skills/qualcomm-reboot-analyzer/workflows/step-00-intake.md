# Step 0: 输入收集与证据分流

收集分析所需的最小信息集,并做转交判断。

## 必须问清/查清

1. **证据清单**(没有的项让用户补,或走 SMB 取证):
   - 串口 log(jpp/IPOP 大文本):文件路径、覆盖时长、单板号
   - logcat 包:轮数、是否含 events buffer(`-b all`)
   - 主机侧物证:采集脚本(collect_log.bat/sh)——**必读**,「谁拉起了 X」类问题第一步
2. **票面信息**:bug 单描述、复现概率(如 1/5000)、预期 vs 实际行为
3. **单板与批次**:原始复现板 vs 复测板分开记,**以票面原始复现的 log 为准绳**
   (复测板可能是同类问题的不同表现路径)
4. **软件版本**:临时版本号(userdebug/user)——userdebug 的 root/adb 语义影响推理

## 分流判断

| 情况 | 动作 |
|------|------|
| 证据里有 panic/ramdump/KASAN/tombstone dump | 停止,转 han-kernel-crash-analyzer |
| 无 dump,重启行为异常 | 本 skill 继续 |
| 两者混合(既有 dump 又有行为异常) | dump 交 crash-analyzer;行为异常部分本 skill 继续,报告中注明分界 |
| 无任何 log | 给取证清单(串口+persist logcat 落盘+复现条件),退出 |

## 大文件处理约定

- 串口大文本(几百 MB 级)只允许 grep/sed 按行号窗口取证,禁止整读
- 注意 rtk grep 的 `process terminated by signal 13`(管道截断)——统计类命令
  避免 head/tail 管道,重跑确认
- 文件含 NUL 字节会被 grep 判 binary,加 `-a` 强制文本模式

**完成后,读取 `workflows/step-01-reboot-stats.md` 继续。**
