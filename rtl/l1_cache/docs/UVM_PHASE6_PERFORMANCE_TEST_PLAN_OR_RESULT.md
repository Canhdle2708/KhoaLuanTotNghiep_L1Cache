# UVM Phase 6 Performance Test Plan / Result

Date: 2026-06-04

## Scope

Phase 6 implements the UVM performance-test framework for the Excel
Performance / Performance test plan P1-P29.

This phase keeps the existing constraints:

- Questa root: `/home/vboxuser/altera/25.1std`
- License: `/media/sf_source_env/LR-166346_License.dat`
- HPDCache source mode: `HPDCACHE_SRC_MODE=base`
- No patched HPDCache for UVM evidence
- No Xcelium
- No Verilator as primary UVM evidence
- No edits to original CV32E40P / CVA6 I-Cache / HPDCache RTL

## Implemented In This Drop

- Added `uvm_p6_perf_test`.
- Added `uvm_p6_perf` workload in the UVM top work-area testbench.
- Added P6 config plusargs and CSV paths.
- Extended the performance collector with event-correlated hit/miss latency,
  store-to-dirty-update latency, and VBUF writeback latency.
- Added Makefile targets for Phase 6 batches A1/A2/B/C/D/E/ALL.
- Added Phase 6 summary CSV, matrix CSV, and group summary CSV generation.
- Added review bundle collection script.
- Added UVM top memory-latency parameter overrides for P13/P14/P16:
  no-wait, fixed-wait, and long-wait are driven through Questa `-g`
  parameters without editing original RTL.
- Added best-effort back-to-back performance counters for P17-P22 from
  passive UVM monitors. These count temporal gaps/windows, not deep internal
  arbitration proof.
- Added a bounded countdown loop for P23-P25 long-run instruction-count
  stability checks.

## P1-P29 Mapping

| ID | Test name | Current status policy |
|---|---|---|
| P1 | perf_icache_fetch_hit_latency | PASS only with fetch responses and event-correlated hit latency |
| P2 | perf_icache_fetch_miss_refill_latency | PASS only with fetch responses and event-correlated miss latency |
| P3 | perf_dcache_load_hit_latency | PASS only with load responses and event-correlated hit latency |
| P4 | perf_dcache_load_miss_refill_latency | PASS only with load responses and event-correlated miss latency |
| P5 | perf_dcache_store_hit_latency | PASS only with store accepts and store-to-dirty-update hit latency |
| P6 | perf_dcache_store_miss_refill_latency | PASS only with store accepts and store-to-dirty-update miss latency |
| P7 | perf_dirty_eviction_vbuf_writeback_latency | PASS only with at least 4 VBUF writeback latency samples |
| P8 | perf_instruction_fetch_throughput | PASS only with at least 128 fetch responses |
| P9 | perf_data_load_throughput | PASS only with at least 64 load responses |
| P10 | perf_data_store_throughput | PASS only with at least 64 store accepts |
| P11 | perf_memory_refill_throughput | PASS only with at least 16 memory read/refill completions |
| P12 | perf_dirty_writeback_throughput | PASS only with at least 4 dirty writeback events |
| P13 | perf_mem_latency_no_wait | PASS only when UVM top is parameterized with read/write/stall latency 0 and memory read samples are measured |
| P14 | perf_mem_latency_fixed_wait | PASS only when fixed-wait latency parameters are selected and memory read samples are measured |
| P15 | perf_mem_latency_random_wait | Implemented in work-area memory model; PASS only after random-wait Questa evidence shows enough samples and at least two observed read latencies |
| P16 | perf_mem_latency_long_wait | PASS only when long-wait latency parameters are selected and memory read samples are measured |
| P17 | perf_b2b_icache_fetch_hit | PASS only when back-to-back I-fetch hit response gap counter reaches target |
| P18 | perf_b2b_dcache_load_hit | PASS only when back-to-back D-cache load hit response gap counter reaches target |
| P19 | perf_b2b_dcache_store_hit | PASS only when back-to-back store hit/accept gap counter reaches target |
| P20 | perf_b2b_load_after_store_same_line | PASS only when load-after-store same-line gap counter reaches target |
| P21 | perf_b2b_icache_dcache_miss_contention | PASS only when I-cache/D-cache miss contention window counter reaches target |
| P22 | perf_b2b_dcache_miss_vbuf_writeback | PASS only when D-cache miss during/recent VBUF writeback window counter reaches target |
| P23 | perf_long_run_1k | PASS only when long-run instruction count reaches 1k with clean scoreboard |
| P24 | perf_long_run_10k | PASS only when long-run instruction count reaches 10k with clean scoreboard |
| P25 | perf_long_run_100k | PASS only when long-run instruction count reaches 100k with clean scoreboard |
| P26 | perf_multi_seed_random_stress | Implemented as an aggregate multi-seed runner; PASS only when every selected seed run passes |
| P27-P29 | cache mode comparison | BLOCKED until UVM no-cache and D-cache-only wrappers are available |

