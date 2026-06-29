#!/system/bin/sh
#
# UFS 精准顺序/随机读写速率测试
# 用法（将 fio 和本脚本放到 /data/local/tmp 后执行）:
#   交互:        adb shell su root sh /data/local/tmp/ufs_test.sh
#   非交互+规格透传: adb shell su root env BATCH=1 SPEC_SEQREAD=1100 SPEC_SEQWRITE=550 \
#                       SPEC_RANDREAD=30000 SPEC_RANDWRITE=60000 sh /data/local/tmp/ufs_test.sh
#
# BATCH=1 跳过交互提示，全部参数用默认值或环境变量；所有参数均可用环境变量覆盖
# 结果输出到 /data/local/tmp/ufs_test_result.txt（机器可读统计: /data/local/tmp/.ufs_stat.tmp）
#
# 测试要点：
#   - 顺序读/写各跑 numjobs=1/2/4/8 四档（找带宽封顶，排除 CPU/队列瓶颈）
#   - 每档预热1轮 + 正式3轮取中位数（min/med/max）
#   - 随机读/写 bs=4K 测 NAND 裸 IOPS
#   - 写裸 rawdump 分区（绕过 f2fs+dm 加密，不损坏 userdata），不可用回退文件
#   - 读裸 userdata 块设备（含 UFS read-ahead 加成，UFS 通病，规格亦含）
#   - Android fio 仅 psync 引擎（QD1），iodepth 被忽略，靠 numjobs 凑并发
#

FIO="/data/local/tmp/fio"
RESULT_FILE="/data/local/tmp/ufs_test_result.txt"
TESTFILE="/data/local/tmp/testfile"
STAT_FILE="/data/local/tmp/.ufs_stat.tmp"

# ---------- 默认参数（均可用环境变量覆盖，如 BATCH=1 SPEC_SEQREAD=1100 sh 本脚本）----------
SEQ_BS="${SEQ_BS:-512K}"
SEQ_SIZE="${SEQ_SIZE:-1G}"
IODEPTH="${IODEPTH:-32}"            # sync 引擎忽略，仅对标规格条件
NUMJOBS_LIST="${NUMJOBS_LIST:-1 2 4 8}"  # 顺序读/写各跑这四档（含空格，勿经 adb env 传递）
RAND_BS="${RAND_BS:-4K}"
RAND_RUNTIME="${RAND_RUNTIME:-15}"       # 随机测试限时秒（time_based）
RAND_JOBS="${RAND_JOBS:-8}"             # 随机测试并发
RAND_SIZE="${RAND_SIZE:-4G}"            # 随机访问范围（大区域减少拥塞）
ROUNDS="${ROUNDS:-3}"                   # 每档正式轮数（取中位数）
CPU_AFFINITY="${CPU_AFFINITY:-0-5}"     # CPU 绑核（6 核）
# 规格对标（默认 CY14-64G，换芯片用环境变量覆盖或交互修改）
SPEC_SEQREAD="${SPEC_SEQREAD:-820}"     # 顺序读 MB/s
SPEC_SEQWRITE="${SPEC_SEQWRITE:-520}"   # 顺序写 MB/s (WB)
SPEC_RANDREAD="${SPEC_RANDREAD:-35000}" # 随机读 IOPS
SPEC_RANDWRITE="${SPEC_RANDWRITE:-80000}" # 随机写 IOPS

