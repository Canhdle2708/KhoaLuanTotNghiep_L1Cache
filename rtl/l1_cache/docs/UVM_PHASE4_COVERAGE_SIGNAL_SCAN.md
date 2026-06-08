# UVM Phase 4 Coverage Signal Scan

Date: 2026-06-04

## Scope

This scan is for planning Phase 4 only. No RTL, UVM source, Makefile, or script implementation is changed by this document.

## Baseline Evidence

The exact requested baseline log `rtl/l1_cache/logs/QUESTA_phase3_baseline_before_phase4.log` is not present in the shared workspace at planning time. Codex cannot run Ubuntu Questa locally from the Windows workspace, so this scan uses the latest verified Phase 3 suite log:

- Log: `rtl/l1_cache/logs/QUESTA_phase3_directed_suite_rerun.log`
- Status from that log: `PASS`
- HPDCACHE_SRC_MODE: `base`
- Questa coverage status: `questa_enable_coverage: 0`
- UCDB default: disabled
- P3 PASS markers found:
  - `[UVM][P3_RESET_BASIC][PASS]`
  - `[UVM][P3_ICACHE_DIRECTED][PASS]`
  - `[UVM][P3_DCACHE_DIRECTED][PASS]`
  - `[UVM][P3_CORNER_ORDERING][PASS]`
  - `[UVM][P3_WRITEBACK_DIRECTED][PASS]`
- UVM summary for each P3 test: `UVM_ERROR : 0`, `UVM_FATAL : 0`
- Scoreboard summary for each P3 test: `strict_errors=0 warnings=0`

Before implementing Phase 4, run the requested baseline command again to create the exact baseline log name:

```sh
FULL_L1_ROOT=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master
cd "$FULL_L1_ROOT/rtl/l1_cache/work/sim" || exit 1
mkdir -p ../../logs

make HPDCACHE_SRC_MODE=base run_uvm_p3_directed_suite \
  2>&1 | tee ../../logs/QUESTA_phase3_baseline_before_phase4.log

grep -E "\[UVM\]\[P3_.*\]\[PASS\]|UVM_ERROR|UVM_FATAL|strict_errors|warnings|run_uvm_p3_directed_suite exit=0|HPDCACHE_SRC_MODE|questa_enable_coverage|QUESTA_ENABLE_COVERAGE" \
  ../../logs/QUESTA_phase3_baseline_before_phase4.log || true
```

## Existing Coverage Skeleton

File: `rtl/l1_cache/work/uvm/env/cv32_l1_coverage.sv`

Current state:

- Defines coverage-related enums for request source, cache result, D-cache request type, store type, byte enable, victim type, writeback event, VBUF event, MSHR/RTAB event, arbiter event, reset point, response type, performance counter event, and PLRU select case.
- Defines `cv32_l1_coverage extends uvm_component`.
- Has an SV `covergroup full_l1_cg` guarded by `UVM_USE_SV_COVERGROUPS`.
- The covergroup is not enabled by default.
- There are no analysis exports/imps in this component today.
- `cv32_l1_env` creates the component, but does not connect any monitor analysis ports into it.
- `note_phase1_skeleton_only()` explicitly reports that SV covergroups are disabled by default for Questa Starter compatibility.

Conclusion: keep this file as the optional SV covergroup home, but do not rely on it as the default Phase 4 pass mechanism.

## Transaction Classes

Folder: `rtl/l1_cache/work/uvm/txn/`

Available transaction types:

| Transaction | Useful fields | Phase 4 use |
| --- | --- | --- |
| `cv32_l1_sys_txn` | `rst_n`, `fetch_enable`, `done`, `pass`, `timeout_seen`, `critical_xz_seen`, `event_kind` | System/basic coverage and result coverage |
| `cv32_l1_core_txn` | `channel`, `op`, `addr`, `rdata`, `wdata`, `be`, `we`, `err` | Core op, byte-enable, load/store/fetch coverage |
| `cv32_l1_mem_txn` | `channel`, `addr`, `data`, `be`, `last`, `error` | I-cache/D-cache memory protocol coverage |
| `cv32_l1_event_txn` | `event_kind`, `addr`, `value`, `source` | I-cache/D-cache miss/refill event coverage |

These are high-confidence sampling sources because they are already used by the Phase 2 scoreboard/perf collector and passed Phase 3.

## Monitor Analysis Ports

Folder: `rtl/l1_cache/work/uvm/monitors/`

