# 07 - Ubuntu Master Log Usage

Date: 2026-05-26

## Purpose

Use one fixed master log so Codex can read Ubuntu errors after every run without
guessing which log changed.

Master log:

```text
rtl/l1_cache/logs/UBUNTU_LAST_RUN.log
```

## Command To Run In Ubuntu

```bash
find /media -maxdepth 8 -type d -name "cv32e40p-master" 2>/dev/null
find /mnt -maxdepth 8 -type d -name "cv32e40p-master" 2>/dev/null

export ROOT_WORKSPACE=<Ubuntu path returned above>
cd "$ROOT_WORKSPACE/rtl/l1_cache/work/sim"
make ubuntu_log
```

## What The Command Does

`make ubuntu_log` runs:

1. `make build`
2. `make run_smoke`
3. `make run`

Then it appends summaries from:

- `rtl/l1_cache/logs/00_build_cv32_dcache.log`
- `rtl/l1_cache/logs/02_adapter_basic.log`
- `rtl/l1_cache/logs/00_run_smoke_hpdcache_wrapper_reset.log`
- `rtl/l1_cache/logs/03_cv32_dcache_basic.log`
- `rtl/l1_cache/logs/03_cv32_dcache_basic_novcd.log`

## What To Send Back

After running, send or sync this file:

```text
rtl/l1_cache/logs/UBUNTU_LAST_RUN.log
```

Codex should read this file first before making any RTL edits.

If `make ubuntu_log` appears to do nothing, run the script directly:

```bash
cd "$ROOT_WORKSPACE/rtl/l1_cache/work/sim"
bash ./run_ubuntu_logged.sh
```

The script writes `UBUNTU_LAST_RUN.log` before it sources the environment
helper, so even path-detection failures should be captured.

## Phase Summary

Files read:

- `rtl/l1_cache/work/sim/Makefile`
- `rtl/l1_cache/work/sim/env_ubuntu.sh`
- existing logs under `rtl/l1_cache/logs`

Files created/modified:

- Created `rtl/l1_cache/work/sim/run_ubuntu_logged.sh`
- Created `rtl/l1_cache/logs/UBUNTU_LAST_RUN.log`
- Modified `rtl/l1_cache/work/sim/Makefile`
- Created `rtl/l1_cache/docs/07_ubuntu_master_log_usage.md`
- Updated `rtl/l1_cache/work/sim/run_ubuntu_logged.sh` so environment detection
  failures are also logged.

Commands run:

- Local file inspection only. No Ubuntu simulation was run from this Codex
  session.

Pass/fail:

- Master log flow creation: PASS.
- Ubuntu execution: pending user run.

Next step:

- Run `make ubuntu_log` in Ubuntu, then Codex reads
  `rtl/l1_cache/logs/UBUNTU_LAST_RUN.log`.
