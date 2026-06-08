# P10 Full L1 Testplan and Benchmark Reuse Plan

## Scope

This plan uses the user-provided `TESTPLAN_WRITEBACK_VBUF.md` as the authoritative source for Full L1 functional coverage.

Full L1 coverage scope:

| Group | Scope | Check count |
|---|---:|---:|
| A | Basic / Reset | 5 |
| B | I-Cache | 7 |
| C | D-Cache basic load/store | 7 |
| D | Replacement / PLRU | 6 |
| E | D-Cache write-back | 6 |
| F | VBUF | 12 |
| G | CV32E40P / RISC-V Cache Integration | 6 |
| H | Corner case / ordering | 10 |

Total Full L1 denominator: 59 CheckIDs. No Group B/G exclusion is used in the Full L1 folder.

## Reuse Decision

Reusable from the D-Cache-only folder:

| Asset | Reuse level | Reason |
|---|---|---|
| `perf_benchmark_programs.svh` | Copy-adapted | The common benchmark ideas and checksums are valid for Full L1 performance. |
| `tb_cv32e40p_perf_no_cache.sv` | Reference only | Useful marker/counter/CSV style, but the DUT and memory topology differ. |
| `tb_cv32e40p_perf_dcache.sv` | Reference only | Useful counter style, but Full L1 must use I-Cache plus shared arbiter. |
| `run_perf_verilator.sh` | Reference only | Same Verilator discipline and CSV style reused. |
| `run_perf_verilator_sweep.sh` | Reference only | Same batch/run-log style reused. |
| `dcache_cov_pkg.sv`, `dcache_event_monitor.sv`, `dcache_check_scoreboard.sv` | Future copy-adapt | CheckID logic is useful, but hierarchical paths must be changed for Full L1. |

Not copied as PASS evidence:

- D-Cache-only coverage PASS results are not reused as Full L1 PASS results.
- Full L1 CheckIDs must run in the Full L1 topology: CV32E40P I-side through CVA6 I-Cache, D-side through HPDCache, and both through the shared L1 arbiter.

## Performance Benchmarks

Common 3-mode benchmarks now supported by Full L1 and already supported by the D-Cache-only performance flow:

| BENCH_NAME | Purpose |
|---|---|
| `basic_load_store` | Smoke: small load/store correctness and marker flow. |
| `repeated_load` | D-cache locality/reuse: first miss then repeated hits. |
| `load_reuse_loop` | Tight loop repeatedly loads one hot line; low instruction footprint, high dynamic load count. |
| `store_load_reuse_loop` | Tight loop repeatedly stores and loads one hot line; stresses store/load reuse and write-back behavior. |
| `array_sum` | Sequential data locality and cache-line reuse. |
| `store_then_load_many` | Store/load reuse and write-back traffic behavior. |
| `stride_access_s1` | Locality sensitivity with `STRIDE_WORDS=1`. |
| `stride_access_s2` | Locality sensitivity with `STRIDE_WORDS=2`. |
| `stride_access_s4` | Locality sensitivity with `STRIDE_WORDS=4`. |
| `stride_access_s8` | Locality sensitivity with `STRIDE_WORDS=8`. |
| `stride_access_s16` | Locality sensitivity with `STRIDE_WORDS=16`. |

Full-L1-focused benchmarks added for I-side and mixed behavior:

| BENCH_NAME | Purpose | 3-mode comparable now |
|---|---|---|
| `tight_loop_fetch` | Repeated instruction fetch from a tight loop to expose I-Cache benefit. | No, Full L1 only until D-Cache-only/No-Cache benchmark generators are extended. |
| `mixed_i_d_locality` | Tight instruction loop plus repeated data loads. | No, Full L1 only until other folders are extended. |

To add more truly common 3-mode benchmarks, the D-Cache-only folder's performance generator must also be extended. That is intentionally not done here because the current rule is to avoid modifying D-Cache-only unless explicitly allowed.

## Functional Coverage Closure Plan

