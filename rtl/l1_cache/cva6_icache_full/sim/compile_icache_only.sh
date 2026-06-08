#!/usr/bin/env bash
set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ICACHE_OUT=$(cd "$SCRIPT_DIR/.." && pwd)
MAIN_LOG="$ICACHE_OUT/logs/icache_extract_error.log"
COMPILE_LOG="$ICACHE_OUT/logs/compile_icache_only.log"
FILELIST="$SCRIPT_DIR/cva6_icache_full.f"
RUN_FILELIST="$SCRIPT_DIR/.cva6_icache_run.f"
HARNESS="$ICACHE_OUT/rtl/cva6_icache_compile_harness.sv"

mkdir -p "$ICACHE_OUT/logs"

{
  echo "============================================================"
  echo "[STEP] RUN compile_icache_only.sh"
  echo "[TIME] $(date)"
  echo "[ICACHE_OUT] $ICACHE_OUT"
  echo "[FILELIST] $FILELIST"
  echo "============================================================"

  if [ ! -f "$FILELIST" ]; then
    echo "[FATAL] Missing filelist: $FILELIST"
    exit 1
  fi

  cp "$FILELIST" "$RUN_FILELIST"
  TOP=cva6_icache

  if [ -f "$HARNESS" ]; then
    echo "[INFO] Harness found: $HARNESS"
    echo "$HARNESS" >> "$RUN_FILELIST"
    TOP=cva6_icache_compile_harness
  else
    echo "[WARN] Harness not found yet."
    echo "[WARN] Direct top cva6_icache may fail because interface type parameters default to logic."
    echo "[WARN] PHASE E4 should create cva6_icache_compile_harness.sv before real smoke compile."
  fi

  TOOL="${ICACHE_TOOL:-auto}"
  STATUS=0

  if [ "$TOOL" = "xrun" ] || { [ "$TOOL" = "auto" ] && command -v xrun >/dev/null 2>&1; }; then
    if ! command -v xrun >/dev/null 2>&1; then
      echo "[FATAL] ICACHE_TOOL=xrun requested but xrun not found"
      exit 127
    fi
    echo "[TOOL] xrun"
    xrun -64bit -sv -elaborate -f "$RUN_FILELIST" -top "$TOP" -l "$ICACHE_OUT/logs/xrun_icache_only.log"
    STATUS=$?
  elif [ "$TOOL" = "verilator" ] || { [ "$TOOL" = "auto" ] && command -v verilator >/dev/null 2>&1; }; then
    if ! command -v verilator >/dev/null 2>&1; then
      echo "[FATAL] ICACHE_TOOL=verilator requested but verilator not found"
      exit 127
    fi
    echo "[TOOL] verilator"
    verilator --lint-only --timing -Wno-fatal -f "$RUN_FILELIST" --top-module "$TOP"
    STATUS=$?
  else
    echo "[INFO] tool not found: no xrun, no verilator"
    echo "[INFO] Filelist exists; compile smoke deferred until a supported tool is available."
    STATUS=0
  fi

  echo "============================================================"
  echo "[STEP DONE] RUN compile_icache_only.sh STATUS=$STATUS"
  echo "[TIME] $(date)"
  echo "============================================================"
  exit "$STATUS"
} 2>&1 | tee -a "$COMPILE_LOG" | tee -a "$MAIN_LOG"

exit ${PIPESTATUS[0]}
