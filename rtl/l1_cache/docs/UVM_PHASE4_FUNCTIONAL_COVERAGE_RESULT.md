# UVM Phase 4 Functional Coverage Result

Date: 2026-06-04

## Correction Applied

The `TestCase` sheet in `CV32_L1Cache_Testplan_final.xlsx` is the source of truth for testcase rows. The `Coverage` sheet is the source of truth for coverpoint/cross names. Phase 4 does not define a standalone generic coverage list. Every non-empty testcase row is represented exactly once in the coverage matrix.

## Inputs

- Testplan workbook: `C:/CanhDac/SOURCE_ENV/CV32_L1Cache_Testplan_final.xlsx`
- Sheets used: `TestCase`, `Coverage`
- Sheets excluded from Phase 4: `Performance`, `Performance test`
- Matrix Markdown: `rtl/l1_cache/docs/UVM_PHASE4_TESTPLAN_COVERAGE_MATRIX.md`
- Matrix CSV: `rtl/l1_cache/logs/uvm_phase4_testplan_coverage_matrix.csv`
- UVM Phase 4 runtime target: `make HPDCACHE_SRC_MODE=base run_uvm_p4_functional_coverage`
- Primary UVM evidence log: `rtl/l1_cache/logs/QUESTA_phase3_directed_suite_rerun.log`
- Phase 2 transaction CSV: `rtl/l1_cache/logs/uvm_phase2_transaction_counts.csv`

## Result Summary

- Total testcase rows: `57`
- Mapped testcase rows: `57`
- PASS count: `7`
- PARTIAL count: `13`
- DEFERRED count: `33`
- NOT_COVERED count: `4`
- Missing testcase rows: `0`

## Runtime Implementation

- `cv32_l1_coverage` now receives monitor transactions from `sys_monitor`, `core_monitor`, `mem_monitor`, `icache_monitor`, and `dcache_monitor`.
- `uvm_p4_functional_coverage_test` runs the existing full L1 UVM program, checks the Phase 3 scoreboard conditions, then emits the Phase 4 matrix from observed monitor/perf counters.
- `[UVM][P4_MATRIX][PASS]` means the matrix was generated completely with `missing_testcase_rows=0` and no missing testcase row.
- `[UVM][P4_FUNC_COV][PASS]` is now reserved for real coverage closure: `PASS=57`, `PARTIAL=0`, `DEFERRED=0`, `NOT_COVERED=0`, and `missing=0`.
- With the current evidence level, Phase 4 is matrix-complete but functional coverage is not closed yet.
- Deep PLRU/VBUF/MSHR/RTAB items remain `DEFERRED` or `PARTIAL` unless a real monitor/checker observes the required condition.

## Status By Group

| Group | PASS | PARTIAL | DEFERRED | NOT_COVERED | Total |
| --- | ---: | ---: | ---: | ---: | ---: |
| A | 1 | 2 | 6 | 2 | 11 |
| B | 1 | 3 | 0 | 1 | 5 |
| C | 0 | 2 | 3 | 1 | 6 |
| D | 0 | 0 | 4 | 0 | 4 |
| E | 0 | 3 | 2 | 0 | 5 |
| F | 0 | 1 | 4 | 0 | 5 |
| G | 4 | 1 | 0 | 0 | 5 |
| H | 1 | 1 | 14 | 0 | 16 |

## PASS Evidence Used

- `QUESTA_phase3_directed_suite_rerun.log`: all five Phase 3 UVM tests pass, `UVM_ERROR=0`, `UVM_FATAL=0`, scoreboard `strict_errors=0 warnings=0`.
- UVM monitor/scoreboard counters observed: `instr_accept=18`, `instr_rsp=18`, `load_accept=3`, `store_accept=5`, `load_rsp=3`, `ic_read_req/rsp=5/5`, `dc_read_req/rsp/last=5/5/5`, `dc_write_addr/data/rsp=2/2/2`.
- DUT perf counters observed: `icache_miss/refill=5/5`, `dcache_miss=9`, `mem_read/write=10/2`, `read_miss=5`, `write_miss=4`.
- `uvm_phase2_transaction_counts.csv`: `uvm_full_l1_basic_test` PASS with the same transaction counters and zero scoreboard errors/warnings.

## Deferred / Partial Policy

- Deep PLRU/VBUF/MSHR/RTAB/arbiter-internal testcases are not marked PASS unless a high-confidence UVM monitor or checker exists.
- Performance, stress, random, or multi-seed statistical testcase rows are marked `DEFERRED` with reason `DEFERRED_TO_PHASE5_6` when current UVM Phase 4 evidence is insufficient.
- Existing Verilator performance CSV is noted only as non-UVM performance evidence and is not used to PASS UVM Phase 4 functional coverage rows.

## Required Follow-Up

1. Implement Phase 4 collector from this testplan matrix, not from a generic coverage list.
2. Add monitor/checker support before changing deferred deep rows to PASS.
3. Re-run UVM and regenerate the matrix after implementation.
4. Keep missing testcase rows at `0`.