Current Phase 3 result before this performance work:

```text
[COV_SUMMARY] total=59 pass=10 fail=0 not_run=35 instrumentation_missing=14 excluded=0
```

Recommended reuse path for Full L1 coverage:

| Group | Reuse source | Needed Full L1 work |
|---|---|---|
| A | Full L1 smoke and I-Cache coverage reset logic | Add reset-idle monitor for I/D response, VBUF empty, MSHR/RTAB idle. |
| B | Existing `verilator_l1_icache_func_cov_suite` | Already closes 7/7 with Full L1 I-Cache evidence. |
| C | D-Cache-only directed benchmarks/checkers | Copy-adapt load/store scenarios to the Full L1 top and shared memory. |
| D | D-Cache-only PLRU/VBUF monitor ideas | Add hierarchical PLRU/victim monitor in Full L1; then add set-conflict benchmarks. |
| E | D-Cache-only write-back directed checks | Add store-hit-dirty and dirty-eviction benchmarks under Full L1. |
| F | D-Cache-only VBUF directed checks | Add VBUF alloc/capture/drain/full/forward benchmarks under Full L1. |
| G | Full L1 smoke plus 3-mode performance compare | Add shared arbiter I/D concurrency and request/response scoreboard. |
| H | D-Cache-only corner sequences plus Full L1 I/D concurrency | Add ordering/no-deadlock benchmarks with both I-side and D-side pressure. |

## Files Added or Updated

Performance implementation in the Full L1 folder:

| File | Purpose |
|---|---|
| `rtl/l1_cache/work/rtl/cv32e40p_full_l1_cache_top.sv` | Adds non-functional parameters for shared L1 memory latency control. |
| `rtl/l1_cache/work/tb/full_l1_perf_benchmark_programs.svh` | Full L1 benchmark generator. |
| `rtl/l1_cache/work/tb/tb_cv32e40p_full_l1_perf.sv` | Full L1 performance TB and counters. |
| `rtl/l1_cache/work/sim/cv32e40p_full_l1_perf_verilator.f` | Full L1 performance filelist. |
| `rtl/l1_cache/work/sim/run_full_l1_perf_verilator.sh` | Single Full L1 performance run. |
| `rtl/l1_cache/work/sim/run_compare_3mode_perf.sh` | NO_CACHE vs DCACHE_ONLY vs FULL_L1 compare driver. |
| `rtl/l1_cache/work/sim/Makefile` | Adds `verilator_full_l1_perf` and `verilator_perf_compare_3mode`. |

D-Cache-only folder performance-only updates needed for common 3-mode benchmark names:

| File | Purpose |
|---|---|
| `C:/CanhDac/SOURCE_ENV/cv32e40p-master/rtl/l1_cache/work/tb/perf_benchmark_programs.svh` | Adds `load_reuse_loop` and `store_load_reuse_loop` so NO_CACHE and DCACHE_ONLY can run the same benchmarks as FULL_L1. |
| `C:/CanhDac/SOURCE_ENV/cv32e40p-master/rtl/l1_cache/work/tb/tb_cv32e40p_perf_no_cache.sv` | Adds BNE instruction encoder for loop benchmarks only. |
| `C:/CanhDac/SOURCE_ENV/cv32e40p-master/rtl/l1_cache/work/tb/tb_cv32e40p_perf_dcache.sv` | Adds BNE instruction encoder for loop benchmarks only. |

## Rules Preserved

- HPDCache base/reference RTL is not modified.
- `hpdcache_patched` is not used.
- The separate No-Cache folder is not modified.
- The D-Cache-only folder is only updated in the performance benchmark/testbench helper files listed above, so the same BENCH_NAME values can run in NO_CACHE and DCACHE_ONLY modes.
- PASS is based on DONE marker, checksum match, timeout guard, and observed counters.
- Missing future coverage evidence remains `NOT_RUN` or `INSTRUMENTATION_MISSING`, not PASS.