| Monitor | Analysis output today | Sample confidence | Notes |
| --- | --- | --- | --- |
| `cv32_l1_sys_monitor` | `sys_ap` emits `cv32_l1_sys_txn` | High | Detects reset deassert, fetch enable, done, pass, timeout, critical X/Z |
| `cv32_l1_core_monitor` | `core_ap` emits `cv32_l1_core_txn` | High | Emits `IFETCH_ACCEPT`, `IFETCH_RSP`, `LOAD_ACCEPT`, `STORE_ACCEPT`, `LOAD_RSP` |
| `cv32_l1_mem_monitor` | `mem_ap` emits `cv32_l1_mem_txn` | High | Emits I-cache read req/rsp and D-cache read/write split transactions |
| `cv32_l1_icache_monitor` | `event_ap` emits `cv32_l1_event_txn` | High | Emits `ICACHE_MISS`, `ICACHE_REFILL_RETURN` |
| `cv32_l1_dcache_monitor` | `event_ap` emits `cv32_l1_event_txn` | High | Emits `DCACHE_READ_MISS`, `DCACHE_WRITE_MISS`, `DCACHE_READ_REQ`, `DCACHE_WRITE_REQ` |
| `cv32_l1_vbuf_monitor` | no analysis port | Low | Debug/skeleton level only; do not make required Phase 4 coverage depend on it |
| `cv32_l1_plru_monitor` | no analysis port | Low | Skeleton only; PLRU deep coverage should be deferred |
| `cv32_l1_mshr_rtab_monitor` | no analysis port | Low | Skeleton only; MSHR/RTAB deep coverage should be deferred |
| `cv32_l1_arbiter_monitor` | no analysis port | Medium-low | Has debug visibility, but no transaction stream yet |

## Env Connections

File: `rtl/l1_cache/work/uvm/env/cv32_l1_env.sv`

Existing connections:

- `sys_monitor.sys_ap -> scoreboard.sys_export`
- `core_monitor.core_ap -> scoreboard.core_export`
- `core_monitor.core_ap -> perf_collector.core_export`
- `mem_monitor.mem_ap -> scoreboard.mem_export`
- `mem_monitor.mem_ap -> perf_collector.mem_export`
- `icache_monitor.event_ap -> perf_collector.event_export`
- `dcache_monitor.event_ap -> perf_collector.event_export`

Missing for Phase 4:

- Coverage collector is not connected to `sys_ap`, `core_ap`, `mem_ap`, or `event_ap`.
- `cv32_l1_coverage` has no analysis imps/exports today.

Recommendation:

- Add a separate counter-based coverage collector with `_sys`, `_core`, `_mem`, and `_event` analysis imps.
- Connect the same high-confidence monitor streams into the coverage collector.
- Keep scoreboard behavior unchanged.

## Scoreboard And Perf Collector Reuse

Files:

- `rtl/l1_cache/work/uvm/env/cv32_l1_scoreboard.sv`
- `rtl/l1_cache/work/uvm/env/cv32_l1_perf_collector.sv`

Useful existing counters:

- Core: `instr_accept_count`, `instr_rsp_count`, `load_accept_count`, `store_accept_count`, `load_rsp_count`
- Memory: `icache_read_req_count`, `icache_read_rsp_count`, `dcache_read_req_count`, `dcache_read_rsp_count`, `dcache_write_addr_count`, `dcache_write_data_count`, `dcache_write_rsp_count`
- Event: `icache_miss_event_count`, `icache_refill_event_count`, `dcache_read_miss_event_count`, `dcache_write_miss_event_count`
- DUT perf counters through `cfg.perf_vif`: `icache_miss_count`, `icache_refill_count`, `dcache_miss_count`, `read_miss_count`, `write_miss_count`, `mem_read_count`, `mem_write_count`

Recommendation:

- Do not overload the scoreboard as the coverage collector.
- Reuse the same transaction streams and optionally copy only final pass/fail status from scoreboard/test context.
- Keep Phase 4 coverage pass/fail separate from Phase 2/3 scoreboard pass/fail.

## Phase 3 Test Reuse

Files:

- `rtl/l1_cache/work/uvm/tests/uvm_p3_reset_basic_test.sv`
- `rtl/l1_cache/work/uvm/tests/uvm_p3_icache_directed_test.sv`
- `rtl/l1_cache/work/uvm/tests/uvm_p3_dcache_directed_test.sv`
- `rtl/l1_cache/work/uvm/tests/uvm_p3_corner_ordering_test.sv`
- `rtl/l1_cache/work/uvm/tests/uvm_p3_writeback_directed_test.sv`
- `rtl/l1_cache/work/uvm/phase3_directed/cv32_l1_phase3_test_utils.sv`

The Phase 3 tests all reuse `run_basic_program_to_done()` and then check different observable aspects. Phase 4 should reuse them as coverage-producing tests instead of creating new stimulus immediately.

## Existing CSV Evidence

File: `rtl/l1_cache/logs/uvm_phase2_transaction_counts.csv`

Observed row:

```text
uvm_full_l1_basic_test,FULL_L1,full_l1_basic,0,PASS,356,18,18,3,5,3,5,5,5,5,2,2,2,10,18,3,5,10,2,0,0
```

This confirms the Phase 2 transaction streams have enough basic signal for Phase 4 groups A through G.

## High Confidence Coverage Sources

Use now:

- `cv32_l1_sys_txn`
- `cv32_l1_core_txn`
- `cv32_l1_mem_txn`
- `cv32_l1_event_txn`
- `cfg.perf_vif` final counters
- Scoreboard final status and strict error/warning count

Defer:

- Deep VBUF internal state coverage
- Deep PLRU victim-selection coverage
- Deep MSHR/RTAB allocation/replay coverage
- Arbiter contention coverage beyond externally observable I/D memory traffic

