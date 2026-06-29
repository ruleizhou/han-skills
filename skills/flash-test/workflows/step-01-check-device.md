# Step 1: 检测设备

通过 adb 确认连接并获取 UFS 型号（供 Step 0 规格匹配回填）。详细 Flash 信息（model / rev / manufacturer_id / wb）由 `ufs_test.sh` 内部自采并写入结果文件，本步不重复采集。

## 1.1 确认连接与 root

```bash
adb devices                       # 确认设备处于 device 状态
adb shell "su root id"            # 确认 uid=0(root)
```

无设备提示连接；无 root 提示需 root 才能直写块设备。

## 1.2 获取 UFS 型号（供规格匹配）

```bash
adb shell "su root cat /sys/block/sda/device/model"   # 如 CY14-64G / SDINFDK4-64G
adb shell "su root cat /sys/block/sda/device/rev"
```

> 若 Step 0 选择「按型号匹配」，用此型号查 `data/patterns.json` → `device_profiles.<model>.spec`，回填 `SPEC_SEQREAD / SPEC_SEQWRITE / SPEC_RANDREAD / SPEC_RANDWRITE` 4 个值，交给 Step 2.3。

## 1.3 确认块设备

```bash
adb shell "su root readlink /dev/block/by-name/userdata"
```

确认指向裸分区（脚本内部据此定位读写目标；读裸 userdata、写优先裸 rawdump）。

## 1.4 fio 就绪检查（可选）

```bash
adb shell "ls -la /data/local/tmp/fio" 2>/dev/null
```

若不存在，Step 2 会从 skill 的 `references/` 推送预编译 fio。

完成后，读取 `workflows/step-02-setup-env.md` 继续。