## Output Files

- `rtl/l1_cache/logs/uvm_p6_perf_summary.csv`
- `rtl/l1_cache/logs/uvm_p6_perf_test_matrix.csv`
- `rtl/l1_cache/logs/uvm_p6_group_summary.csv`
- `rtl/l1_cache/logs/uvm_p6_p15_random_wait_distribution.csv`
- `rtl/l1_cache/logs/uvm_p6_p26_multiseed_summary.csv`
- `rtl/l1_cache/logs/uvm_p6_mode_compare_summary.csv`
- `rtl/l1_cache/logs/uvm_p6_perf_raw.csv`
- `rtl/l1_cache/logs/UVM_PHASE6_REVIEW_BUNDLE.txt`
- `rtl/l1_cache/logs/UVM_PHASE6_FINAL_REVIEW_BUNDLE.txt`
- `rtl/l1_cache/docs/UVM_PHASE6_FINAL_UBUNTU_COMMANDS.md`

## Important Notes

- No Phase 6 PASS is claimed until the user runs the Ubuntu/Questa command and
  the log/CSV confirms it.
- P15 and P26 are intentionally not faked: they PASS only after their new
  Questa/UVM evidence is generated and checked.
- P27-P29 are intentionally not faked. They remain BLOCKED until true UVM
  NO_CACHE and DCACHE_ONLY wrappers exist alongside FULL_L1.
- P13/P14/P16 require separate runs because each memory latency mode is a
  different DUT parameterization.
- P17-P22 use passive-monitor temporal counters. Treat them as performance
  evidence, not proof of internal arbiter/MSHR/VBUF microarchitecture.
- P17-P22 are run in no-wait memory mode to isolate back-to-back behavior from
  the memory-latency sensitivity already covered by P13/P14/P16.
- P23-P25 are run in no-wait memory mode with a bounded countdown loop. P26 is
  not claimed by the single-run D target.
- Full Phase 6 must not be reported as PASS while P27-P29 lack real UVM mode
  wrappers.

## Final Closure Attempt Additions

The closure update adds real infrastructure for P15 and P26:

- P15 random wait:
  - Adds random wait parameters to the work-area `l1_mem_arbiter`.
  - Keeps fixed/no-wait/long-wait behavior unchanged when random wait is off.
  - Uses a deterministic seeded LFSR delay per accepted memory read and write
    response when random wait is enabled.
  - Emits `uvm_p6_p15_random_wait_distribution.csv`.
  - Requires at least 16 read samples and at least 2 distinct observed read
    latency values before P15 can PASS.

- P26 multi-seed:
  - Adds an aggregate runner that launches separate Questa/UVM seed runs.
  - Full mode uses seeds `1 2 3 5 7`.
  - Each seed has its own log and measurement summary.
  - Emits `uvm_p6_p26_multiseed_summary.csv`.
  - P26 PASS is printed only when every selected seed run passes with clean
    UVM, scoreboard, and timeout checks.

P27-P29 remain evidence-safe:

- The repository has a legacy Verilator 3-mode comparison flow, but it is not
  used as primary UVM evidence.
- The current UVM testbench has deep Full L1 hierarchy references into CVA6
  I-cache and HPDCache internals.
- True P27-P29 PASS still requires UVM NO_CACHE and DCACHE_ONLY wrappers with
  the same benchmark, scoreboard/correctness guard, memory model, and
  measurement rule as FULL_L1.
- Until those wrappers exist, the mode-compare target emits BLOCKED markers and
  `uvm_p6_mode_compare_summary.csv` instead of fake PASS.
