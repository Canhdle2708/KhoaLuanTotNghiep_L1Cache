# UVM Legacy Functional Coverage Audit

Date: 2026-06-03

Scope:
- `rtl/l1_cache/work`
- `rtl/l1_cache/work/sim`
- `rtl/l1_cache/work/tb`
- `rtl/l1_cache/docs`
- `rtl/l1_cache/logs`

This audit is read-only. No legacy testbench, coverage, script, or filelist file was deleted, moved, or overwritten.

## Active Flow References

The existing Makefile still references these proven targets:

| Target | Classification | Reason |
|---|---|---|
| `run_full_l1_basic` | DO_NOT_TOUCH | Proven Full L1 basic smoke flow; Questa/ModelSim path already PASS with `HPDCACHE_SRC_MODE=base`. |
| `run_full_l1_random` | DO_NOT_TOUCH | Proven Full L1 random smoke flow used as regression evidence. |
| `verilator_l1_icache_func_cov_suite` | DO_NOT_TOUCH | Existing Group B I-Cache coverage suite, 7/7 PASS evidence. |
| `verilator_full_l1_dcache_func_cov_suite` | DO_NOT_TOUCH | Existing A/C/D/E/F/H functional coverage suite, 46/46 PASS evidence. |
| `verilator_full_l1_func_cov_suite` | DO_NOT_TOUCH | Existing full 59-check aggregation, 59/59 PASS evidence. |
| `verilator_full_l1_perf` | DO_NOT_TOUCH | Existing Full L1 performance benchmark flow. |
| `verilator_perf_compare_3mode` | DO_NOT_TOUCH | Existing No-Cache / D-Cache-only / Full-L1 performance comparison flow. |

## Legacy Testbench And Coverage Files

| Path | Classification | Notes |
|---|---|---|
| `rtl/l1_cache/work/tb/tb_cv32e40p_full_l1_basic.sv` | DO_NOT_TOUCH | Source of the proven basic program initialization and PASS criteria. Reused as reference for UVM Phase 1. |
| `rtl/l1_cache/work/tb/tb_cv32e40p_full_l1_random.sv` | DO_NOT_TOUCH | Used by `run_full_l1_random`. |
| `rtl/l1_cache/work/tb/tb_cv32e40p_full_l1_dcache_func_cov.sv` | DO_NOT_TOUCH | Used by dcache functional coverage suite. |
| `rtl/l1_cache/work/tb/tb_cv32e40p_l1_icache_func_cov.sv` | DO_NOT_TOUCH | Used by I-Cache functional coverage suite. |
| `rtl/l1_cache/work/tb/l1_icache_cov_pkg.sv` | DO_NOT_TOUCH | Used by I-Cache functional coverage filelist. |
| `rtl/l1_cache/work/tb/l1_icache_event_monitor.sv` | DO_NOT_TOUCH | Used by I-Cache functional coverage filelist. |
| `rtl/l1_cache/work/tb/l1_icache_check_scoreboard.sv` | DO_NOT_TOUCH | Used by I-Cache functional coverage filelist. |
| `rtl/l1_cache/work/tb/tb_cv32e40p_full_l1_perf.sv` | DO_NOT_TOUCH | Used by performance flow. |
| `rtl/l1_cache/work/tb/full_l1_perf_benchmark_programs.svh` | DO_NOT_TOUCH | Benchmark program source for performance comparisons. |
| `rtl/l1_cache/work/tb/tb_cv32e40p_full_l1_basic_debug.sv` | KEEP_REFERENCE | Debug variant of basic Full L1 TB. Not used by new UVM flow. |
| `rtl/l1_cache/work/tb/tb_cv32e40p_dcache_basic.sv` | KEEP_REFERENCE | Earlier D-Cache-only bring-up reference. |
| `rtl/l1_cache/work/tb/tb_cv32e40p_dcache_random.sv` | KEEP_REFERENCE | Earlier D-Cache random reference. |
| `rtl/l1_cache/work/tb/tb_cv32e40p_baseline_original.sv` | KEEP_REFERENCE | Baseline no-cache reference. |
| `rtl/l1_cache/work/tb/tb_cv32_dcache_adapter_basic.sv` | KEEP_REFERENCE | Adapter-level reference. |
| `rtl/l1_cache/work/tb/tb_hpdcache_cv32_wrapper_reset.sv` | KEEP_REFERENCE | HPDCache wrapper reset/debug evidence. |

