# UVM Phase 3 Baseline Fail Report

Date: 2026-06-04

## Observed Failure

The user ran the requested baseline and Phase 3 suite commands. Both failed before simulation, during `vlog`.

Logs inspected:

- `rtl/l1_cache/logs/QUESTA_phase1_2_baseline_before_phase3.log`
- `rtl/l1_cache/logs/QUESTA_phase3_directed_suite.log`
- `rtl/l1_cache/logs/QUESTA_phase1_2_baseline_after_phase3.log`

Observed result:

- `run_uvm_full_l1_basic exit=1`
- `run_uvm_p3_reset_basic exit=1`
- Failure point: `vlog`

Key error:

```text
** Warning: (vlog-174) An embedded newline exists within a string in the argument file ... hpdcache_base_cv32.f
** Error: (vlog-173) An unterminated string exists in the argument file ... hpdcache_base_cv32.f
```

## Root Cause

The Phase 3 hard-path cleanup changed `hpdcache_src_mode.sh` to emit relative filelist paths, but it treated HPDCache source filelist comment lines beginning with `//` as absolute paths. That generated invalid entries in:

```text
rtl/l1_cache/work/sim/hpdcache_base_cv32.f
```

Example bad generated lines:

```text
../../../../../../../../
../../../../../../../../  Copyright 2023 ...
```

Questa then parsed those malformed lines as an unterminated argument string.

## Fix Applied

- `rtl/l1_cache/work/sim/hpdcache_src_mode.sh` now skips blank lines and lines matching `^[[:space:]]*//`.
- `rtl/l1_cache/work/sim/hpdcache_base_cv32.f` was regenerated with clean relative paths.

Current expected first lines:

```text
+incdir+../../hpdcache/cv-hpdcache/rtl/include
../../hpdcache/cv-hpdcache/rtl/src/hpdcache_pkg.sv
```

## Required Rerun

Rerun baseline and Phase 3 after this fix:

```sh
FULL_L1_ROOT=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master
cd "$FULL_L1_ROOT/rtl/l1_cache/work/sim" || exit 1
mkdir -p ../../logs

bash -n hpdcache_src_mode.sh
bash -n run_uvm_questa.sh

make HPDCACHE_SRC_MODE=base run_uvm_full_l1_basic \
  2>&1 | tee ../../logs/QUESTA_phase1_2_baseline_before_phase3_rerun.log

make HPDCACHE_SRC_MODE=base run_uvm_p3_directed_suite MAX_CYCLES=100000 \
  2>&1 | tee ../../logs/QUESTA_phase3_directed_suite_rerun.log

make HPDCACHE_SRC_MODE=base run_uvm_full_l1_basic \
  2>&1 | tee ../../logs/QUESTA_phase1_2_baseline_after_phase3_rerun.log
```

## Status

- Failure diagnosed: yes.
- Fix applied: yes.
- Questa rerun required: completed.
- Rerun result: PASS.
- Passing logs:
  - `rtl/l1_cache/logs/QUESTA_phase1_2_baseline_before_phase3_rerun.log`
  - `rtl/l1_cache/logs/QUESTA_phase3_directed_suite_rerun.log`
  - `rtl/l1_cache/logs/QUESTA_phase1_2_baseline_after_phase3_rerun.log`
- No RTL files modified.
