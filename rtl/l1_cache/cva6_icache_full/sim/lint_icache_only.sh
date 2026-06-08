#!/usr/bin/env bash
set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ICACHE_OUT=$(cd "$SCRIPT_DIR/.." && pwd)
MAIN_LOG="$ICACHE_OUT/logs/icache_extract_error.log"
LINT_LOG="$ICACHE_OUT/logs/compile_icache_only.log"
VL_FILELIST="$SCRIPT_DIR/cva6_icache_full_verilator_lint.f"

mkdir -p "$ICACHE_OUT/logs"

{
  echo "============================================================"
  echo "[STEP] RUN lint_icache_only.sh - Verilator lint"
  echo "[TIME] $(date)"
  echo "[ICACHE_OUT] $ICACHE_OUT"
  echo "[VL_FILELIST] $VL_FILELIST"
  echo "============================================================"

  if ! command -v verilator >/dev/null 2>&1; then
    echo "[INFO] tool not found: verilator"
    exit 0
  fi

  if [ ! -f "$VL_FILELIST" ]; then
    echo "[FATAL] Missing Verilator lint filelist: $VL_FILELIST"
    exit 1
  fi

  verilator --lint-only --timing -Wno-fatal \
    -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-UNSIGNED \
    -f "$VL_FILELIST" --top-module cva6_icache_compile_harness

  STATUS=$?
  echo "============================================================"
  echo "[STEP DONE] RUN lint_icache_only.sh STATUS=$STATUS"
  echo "[TIME] $(date)"
  echo "============================================================"
  exit "$STATUS"
} 2>&1 | tee -a "$LINT_LOG" | tee -a "$MAIN_LOG"

exit ${PIPESTATUS[0]}