# ---------- 交互输入（回车使用默认值；BATCH=1 时跳过，全用默认/环境变量值）----------
if [ "${BATCH:-0}" != "1" ]; then
    echo ""
    echo "===== UFS 测试参数配置（直接回车使用 [默认值]）====="
    echo "  --- 顺序参数 ---"
    printf "  顺序读写 bs        [%s]: " "$SEQ_BS";        read v; [ -n "$v" ] && SEQ_BS="$v"
    printf "  顺序读写 size      [%s]: " "$SEQ_SIZE";      read v; [ -n "$v" ] && SEQ_SIZE="$v"
    printf "  iodepth            [%s]: " "$IODEPTH";       read v; [ -n "$v" ] && IODEPTH="$v"
    echo "  --- 随机参数 ---"
    printf "  随机读写 bs        [%s]: " "$RAND_BS";        read v; [ -n "$v" ] && RAND_BS="$v"
    printf "  随机读写 size      [%s]: " "$RAND_SIZE";      read v; [ -n "$v" ] && RAND_SIZE="$v"
    printf "  随机读写 numjobs   [%s]: " "$RAND_JOBS";      read v; [ -n "$v" ] && RAND_JOBS="$v"
    echo "  --- 规格对标（换芯片请修改）---"
    printf "  顺序读规格 MB/s    [%s]: " "$SPEC_SEQREAD";   read v; [ -n "$v" ] && SPEC_SEQREAD="$v"
    printf "  顺序写规格 MB/s    [%s]: " "$SPEC_SEQWRITE";  read v; [ -n "$v" ] && SPEC_SEQWRITE="$v"
    printf "  随机读规格 IOPS    [%s]: " "$SPEC_RANDREAD";  read v; [ -n "$v" ] && SPEC_RANDREAD="$v"
    printf "  随机写规格 IOPS    [%s]: " "$SPEC_RANDWRITE"; read v; [ -n "$v" ] && SPEC_RANDWRITE="$v"
    unset v
fi

MAX_NJ=""
for _x in $NUMJOBS_LIST; do MAX_NJ=$_x; done

# ---------- 辅助函数 ----------
echo "" > "$RESULT_FILE"
: > "$STAT_FILE"
log() { echo "$*" | tee -a "$RESULT_FILE"; }
header() {
    log ""
    log "============================================"
    log "  $*"
    log "============================================"
}
drop_caches() { sync; echo 3 > /proc/sys/vm/drop_caches 2>/dev/null; }
size_to_mb() {
    case "$1" in
        *[Gg]) echo $(( ${1%[Gg]} * 1024 )) ;;
        *[Mm]) echo $(( ${1%[Mm]} )) ;;
        *)     echo $(( ${1} / 1048576 )) ;;
    esac
}
parse_bw_mib() { sed -n 's/.*[Bb][Ww]=\([0-9.]*\)MiB\/s.*/\1/p' | head -1; }
parse_iops() {
    awk '/IOPS=/{
        match($0, /IOPS=[0-9.]+[kKmM]?/);
        s=substr($0, RSTART+5, RLENGTH-5); m=1;
        if(s~/[kK]$/){sub(/[kK]$/,"",s);m=1000}
        else if(s~/[mM]$/){sub(/[mM]$/,"",s);m=1000000}
        printf "%.0f", s*m; exit
    }'
}
# 摘要打印：$1=key前缀  $2=规格(含单位)  $3=实测单位
print_stat() {
    grep "^$1" "$STAT_FILE" | while read -r k mn md mx; do
        log "  $k : $md $3  ($mn ~ $mx $3)  [规格 $2]"
    done
}

# CPU 绑核（仅绑核集，不加 split 避免 numjobs>核数时 err=22）
CPUOPT="--cpus_allowed=$CPU_AFFINITY"

# ---------- 多轮测试（预热1轮 + 正式 ROUNDS 轮，取 min/median/max）----------
run_rounds() {
    _key="$1"; _metric="$2"; shift 2
    drop_caches
    "$FIO" "$@" >/dev/null 2>&1          # 预热轮（丢弃）
    _vals=""
    _r=1
    while [ "$_r" -le "$ROUNDS" ]; do
        drop_caches
        _out=$("$FIO" "$@" 2>&1 | tee -a "$RESULT_FILE")
        if [ "$_metric" = "iops" ]; then
            _v=$(echo "$_out" | parse_iops)
        else
            _v=$(echo "$_out" | parse_bw_mib)
        fi
        _vals="$_vals $_v"
        _r=$((_r + 1))
    done
    _stat=$(echo "$_vals" | tr ' ' '\n' | grep -v '^$' | sort -n | \
        awk '{a[NR]=$1} END{
            if(NR==0){print "N/A N/A N/A"; exit}
            mn=a[1]; mx=a[NR];
            if(NR%2==1) md=a[(NR+1)/2]; else md=(a[NR/2]+a[NR/2+1])/2;
            printf "%.1f %.1f %.1f", mn, md, mx}')
    echo "$_key $_stat" >> "$STAT_FILE"
    log "    -> $_key : min/med/max = $_stat"
}

