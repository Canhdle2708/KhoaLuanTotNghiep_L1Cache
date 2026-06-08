# P6 Full L1 Reproduce Smoke Result

Date: 2026-05-28

Status: PASS

## User Run Attempt 1

Ubuntu root detected by user command:

```text
/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master
```

Commands attempted:

```sh
make HPDCACHE_SRC_MODE=base run_full_l1_basic
make HPDCACHE_SRC_MODE=base run_full_l1_random SEEDS="1 2 3"
```

## Observed Result Attempt 1

Both smoke targets failed at Verilator compile before simulation.

Primary failure:

```text
%Error: Cannot find file containing module:
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/config_pkg.sv
```

Root cause:

- `rtl/l1_cache/work/sim/cva6_icache_full_for_cv32.f` used hardcoded lowercase mount path `/media/sf_source_env/...`.
- The actual user mount path is uppercase/mixed `/media/sf_SOURCE_ENV/...`.
- This is a filelist path issue, not evidence of RTL failure.

Secondary command issue:

```text
tee: ../../../logs/P6_run_full_l1_basic_user.log: No such file or directory
```

Root cause:

- From `rtl/l1_cache/work/sim`, the correct logs path is `../../logs`, not `../../../logs`.

## Fix Applied

Changed:

```text
rtl/l1_cache/work/sim/cva6_icache_full_for_cv32.f
```

from absolute `/media/sf_source_env/...` paths to relative paths:

```text
../../cva6_icache_full/rtl/...
```

No RTL logic was changed.
No HPDCache base/reference file was changed.
No DCACHE_ONLY or NO_CACHE folder was changed.

## Rerun Required

Smoke was rerun after the filelist fix and passed.

## User Rerun Attempt 2

Ubuntu root:

```text
/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master
```

Commands rerun by user:

```sh
cd /media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim
mkdir -p ../../logs
make HPDCACHE_SRC_MODE=base run_full_l1_basic 2>&1 | tee ../../logs/P6_run_full_l1_basic_user.log
make HPDCACHE_SRC_MODE=base run_full_l1_random SEEDS="1 2 3" 2>&1 | tee ../../logs/P6_run_full_l1_random_user.log
```

## PASS Evidence

| Target | Status | Evidence |
|---|---:|---|
| `run_full_l1_basic` | PASS | `[MAKE TARGET DONE] run_full_l1_basic exit=0` |
| `run_full_l1_random` seed 1 | PASS | `[PHASE10][PASS] seed=1 cycles=550 instr=60 ic_miss=15 ic_refill=15 loads=12 stores=17 mem_reads=28 mem_writes=6 dcache_miss=26` |
| `run_full_l1_random` seed 2 | PASS | `[PHASE10][PASS] seed=2 cycles=530 instr=60 ic_miss=15 ic_refill=15 loads=12 stores=17 mem_reads=27 mem_writes=4 dcache_miss=24` |
| `run_full_l1_random` seed 3 | PASS | `[PHASE10][PASS] seed=3 cycles=533 instr=60 ic_miss=15 ic_refill=15 loads=12 stores=17 mem_reads=27 mem_writes=4 dcache_miss=24` |
| `run_full_l1_random` aggregate | PASS | `[MAKE TARGET DONE] run_full_l1_random exit=0` |

Basic smoke PASS marker:

```text
[PHASE6][PASS] full L1 basic done cycles=356 instr=18 ic_miss=5 ic_refill=5 loads=3 stores=5 mem_reads=10 mem_writes=2 dcache_miss=9
[PHASE7] PASS marker found
```

Random smoke PASS markers:

```text
[PHASE10] PASS marker found for seed 1
[PHASE10] PASS marker found for seed 2
[PHASE10] PASS marker found for seed 3
[PHASE10] random smoke done
```

## Warnings / Cleanup

The following warnings were observed in the user rerun:

- Verilator `UNSIGNED` warning in `cva6_icache_full/rtl/vendor/tech_cells_generic/tc_sram.sv`. This is a lint-only warning caused by the `Latency=1` configuration making `(Latency-1)` a constant zero in an unsigned loop comparison. It was cleaned up in the Full L1 smoke scripts with `-Wno-UNSIGNED`; the CVA6 vendor RTL was not modified.
- `Clock skew detected` from make, likely due to shared-folder timestamp behavior.

No fatal simulation failure was observed after the path fix.

## Warning Cleanup Verification

User reran both smoke targets after adding `-Wno-UNSIGNED` to the Full L1 smoke Verilator commands:

| Target | Status | Warning status |
|---|---:|---|
| `run_full_l1_basic` | PASS | No Verilator `UNSIGNED` warning observed; only make clock-skew warning remains |
| `run_full_l1_random` seeds 1,2,3 | PASS | No Verilator `UNSIGNED` warning observed; only make clock-skew warning remains |

## Gate Status

Phase 1 reproduce smoke gate is PASS.

Next phase must not start until the user explicitly confirms Phase 2.
