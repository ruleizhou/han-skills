# Step 1: 提取传输耗时

## 目标

从 Android logcat 中提取 `FileOperationService` 的精确耗时数据。

## 流程

### 1.1 编码检测与转换

Android logcat 通常为 UTF-16 编码，先检测并转换：

```bash
file <logfile>                    # 检测编码
iconv -f UTF-16 -t UTF-8 <logfile> 2>/dev/null | ...  # 如果是 UTF-16
```

### 1.2 提取关键事件

```bash
iconv -f UTF-16 -t UTF-8 <logfile> 2>/dev/null | grep -E \
  "am_foreground_service_start.*documentsui|am_foreground_service_stop.*documentsui"
```

### 1.3 解析耗时

`am_foreground_service_stop` 消息格式：
```
am_foreground_service_stop: [0,<service>,1,PROC_STATE_TOP,34,34,0,0,<DURATION_MS>,1,STOP_FOREGROUND,1]
```

- **第 10 个字段 `<DURATION_MS>`** 即操作耗时（毫秒），由系统精确记录
- 同时记录 `start/stop` 的**时间戳**和**时间差**作为交叉验证

### 1.4 计算速度

```
速度 (MB/s) = 文件大小 (bytes) / 耗时 (ms) × 1000 / 1048576
```

### 1.5 提取进度粒度

统计 `notification_enqueue.*documentsui` 出现次数：
```bash
... | grep -c "notification_enqueue.*documentsui"
```
- 每次进度更新 ≈ 500ms，次数与耗时成正比
- 如果读写方向更新间隔一致（~500ms），说明瓶颈不在应用层

### 1.6 输出格式

```
## 传输性能数据

| 方向 | 耗时 (ms) | 速度 (MB/s) | 进度更新次数 | 每次数据量 |
|------|----------|-------------|-------------|-----------|
| 读   | X,XXX    | XX.X        | XX          | ~XX.X MB  |
| 写   | XX,XXX   | XX.X        | XX          | ~XX.X MB  |

读写速度比: X.XXx
```

---

完成后，读取 `workflows/step-02-protocol-check.md` 继续。