# ---------- 本次测试参数 ----------
header "本次测试参数"
log "顺序: bs=$SEQ_BS size=$SEQ_SIZE(每job) iodepth=$IODEPTH(sync忽略) numjobs=$NUMJOBS_LIST"
log "随机: bs=$RAND_BS runtime=${RAND_RUNTIME}s numjobs=$RAND_JOBS size=$RAND_SIZE"
log "每档: 预热1轮 + 正式${ROUNDS}轮取中位数 | CPU绑核: $CPU_AFFINITY"
log "规格: 顺序读 $SPEC_SEQREAD / 写 $SPEC_SEQWRITE MB/s，随机读 $SPEC_RANDREAD / 写 $SPEC_RANDWRITE IOPS"

# ---------- 定位测试目标 ----------
header "定位测试目标"
UFS_BLK=$(readlink /dev/block/by-name/userdata 2>/dev/null)
if [ -z "$UFS_BLK" ]; then
    log "ERROR: cannot find userdata partition"; exit 1
fi
UFS_BLK="/dev/block/${UFS_BLK##*/}"
log "  读目标(裸): $UFS_BLK"

# 写目标：优先裸写 rawdump（绕过 f2fs+dm 加密），不可用回退文件
WRITE_BLK=""
RAWDUMP_BLK=$(readlink /dev/block/by-name/rawdump 2>/dev/null)
if [ -n "$RAWDUMP_BLK" ]; then
    RAWDUMP_BLK="/dev/block/${RAWDUMP_BLK##*/}"
    SEQ_TOTAL_MB=$(( $(size_to_mb "$SEQ_SIZE") * MAX_NJ ))
    RDUMP_MB=$(( $(blockdev --getsz "$RAWDUMP_BLK" 2>/dev/null) / 2048 ))  # 扇区/2048=MiB（避免 int32 溢出）
    if [ -b "$RAWDUMP_BLK" ] && ! grep -q "$RAWDUMP_BLK" /proc/mounts && [ "${RDUMP_MB:-0}" -ge "$SEQ_TOTAL_MB" ]; then
        WRITE_BLK="$RAWDUMP_BLK"
        log "  写目标(裸 rawdump): $RAWDUMP_BLK (${RDUMP_MB}MiB, 未挂载) -> 绕过 f2fs+dm ✓"
    else
        log "  WARN: rawdump($RAWDUMP_BLK) 不可用（挂载/过小/不存在），写回退文件"
    fi
fi
if [ -z "$WRITE_BLK" ]; then
    WRITE_BLK="$TESTFILE"
    log "  写目标(文件): $TESTFILE -> 经 f2fs+dm，有衰减"
fi

# ---------- UFS Flash 信息 ----------
header "UFS Flash 信息"
FLASH_MODEL=$(cat /sys/block/sda/device/model 2>/dev/null | tr -d ' ')
FLASH_REV=$(cat /sys/block/sda/device/rev 2>/dev/null | tr -d ' ')
FLASH_SIZE_SEC=$(cat /sys/block/sda/size 2>/dev/null)
FLASH_MANID=""; FLASH_SPEC=""; FLASH_WB_EN=""
for n in /sys/devices/platform/soc/*.ufshc; do
    [ -d "$n" ] || continue
    FLASH_MANID=$(cat "$n/device_descriptor/manufacturer_id" 2>/dev/null)
    FLASH_SPEC=$(cat "$n/device_descriptor/wspecversion" 2>/dev/null)
    FLASH_WB_EN=$(cat "$n/flags/wb_enable" 2>/dev/null)
    break
done
FLASH_SIZE_MIB=$((${FLASH_SIZE_SEC:-0} / 2 / 1024))
log "  model=${FLASH_MODEL:-N/A}  rev=${FLASH_REV:-N/A}  size=${FLASH_SIZE_MIB}MiB"
log "  manufacturer_id=${FLASH_MANID:-N/A}  wspecversion=${FLASH_SPEC:-N/A}  wb_enable=${FLASH_WB_EN:-N/A}"

# ---------- 切换调度器 ----------
header "I/O 调度器"
CUR_SCHED=$(cat /sys/block/sda/queue/scheduler 2>/dev/null | sed 's/.*\[\(.*\)\].*/\1/')
echo none > /sys/block/sda/queue/scheduler 2>/dev/null
log "scheduler: $CUR_SCHED -> none"

