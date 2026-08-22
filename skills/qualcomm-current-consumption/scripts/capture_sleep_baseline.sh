#!/usr/bin/env bash
# qualcomm-current-consumption：睡眠基线一键采集（拔 USB 前必跑）
# 打包 step-01/03/04 全部读节点：qcom_sleep_stats / mem_sleep / UFS SPM /
# wakeup_sources / GPIO / QDSS·debug 开关。产出 SUMMARY.md 供 step-05 定位矩阵。
# 用法: bash scripts/capture_sleep_baseline.sh [OUTDIR]
# 环境: ADB, ANDROID_SERIAL, MEASURED_MA=<电流表读数>, TARGET_MA=<对标/目标 mA>
set -euo pipefail

usage() {
  cat <<'EOF'
用法: bash scripts/capture_sleep_baseline.sh [OUTDIR]

参数:
  OUTDIR     采集产物输出目录（默认 ./sleep-baseline-capture）
  -h|--help  打印本帮助
  --dry-run  只打印将执行的命令与将写入的路径，不实际执行

环境变量:
  ADB             adb 命令（默认 adb）
  ANDROID_SERIAL  指定设备序列号
  MEASURED_MA     电流表实测待机电流（mA；测流后可补填 SUMMARY）
  TARGET_MA       对标机/平台目标电流（mA）

时序（关键）:
  测流需拔 USB，而 sleep_stats / spm / debug 开关必须 adb 在线时读取。
  本脚本必须在拔 USB 测流【之前】跑；电流稳定后把读数填进 SUMMARY 的 measured_ma。

退出码:
  0=success  2=env_error  3=param_error
EOF
  exit 0
}

OUT=""
DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    --dry-run) DRY_RUN=1; shift ;;
    -*) echo "Unknown arg: $1" >&2; exit 3 ;;
    *) OUT="$1"; shift ;;
  esac
done
OUT="${OUT:-./sleep-baseline-capture}"
ADB="${ADB:-adb}"
MEASURED_MA="${MEASURED_MA:-}"
TARGET_MA="${TARGET_MA:-}"

command -v "$ADB" >/dev/null 2>&1 || {
  echo "ERROR: adb not found (set ADB=/path/to/adb)" >&2
  exit 2
}

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] OUT=$OUT MEASURED_MA=${MEASURED_MA:-<unset>} TARGET_MA=${TARGET_MA:-<unset>} ADB=$ADB"
  echo "[dry-run] 将执行: qcom_sleep_stats 全节点 / mem_sleep / UFS spm / wakeup_sources / gpio / QDSS 开关"
  echo "[dry-run] 将写入: $OUT/{sleep-baseline.txt,SUMMARY.md,gpio.txt,README.txt}"
  exit 0
fi

mkdir -p "$OUT"

# 单条 adb 读取；节点不存在输出 N/A（各机型节点差异大，缺节点不是错误）
sh_cat() { $ADB shell cat "$1" 2>/dev/null | tr -d '\r' || echo "N/A"; }

# sleep_stats 输出里存在任意独立非零数字 → 该域有活动（宽松判定，精确归 step-01 1.3）
has_nonzero() { printf '%s\n' "$1" | grep -qE '(^|[[:space:]])0*[1-9][0-9]*([[:space:]]|$)'; }

SS=/sys/kernel/debug/qcom_sleep_stats
SS_NODES="$($ADB shell ls "$SS" 2>/dev/null | tr -d '\r' || true)"
UFS_PATH="$($ADB shell 'ls -d /sys/devices/platform/soc/*.ufshc 2>/dev/null' | tr -d '\r' || true)"

echo "[sleep-baseline] OUT=$OUT serial=$($ADB get-serialno 2>/dev/null || echo '?')"

aosd_out="" ; cxsd_out="" ; ddr_out=""
{
  echo "## meta"
  date -Is 2>/dev/null || date
  echo "ANDROID_SERIAL=${ANDROID_SERIAL:-}"
  echo "MEASURED_MA=${MEASURED_MA}"
  echo "TARGET_MA=${TARGET_MA}"
  $ADB shell getprop ro.build.display.id 2>/dev/null | tr -d '\r' || true
  $ADB shell getprop ro.product.model 2>/dev/null | tr -d '\r' || true

  echo "## mem_sleep (期望含 [deep])"
  sh_cat /sys/power/mem_sleep

  echo "## qcom_sleep_stats (全节点)"
  for n in $SS_NODES; do
    echo "### $n"
    out="$(sh_cat "$SS/$n")"
    printf '%s\n' "$out"
    case "$n" in aosd) aosd_out="$out" ;; cxsd) cxsd_out="$out" ;; ddr) ddr_out="$out" ;; esac
  done

  echo "## UFS spm (路径自动探测: ${UFS_PATH:-<none>})"
  if [[ -n "$UFS_PATH" ]]; then
    for f in spm_lvl spm_target_dev_state spm_target_link_state \
             rpm_lvl rpm_target_dev_state rpm_target_link_state auto_hibern8; do
      printf '%s = ' "$f"; sh_cat "$UFS_PATH/$f"
    done
  fi

  echo "## wakeup_sources 活跃项 (第6列!=0)"
  $ADB shell "awk '\$6 != 0 {print \$1, \$6}' /sys/kernel/debug/wakeup_sources" 2>/dev/null | tr -d '\r' | sort -k2 -nr || echo "N/A"

  echo "## debug / QDSS / Coresight"
  printf 'debug_enabled = '; sh_cat /sys/kernel/debug/debug_enabled
  printf 'persist.debug.coresight.config = '
  $ADB shell getprop persist.debug.coresight.config 2>/dev/null | tr -d '\r' || echo "N/A"
  printf 'sys.usb.config = '
  $ADB shell getprop sys.usb.config 2>/dev/null | tr -d '\r' || echo "N/A"
  echo "### coresight 仍开启的 source/sink"
  $ADB shell 'for d in /sys/bus/coresight/devices/*; do
    e=""; s=""
    [ -f "$d/enable_source" ] && e=$(cat "$d/enable_source")
    [ -f "$d/enable_sink" ] && s=$(cat "$d/enable_sink")
    if [ "$e" = "1" ] || [ "$s" = "1" ]; then
      echo "$(basename $d) source=$e sink=$s"
    fi
  done' 2>/dev/null | tr -d '\r' || echo "N/A"
} >"$OUT/sleep-baseline.txt"

