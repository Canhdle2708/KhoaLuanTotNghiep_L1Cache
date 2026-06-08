# UVM Phase 6E Mode Compare Plan / Result

## Goal

Close P27-P29 with three true Questa/UVM DUT modes:

- `NO_CACHE`: CV32E40P instruction port direct to shared memory, data port direct to shared memory. No CVA6 I-Cache and no HPDCache instance.
- `DCACHE_ONLY`: CV32E40P instruction port direct to shared memory, data port through HPDCache base D-Cache. No CVA6 I-Cache instance.
- `FULL_L1`: existing Full L1 wrapper, CVA6 I-Cache plus HPDCache D-Cache.

The comparison uses the same `uvm_p6_perf` benchmark, same seed, same memory latency mode, same random-wait settings, and same `MAX_CYCLES`.

## Implemented Work-Area Files

- `rtl/l1_cache/work/rtl/cv32e40p_l1_no_cache_top.sv`
- `rtl/l1_cache/work/rtl/cv32e40p_l1_dcache_only_top.sv`
- `rtl/l1_cache/work/uvm/tb/tb_cv32_l1_uvm_top.sv`
- `rtl/l1_cache/work/sim/run_uvm_questa.sh`
- `rtl/l1_cache/work/sim/run_p6_mode_compare.sh`
- `rtl/l1_cache/work/sim/run_p6_closure.sh`
- `rtl/l1_cache/work/sim/Makefile`
- `rtl/l1_cache/work/sim/collect_p6_final_review_bundle.sh`

## Wrapper Mapping

| Mode | Wrapper | True Mode Evidence |
| --- | --- | --- |
| `NO_CACHE` | `cv32e40p_l1_no_cache_top` | Instantiates CV32E40P and direct memory model only; no CVA6 I-Cache, no HPDCache. |
| `DCACHE_ONLY` | `cv32e40p_l1_dcache_only_top` | Instantiates CV32E40P, `cv32_data_to_hpdcache_adapter`, `hpdcache_cv32_wrapper`, and shared memory arbiter; instruction path is direct. |
| `FULL_L1` | `cv32e40p_full_l1_cache_top` | Existing Full L1 wrapper: CVA6 I-Cache plus HPDCache D-Cache. |

## Metric Rules

- `measured_cycles`, instruction/load/store counts, memory read/write counts come from the UVM P5 performance collector summary for each true DUT mode.
- `speedup_vs_no_cache = cycles_no_cache / cycles_mode`.
- `traffic_reduction_vs_no_cache = (traffic_no_cache - traffic_mode) / traffic_no_cache`.
- `NO_CACHE` cache hit/miss rates are `N/A`.
- `DCACHE_ONLY` I-Cache hit/miss rates are `N/A`.
- `DCACHE_ONLY` D-Cache hit/miss rate uses HPDCache miss events.
- `FULL_L1` I-Cache/D-Cache hit/miss rates use existing Full L1 counters/events.
- No cache-specific event is fabricated for `NO_CACHE`.

## PASS Criteria

P27 PASS requires:

- Rows for `NO_CACHE`, `DCACHE_ONLY`, and `FULL_L1`.
- Correctness PASS for all three modes.
- Same benchmark, seed, memory latency mode, random-wait settings, and max cycles.
- `measured_cycles > 0`.
- Minimum workload in each mode: `instr_count >= 128`, `load_count >= 64`, `store_count >= 64`.

P28 PASS requires P27 PASS plus valid memory traffic metrics for all three modes.

P29 PASS requires P27 PASS plus valid speedup metrics versus `NO_CACHE`.

## Output Files

- `rtl/l1_cache/logs/uvm_p6_mode_compare_summary.csv`
- `rtl/l1_cache/logs/uvm_p6_mode_compare_raw.csv`
- `rtl/l1_cache/logs/uvm_p6_perf_test_matrix.csv`
- `rtl/l1_cache/logs/uvm_p6_perf_summary.csv`
- `rtl/l1_cache/logs/uvm_p6_group_summary.csv`
- `rtl/l1_cache/logs/UVM_PHASE6_FINAL_REVIEW_BUNDLE.txt`

## Current Status

After implementation, the next required step is Ubuntu/Questa syntax check and three-mode run. P27-P29 must remain BLOCKED or FAIL until the generated logs show true wrapper compile/run and reliable CSV rows.