# ---------- 顺序读（裸块设备，numjobs 1/2/4/8）----------
header "顺序读测试  numjobs: $NUMJOBS_LIST  (规格 $SPEC_SEQREAD MB/s)"
for nj in $NUMJOBS_LIST; do
    run_rounds "seqread_nj$nj" bw \
        --name=seqread_nj$nj --rw=read --bs=$SEQ_BS --size=$SEQ_SIZE \
        --direct=1 --filename=$UFS_BLK --numjobs=$nj \
        --offset_increment=$SEQ_SIZE --iodepth=$IODEPTH \
        $CPUOPT --group_reporting
done

# ---------- 顺序写（裸 rawdump 或文件，numjobs 1/2/4/8 错位写）----------
header "顺序写测试  numjobs: $NUMJOBS_LIST  目标=$WRITE_BLK  (规格 $SPEC_SEQWRITE MB/s)"
if [ "$WRITE_BLK" = "$TESTFILE" ]; then
    FILE_MB=$(( $(size_to_mb "$SEQ_SIZE") * MAX_NJ ))
    log "  预创建测试文件 ${FILE_MB}MiB"
    drop_caches
    dd if=/dev/zero of=$TESTFILE bs=1M count=$FILE_MB 2>&1 | tee -a "$RESULT_FILE"
    drop_caches
fi
for nj in $NUMJOBS_LIST; do
    run_rounds "seqwrite_nj$nj" bw \
        --name=seqwrite_nj$nj --rw=write --bs=$SEQ_BS --size=$SEQ_SIZE \
        --numjobs=$nj --offset_increment=$SEQ_SIZE --direct=1 \
        --filename=$WRITE_BLK --iodepth=$IODEPTH --end_fsync=1 \
        $CPUOPT --group_reporting
done
[ "$WRITE_BLK" = "$TESTFILE" ] && rm -f "$TESTFILE"

# ---------- 随机读（裸块设备，对标规格 IOPS）----------
header "随机读测试  bs=$RAND_BS numjobs=$RAND_JOBS runtime=${RAND_RUNTIME}s  (规格 $SPEC_RANDREAD IOPS)"
run_rounds "randread" iops \
    --name=randread --rw=randread --bs=$RAND_BS --size=$RAND_SIZE \
    --direct=1 --filename=$UFS_BLK --numjobs=$RAND_JOBS \
    --iodepth=$IODEPTH --runtime=$RAND_RUNTIME --time_based \
    $CPUOPT --group_reporting

# ---------- 随机写（裸 rawdump 或文件，对标规格 IOPS）----------
header "随机写测试  bs=$RAND_BS numjobs=$RAND_JOBS runtime=${RAND_RUNTIME}s  目标=$WRITE_BLK  (规格 $SPEC_RANDWRITE IOPS)"
if [ "$WRITE_BLK" = "$TESTFILE" ]; then
    drop_caches
    dd if=/dev/zero of=$TESTFILE bs=1M count=$(size_to_mb "$RAND_SIZE") >/dev/null 2>&1
    drop_caches
fi
run_rounds "randwrite" iops \
    --name=randwrite --rw=randwrite --bs=$RAND_BS --size=$RAND_SIZE \
    --direct=1 --filename=$WRITE_BLK --numjobs=$RAND_JOBS \
    --iodepth=$IODEPTH --runtime=$RAND_RUNTIME --time_based \
    $CPUOPT --group_reporting
[ "$WRITE_BLK" = "$TESTFILE" ] && rm -f "$TESTFILE"

# ---------- 恢复调度器 ----------
header "恢复 I/O 调度器"
echo "$CUR_SCHED" > /sys/block/sda/queue/scheduler 2>/dev/null
log "scheduler restored to: $CUR_SCHED"

# ---------- 结果摘要 ----------
header "结果摘要"
log "--- 顺序读 (BW 中位数) ---"
print_stat seqread "$SPEC_SEQREAD MB/s" "MB/s"
log "--- 顺序写 (BW 中位数) ---"
print_stat seqwrite "$SPEC_SEQWRITE MB/s" "MB/s"
log "--- 随机读 (IOPS 中位数) ---"
print_stat randread "$SPEC_RANDREAD IOPS" "IOPS"
log "--- 随机写 (IOPS 中位数) ---"
print_stat randwrite "$SPEC_RANDWRITE IOPS" "IOPS"
log ""
log "测试完成！详细结果: $RESULT_FILE"
