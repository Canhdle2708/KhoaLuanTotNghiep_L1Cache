# UVM Phase 7 Final Regression Report

## Executive summary

Phase 7 is a final evidence regression and report packaging pass. It does not add new deep checkers and does not rerun the full Questa simulation suite. The current evidence check status is **PASS**.

Accepted final Phase 6 evidence is the post-mode-compare closure, not the older historical Phase 6 bundle snapshot. The current closure reports P1-P29 PASS, fail=0, deferred=0, blocked=0.

## Environment

| item | value |
| --- | --- |
| Questa root | `/home/admin/altera/25.1std/questa_fse` |
| License path | `/media/sf_SOURCE_ENV/LR-166407_License.dat` |
| HPDCACHE_SRC_MODE | `base` |
| Ubuntu repo path | `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master` |
| Alternate Ubuntu repo path | `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master` |
| Windows repo path | `C:\CanhDac\SOURCE_ENV\cv32_full_l1_cache\cv32e40p-master` |

## Phase summary

| phase | summary | status |
| --- | --- | --- |
| Phase 0 | Bring-up and repository integration evidence is preserved from earlier phases. | PASS by existing evidence chain |
| Phase 1 | UVM smoke/basic execution path is covered by accepted Questa logs. | PASS by existing evidence chain |
| Phase 2 | Monitor and scoreboard sanity are covered by accepted transaction/count logs. | PASS by existing evidence chain |
| Phase 3 | Directed cache/order/writeback tests are covered by accepted Phase 3/4/6 evidence. | PASS by existing evidence chain |
| Phase 4 | Functional coverage closure: 57/57 mapped testplan rows PASS. | PASS |
| Phase 5 | Performance collector summary has pass=PASS, timeout=0, scoreboard_errors=0. | PASS |
| Phase 6 | Performance test closure P1-P29 PASS, fail=0, deferred=0, blocked=0. | PASS |

## Key evidence table

| item | log/CSV | status | PASS marker / condition | UVM_ERROR | UVM_FATAL |
| --- | --- | --- | --- | ---: | ---: |
| Phase 4 coverage | `../../logs/uvm_phase4_coverage_summary.txt`, `../../logs/uvm_phase4_testplan_coverage_matrix.csv` | PASS | total_testcase_rows=57 mapped_testcase_rows=57 pass_count=57 partial/deferred/not_covered/missing=0 matrix_complete=1 functional_coverage_closed=1 | N/A | N/A |
| Phase 5 performance collector | `../../logs/uvm_p5_perf_collector_full_summary.csv` | PASS | pass=PASS timeout=0 scoreboard_errors=0 | 0 | 0 |
| Phase 6 closure | `../../logs/QUESTA_p6_perf_closure_full_after_mode_compare.log` | PASS | [UVM][P6_CLOSURE][PASS] | N/A | N/A |
| P15 random wait | `../../logs/uvm_p6_p15_random_wait_distribution.csv` | PASS | random wait READ distinct latency >= 2 | N/A | N/A |
| P26 multi-seed | `../../logs/uvm_p6_p26_multiseed_summary.csv` | PASS | selected seeds all PASS | N/A | N/A |
| P27-P29 mode compare | `../../logs/QUESTA_p6_perf_mode_compare_full.log`, `../../logs/uvm_p6_mode_compare_summary.csv` | PASS | [UVM][P6_MODE_COMPARE][PASS] | N/A | N/A |

## Phase 6 highlight

- P15 random wait PASS: random_wait true distribution read_distinct=21 write_distinct=9.
- P26 multi-seed PASS: multi-seed PASS 5/5 selected seeds.
- P27-P29 true 3-mode comparison PASS: NO_CACHE, DCACHE_ONLY, and FULL_L1 wrappers are represented in `uvm_p6_mode_compare_summary.csv` with `reliable_for_report=1`.

## Mode comparison summary

| mode | cycles | traffic/instr | speedup vs no-cache | hit/miss notes |
| --- | ---: | ---: | ---: | --- |
| NO_CACHE | 277389 | 1.426670 | 1.000000 | ic_miss=0; dc_miss=0; true_no_cache_direct_i_and_d_memory;cache_hit_miss_N/A;refill_count_zero_no_cache |
| DCACHE_ONLY | 56726 | 1.009275 | 4.889980 | ic_miss=0; dc_miss=70; true_dcache_only_direct_ifetch_hpdcache_data;icache_hit_miss_N/A;refill_count_uses_dcache_miss_count |
| FULL_L1 | 28519 | 0.019352 | 9.726463 | ic_miss=75; dc_miss=70; true_full_l1_cva6_icache_plus_hpdcache;refill_count_icache_refill_plus_dcache_miss |

## Known notes and limitations

- P17-P22 are passive-monitor temporal performance evidence, not formal deep microarchitecture proof.
- Phase 8 can optionally add deep evidence add-ons for arbiter, MSHR, RTAB, and VBUF.
- Phase 7 intentionally performs evidence regression and packaging only; it does not add new feature-level behavior.
- Phase 5 uses `uvm_p5_perf_collector_full_summary.csv` as the required current evidence file. The legacy `uvm_p5_perf_collector_summary.csv` name is an optional alias and must not fail Phase 7 when the full summary passes.
- The historical `UVM_PHASE6_FINAL_REVIEW_BUNDLE.txt` is included for reviewer context, but the current accepted final Phase 6 status comes from `QUESTA_p6_perf_closure_full_after_mode_compare.log` and the current CSVs.

## Final conclusion


**PHASE7_PASS**: final evidence regression is clean, no required evidence is missing, and the Full L1 UVM evidence is ready for thesis/report use.
