# UVM Phase 6 ChatGPT Review Notes

## What To Review

Review Phase 6 after Ubuntu/Questa has generated logs and CSV files.

Primary files:

- `rtl/l1_cache/logs/UVM_PHASE6_REVIEW_BUNDLE.txt`
- `rtl/l1_cache/logs/uvm_p6_perf_summary.csv`
- `rtl/l1_cache/logs/uvm_p6_perf_test_matrix.csv`
- `rtl/l1_cache/logs/uvm_p6_group_summary.csv`

## Expected Markers

The log should contain:

- `[UVM][P6_PERF][SUMMARY]`
- `[UVM][P6_TEST][P1]` through `[UVM][P6_TEST][P29]`
- `[UVM][P6_GROUP_A1][PASS/FAIL]`
- `[UVM][P6_GROUP_A2][PASS/FAIL]`
- `[UVM][P6_GROUP_B][PASS/FAIL]`
- `[UVM][P6_GROUP_C][PASS/FAIL]`
- `[UVM][P6_GROUP_D][PASS/FAIL]`
- `[UVM][P6_GROUP_E][PASS/FAIL]`
- `[UVM][P6_GROUP_ALL][PASS/FAIL]`
- `[UVM][P6_PERF][PASS/FAIL]`

## Known Status Before Simulation

This implementation is a framework plus first measurable batches. It must be
validated by Questa logs.

- A1/A2 may PASS if the new workload produces enough transactions and deep
  events.
- B uses parameterized UVM top runs:
  P13 no-wait, P14 fixed-wait, and P16 long-wait may PASS from separate
  Questa runs. P15 remains BLOCKED until a randomized wait-state memory model
  exists.
- C may PASS if passive-monitor back-to-back counters meet target. These are
  temporal gap/window counters and should be reported as best-effort
  performance evidence. C uses no-wait memory parameters so P17-P22 are not
  dominated by P13/P14/P16 memory-latency effects.
- D may PASS P23-P25 with the bounded long-run countdown loop. P26 remains
  DEFERRED until a multi-seed aggregate runner/report exists.
- E is BLOCKED until no-cache and D-cache-only UVM wrappers are available.

## Reliability Rules

- Do not report PASS from planned status.
- Read the log and CSV first.
- If minimum transaction count is not met, treat that P test as FAIL.
- If metric source is not reliable, report DEFERRED or BLOCKED.
- Do not use Verilator as primary UVM evidence.