## Legacy Scripts And Filelists

| Path | Classification | Notes |
|---|---|---|
| `rtl/l1_cache/work/sim/Makefile` | DO_NOT_TOUCH | New UVM target is added without changing existing targets. |
| `rtl/l1_cache/work/sim/run_full_l1_basic.sh` | DO_NOT_TOUCH | Proven Questa/Verilator full L1 basic runner. |
| `rtl/l1_cache/work/sim/run_full_l1_random.sh` | DO_NOT_TOUCH | Full L1 random runner. |
| `rtl/l1_cache/work/sim/run_l1_icache_cov_suite.sh` | DO_NOT_TOUCH | Existing Group B coverage runner. |
| `rtl/l1_cache/work/sim/run_full_l1_dcache_cov_suite.sh` | DO_NOT_TOUCH | Existing A/C/D/E/F/H coverage runner. |
| `rtl/l1_cache/work/sim/run_full_l1_func_cov_suite.sh` | DO_NOT_TOUCH | Existing full coverage aggregation runner. |
| `rtl/l1_cache/work/sim/run_full_l1_perf_verilator.sh` | DO_NOT_TOUCH | Existing performance runner. |
| `rtl/l1_cache/work/sim/run_compare_3mode_perf.sh` | DO_NOT_TOUCH | Existing 3-mode performance comparison runner. |
| `rtl/l1_cache/work/sim/cv32e40p_full_l1_basic.f` | DO_NOT_TOUCH | Proven Full L1 basic RTL/TB filelist. |
| `rtl/l1_cache/work/sim/cva6_icache_full_for_cv32.f` | DO_NOT_TOUCH | Proven CVA6 I-Cache filelist for CV32. |
| `rtl/l1_cache/work/sim/hpdcache_base_cv32.f` | DO_NOT_TOUCH | Generated HPDCache base filelist. New UVM runner regenerates and checks it. |
| `rtl/l1_cache/work/sim/cv32e40p_l1_icache_func_cov_verilator.f` | DO_NOT_TOUCH | Existing I-Cache coverage filelist. |
| `rtl/l1_cache/work/sim/cv32e40p_full_l1_dcache_func_cov_verilator.f` | DO_NOT_TOUCH | Existing D-Cache/full-L1 coverage filelist. |
| `rtl/l1_cache/work/sim/cv32e40p_full_l1_perf_verilator.f` | DO_NOT_TOUCH | Existing performance filelist. |
| `rtl/l1_cache/work/sim/hpdcache_patched_cv32*.f` | CANDIDATE_ARCHIVE | Patched HPDCache artifacts from earlier debug work. Not used by the new UVM flow and must not be selected. |
| `rtl/l1_cache/work/hpdcache_patched/` | CANDIDATE_ARCHIVE | Earlier patched RTL sandbox. New UVM runner fails if this mode is selected. |

## Logs And Docs

| Path | Classification | Notes |
|---|---|---|
| `rtl/l1_cache/logs/10_full_l1_basic.log` | KEEP_ACTIVE | Existing Full L1 basic evidence. |
| `rtl/l1_cache/logs/full_l1_func_cov*.log/csv/txt` | KEEP_ACTIVE | Existing 59/59 functional coverage evidence. |
| `rtl/l1_cache/logs/full_l1_dcache_func_cov*.log/csv/txt` | KEEP_ACTIVE | Existing A/C/D/E/F/H coverage evidence. |
| `rtl/l1_cache/logs/l1_icache_func_cov*.log/csv/txt` | KEEP_ACTIVE | Existing Group B coverage evidence. |
| `rtl/l1_cache/logs/perf_compare_3mode.*` | KEEP_ACTIVE | Existing performance comparison evidence. |
| `rtl/l1_cache/docs/P6_*`, `P7_*`, `P8_*`, `P9_*`, `P10_*` | KEEP_REFERENCE | Prior phase documentation and evidence. |

## New UVM Isolation Rule

New UVM work is isolated under:

`rtl/l1_cache/work/uvm`

The UVM filelist is explicit:

`rtl/l1_cache/work/sim/cv32_l1_uvm_questa.f`

No wildcard file inclusion is used for the UVM files, so legacy testbenches are not accidentally pulled into the new UVM package.