$ADB shell cat /sys/kernel/debug/gpio 2>/dev/null | tr -d '\r' >"$OUT/gpio.txt" || true

MEM_SLEEP="$(sh_cat /sys/power/mem_sleep)"
DBG_EN="$(sh_cat /sys/kernel/debug/debug_enabled)"
DBG_ENABLED_LIST="$($ADB shell 'for d in /sys/bus/coresight/devices/*; do
  e=""; s=""
  [ -f "$d/enable_source" ] && e=$(cat "$d/enable_source")
  [ -f "$d/enable_sink" ] && s=$(cat "$d/enable_sink")
  if [ "$e" = "1" ] || [ "$s" = "1" ]; then echo "$(basename $d) source=$e sink=$s"; fi
done' 2>/dev/null | tr -d '\r' || true)"
GPIO_OUTHI="$(grep -E '\bout[[:space:]]+hi\b' "$OUT/gpio.txt" 2>/dev/null | head -15 || true)"

# 睡眠分层自动初判（规则同 step-01 1.3；宽松提取失败 → unknown 交人工）
aosd_active="unknown"; cxsd_active="unknown"; ddr_active="unknown"
[[ -n "$aosd_out" ]] && { has_nonzero "$aosd_out" && aosd_active=yes || aosd_active=no; }
[[ -n "$cxsd_out" ]] && { has_nonzero "$cxsd_out" && cxsd_active=yes || cxsd_active=no; }
[[ -n "$ddr_out"  ]] && { has_nonzero "$ddr_out"  && ddr_active=yes  || ddr_active=no;  }
LABEL="unknown"
if [[ "$aosd_active" == "no" && "$cxsd_active" == "yes" ]]; then
  LABEL="CLASS_AOSS_STUCK(aosd=0 且 cxsd 有 Count；先查平台 retention 分支再定性)"
elif [[ "$cxsd_active" == "no" || "$ddr_active" == "no" ]]; then
  LABEL="CLASS_CX_DDR_BLOCKED"
fi
if ! printf '%s' "$MEM_SLEEP" | grep -q '\[deep\]'; then
  LABEL="${LABEL}+WARN_NOT_DEEP"
fi

{
  echo "# SUMMARY — 高通待机电流 睡眠基线"
  echo "- time: $(date -Is 2>/dev/null || date)"
  echo "- measured_ma: ${MEASURED_MA:-<测流后补填>}"
  echo "- target_ma: ${TARGET_MA:-<未填>}"
  echo "- 测量时序: 本采集完成于拔 USB 测流之前（adb 在线）"
  echo
  echo "## 睡眠分层自动初判（精确判定以 step-01 1.3 为准）"
  echo "- mem_sleep: $MEM_SLEEP"
  echo "- aosd 活跃: $aosd_active / cxsd 活跃: $cxsd_active / ddr 活跃: $ddr_active"
  echo "- 初判标签: $LABEL"
  echo
  echo "## debug 开关（期望全关）"
  echo "- debug_enabled: $DBG_EN"
  echo "- 仍开启的 coresight:"
  echo "${DBG_ENABLED_LIST:-  (无)}"
  echo
  echo "## GPIO out high 摘要（完整见 gpio.txt，交 step-03）"
  echo "${GPIO_OUTHI:-  (无)}"
  echo
  echo "## 下一步"
  echo "- 把本 SUMMARY 各值代入 workflows/step-05-triage.md 定位矩阵"
  echo "- 活跃 wakeup 项见 sleep-baseline.txt，量化票龄定位挡深睡者"
} >"$OUT/SUMMARY.md"

cat >"$OUT/README.txt" <<EOF
qualcomm-current-consumption 睡眠基线采集
- SUMMARY.md           : 先读（分层初判/debug 开关/GPIO 摘要）
- sleep-baseline.txt   : 全节点原始输出
- gpio.txt             : 完整 GPIO 表（step-03 板级排查用）

复测: 修复后同命令再跑一个 OUTDIR，对比 SUMMARY 分层标签变化
MEASURED_MA=5.8 TARGET_MA=6 bash $0 ./sleep-baseline-after-fix
EOF

echo "[OK] $OUT/SUMMARY.md + sleep-baseline.txt + gpio.txt"
[[ -n "$MEASURED_MA" && -n "$TARGET_MA" ]] && \
  echo "提示: 实测 ${MEASURED_MA} mA vs 目标 ${TARGET_MA} mA"
