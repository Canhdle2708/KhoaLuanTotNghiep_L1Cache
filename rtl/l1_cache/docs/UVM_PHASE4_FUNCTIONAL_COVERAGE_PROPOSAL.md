# UVM Phase 4 Functional Coverage Proposal

Date: 2026-06-04

## Status

This is a proposal only. No UVM, RTL, Makefile, or script implementation is changed by this document.

## 1. Baseline Phase 3 Status Before Phase 4

Requested baseline command:

```sh
cd /media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
make HPDCACHE_SRC_MODE=base run_uvm_p3_directed_suite \
  2>&1 | tee ../../logs/QUESTA_phase3_baseline_before_phase4.log

grep -E "\[UVM\]\[P3_.*\]\[PASS\]|UVM_ERROR|UVM_FATAL|strict_errors|warnings|run_uvm_p3_directed_suite exit=0|HPDCACHE_SRC_MODE|questa_enable_coverage|QUESTA_ENABLE_COVERAGE" \
  ../../logs/QUESTA_phase3_baseline_before_phase4.log \
  2>&1 | tee ../../logs/QUESTA_phase3_baseline_before_phase4_check.log || true
```

Planning-time baseline evidence:

| Item | Value |
| --- | --- |
| Exact requested log present | No, `rtl/l1_cache/logs/QUESTA_phase3_baseline_before_phase4.log` was not found in the shared workspace |
| Latest verified Phase 3 suite log used for planning | `rtl/l1_cache/logs/QUESTA_phase3_directed_suite_rerun.log` |
| Baseline status from latest verified log | `PASS` |
| Backend | Questa Altera Starter FPGA Edition 2025.2 |
| HPDCACHE_SRC_MODE | `base` |
| Patched HPDCache selected | No |
| Questa coverage | `questa_enable_coverage: 0` |
| UCDB default | Disabled |
| UVM_ERROR | `0` for each P3 test |
| UVM_FATAL | `0` for each P3 test |
| Scoreboard | `strict_errors=0 warnings=0` for each P3 test |

PASS markers observed in the latest verified Phase 3 suite log:

- `[UVM][P3_RESET_BASIC][PASS]`
- `[UVM][P3_ICACHE_DIRECTED][PASS]`
- `[UVM][P3_DCACHE_DIRECTED][PASS]`
- `[UVM][P3_CORNER_ORDERING][PASS]`
- `[UVM][P3_WRITEBACK_DIRECTED][PASS]`

Gate before implementation:

- Before writing Phase 4 code, create the exact requested baseline log `QUESTA_phase3_baseline_before_phase4.log`.
- If that baseline fails, stop and write `rtl/l1_cache/docs/UVM_PHASE4_BASELINE_FAIL_REPORT.md`.
- Do not implement Phase 4 on a failing Phase 3 baseline.

## 2. Current Coverage Infrastructure Scan

Existing coverage file:

- `rtl/l1_cache/work/uvm/env/cv32_l1_coverage.sv`
- It currently defines coverage enums and an optional `covergroup full_l1_cg`.
- The covergroup is guarded by `UVM_USE_SV_COVERGROUPS`.
- It is not enabled by default.
- It has no UVM analysis imps/exports.
- It is instantiated in `cv32_l1_env`, but no monitor analysis ports connect to it.

Available transaction sources:

| Source | Transaction | Coverage use |
| --- | --- | --- |
| `sys_monitor.sys_ap` | `cv32_l1_sys_txn` | reset/fetch/done/pass/timeout/XZ/result |
| `core_monitor.core_ap` | `cv32_l1_core_txn` | IFETCH/load/store/response/byte-enable |
| `mem_monitor.mem_ap` | `cv32_l1_mem_txn` | I-cache read, D-cache read, D-cache write address/data/response |
| `icache_monitor.event_ap` | `cv32_l1_event_txn` | I-cache miss/refill event |
| `dcache_monitor.event_ap` | `cv32_l1_event_txn` | D-cache read/write miss and request event |
| `cfg.perf_vif` | final DUT counters | final sanity counters and expected hit checks |
| `scoreboard` | final status/counters | pass/fail, strict errors, warnings, ordering checks |

Existing analysis connections:

- `sys_monitor.sys_ap -> scoreboard.sys_export`
- `core_monitor.core_ap -> scoreboard.core_export`
- `core_monitor.core_ap -> perf_collector.core_export`
- `mem_monitor.mem_ap -> scoreboard.mem_export`
- `mem_monitor.mem_ap -> perf_collector.mem_export`
- `icache_monitor.event_ap -> perf_collector.event_export`
- `dcache_monitor.event_ap -> perf_collector.event_export`

Missing for Phase 4:

- Coverage collector is not connected to the monitor streams.
- No Phase 4 CSV/Markdown coverage report exists.
- No `run_uvm_p4_*` Make targets exist.

## 3. Recommended Phase 4 Strategy

### Option A: Counter-Based Functional Coverage

Recommended first.

Properties:

- Works with `QUESTA_ENABLE_COVERAGE=0`.
- Does not require UCDB.
- Does not require simulator coverage license features.
- Samples from real UVM monitor transactions that already passed Phase 2/3.
- Emits deterministic CSV and terminal/Markdown summary.
- Can run on Questa Starter without changing the default flow.

Why this is the right first step:

- The current verified UVM infrastructure already has reliable passive monitors for sys/core/mem/cache-event traffic.
- Phase 3 already proves the main directed test cases PASS with no UVM errors/fatals.
- The project must keep UCDB disabled by default.
- It avoids false confidence from optional covergroups that may compile but not produce usable licensed coverage output.

### Option B: Optional SV Covergroup

Use later, only after Option A passes.

Properties:

- Guard with `UVM_USE_SV_COVERGROUPS`.
- Run only when `QUESTA_ENABLE_COVERAGE=1`.
- Do not enable UCDB by default.
- If Questa Starter behavior or licensing is not suitable, fallback to Option A without changing Phase 4 pass/fail.

Recommendation:

- Implement Option A first and make it the official Phase 4 pass criterion.
- Keep Option B as an experiment, not as the default or required flow.

## 4. Proposed Coverage Model

| Coverage ID | Group | Cover Item | Source transaction/signal | Expected hit | Test producing hit | Priority |
| --- | --- | --- | --- | --- | --- | --- |
| P4_A_01 | A System/basic | reset deassert observed | `cv32_l1_sys_txn.event_kind == RESET_DEASSERT` | `>0` | `uvm_p3_reset_basic_test` | Must |
| P4_A_02 | A System/basic | fetch enable observed | `cv32_l1_sys_txn.event_kind == FETCH_ENABLE_ASSERT` | `>0` | `uvm_p3_reset_basic_test` | Must |
| P4_A_03 | A System/basic | done observed | `cv32_l1_sys_txn.done` or `DONE_ASSERT` | `>0` | all P3 tests | Must |
| P4_A_04 | A System/basic | pass observed | `cv32_l1_sys_txn.pass` or `PASS_ASSERT` | `>0` | all P3 tests | Must |
| P4_A_05 | A System/basic | no timeout | `timeout_seen == 0` final | true | all P3 tests | Must |
| P4_A_06 | A System/basic | no critical X/Z | `critical_xz_seen == 0` final | true | all P3 tests | Must |
| P4_B_01 | B Core transaction | instruction fetch accept | `cv32_l1_core_txn.op == IFETCH_ACCEPT` | `>0` | all P3 tests | Must |
| P4_B_02 | B Core transaction | instruction fetch response | `cv32_l1_core_txn.op == IFETCH_RSP` | `>0` | all P3 tests | Must |
| P4_B_03 | B Core transaction | data load accept | `cv32_l1_core_txn.op == LOAD_ACCEPT` | `>0` | D-cache/corner/writeback P3 | Must |
| P4_B_04 | B Core transaction | data store accept | `cv32_l1_core_txn.op == STORE_ACCEPT` | `>0` | D-cache/corner/writeback P3 | Must |
| P4_B_05 | B Core transaction | data load response | `cv32_l1_core_txn.op == LOAD_RSP` | `>0` | D-cache/corner/writeback P3 | Must |
| P4_B_06 | B Core transaction | full-word byte enable | `cv32_l1_core_txn.be == 4'b1111` | `>0` | D-cache/writeback P3 | Should |
| P4_B_07 | B Core transaction | byte/half/other byte enable | `cv32_l1_core_txn.be` decoded | `>=0`, report only first | existing program may not hit all | Nice |
| P4_C_01 | C I-cache | I-cache memory read request | `cv32_l1_mem_txn.channel == ICACHE_READ_REQ` | `>0` | `uvm_p3_icache_directed_test` | Must |
| P4_C_02 | C I-cache | I-cache memory read response | `cv32_l1_mem_txn.channel == ICACHE_READ_RSP` | `>0` | `uvm_p3_icache_directed_test` | Must |
| P4_C_03 | C I-cache | I-cache req/rsp balanced | scoreboard `icache_read_req_count == icache_read_rsp_count` | true | `uvm_p3_icache_directed_test` | Must |
| P4_C_04 | C I-cache | I-cache miss event | `cv32_l1_event_txn.event_kind == ICACHE_MISS` or `perf_vif.icache_miss_count > 0` | `>0` | `uvm_p3_icache_directed_test` | Must |
| P4_C_05 | C I-cache | I-cache refill event | `ICACHE_REFILL_RETURN` or `perf_vif.icache_refill_count > 0` | `>0` | `uvm_p3_icache_directed_test` | Must |
| P4_D_01 | D D-cache | load transaction observed | `LOAD_ACCEPT` | `>0` | `uvm_p3_dcache_directed_test` | Must |
| P4_D_02 | D D-cache | store transaction observed | `STORE_ACCEPT` | `>0` | `uvm_p3_dcache_directed_test` | Must |
| P4_D_03 | D D-cache | D-cache read request | `DCACHE_READ_REQ` mem transaction | `>0` | `uvm_p3_dcache_directed_test` | Must |
| P4_D_04 | D D-cache | D-cache read response | `DCACHE_READ_RSP` mem transaction | `>0` | `uvm_p3_dcache_directed_test` | Must |
| P4_D_05 | D D-cache | D-cache last response observed | `cv32_l1_mem_txn.last` on `DCACHE_READ_RSP` | `>0` | `uvm_p3_dcache_directed_test` | Must |
| P4_D_06 | D D-cache | D-cache miss event/counter | `DCACHE_READ_MISS`, `DCACHE_WRITE_MISS`, or `perf_vif.dcache_miss_count > 0` | `>0` | `uvm_p3_dcache_directed_test` | Must |
| P4_E_01 | E Writeback | D-cache write address observed | `DCACHE_WRITE_ADDR` | `>0` | `uvm_p3_writeback_directed_test` | Must |
| P4_E_02 | E Writeback | D-cache write data observed | `DCACHE_WRITE_DATA` | `>0` | `uvm_p3_writeback_directed_test` | Must |
| P4_E_03 | E Writeback | D-cache write response observed | `DCACHE_WRITE_RSP` | `>0` | `uvm_p3_writeback_directed_test` | Must |
| P4_E_04 | E Writeback | memory write counter observed | `perf_vif.mem_write_count > 0` | true | `uvm_p3_writeback_directed_test` | Must |
| P4_E_05 | E Writeback | write address/data sanity | `dcache_write_addr_count > 0 && dcache_write_data_count > 0` | true | `uvm_p3_writeback_directed_test` | Must |
| P4_F_01 | F Arbiter/full L1 | I-cache memory path used | `ICACHE_READ_REQ` | `>0` | all P3 tests | Must |
| P4_F_02 | F Arbiter/full L1 | D-cache memory read path used | `DCACHE_READ_REQ` | `>0` | D-cache/writeback P3 | Must |
| P4_F_03 | F Arbiter/full L1 | D-cache memory write path used | `DCACHE_WRITE_ADDR/DATA/RSP` | `>0` | writeback P3 | Must |
| P4_F_04 | F Arbiter/full L1 | observed memory read total sanity | `icache_read_req_count + dcache_read_req_count` | equals scoreboard total | all P3 tests | Must |
| P4_F_05 | F Arbiter/full L1 | I and D read traffic both observed in one run | mem transaction sources | true | D-cache/writeback P3 | Should |
| P4_G_01 | G Corner/ordering | no response without pending | scoreboard strict errors | `0` | `uvm_p3_corner_ordering_test` | Must |
| P4_G_02 | G Corner/ordering | no negative pending | scoreboard pending counters | true | `uvm_p3_corner_ordering_test` | Must |
| P4_G_03 | G Corner/ordering | no final load pending | scoreboard `load_pending_count == 0` | true | `uvm_p3_corner_ordering_test` | Must |
| P4_G_04 | G Corner/ordering | no final I-cache read pending | scoreboard `icache_read_pending_count == 0` | true | `uvm_p3_corner_ordering_test` | Must |
| P4_G_05 | G Corner/ordering | no final D-cache read pending | scoreboard `dcache_read_pending_count == 0` | true | `uvm_p3_corner_ordering_test` | Must |
| P4_G_06 | G Corner/ordering | load after store scenario observed | core op order in transaction stream | report initially | existing program likely produces both ops | Should |
| P4_H_01 | H Optional/deferred | VBUF allocation/deep events | no reliable analysis transaction today | deferred | future VBUF test | Deferred |
| P4_H_02 | H Optional/deferred | PLRU victim way/deep replacement | no reliable analysis transaction today | deferred | future PLRU test | Deferred |
| P4_H_03 | H Optional/deferred | MSHR/RTAB allocation/replay | no reliable analysis transaction today | deferred | future MSHR/RTAB test | Deferred |
| P4_H_04 | H Optional/deferred | arbiter contention internals | no reliable analysis transaction today | deferred | future contention test | Deferred |

## 5. Proposed Cross Coverage

| Cross ID | Cross | Source | Reason | Priority |
| --- | --- | --- | --- | --- |
| P4_X_01 | `test_kind x core_op` | P4 test context plus `cv32_l1_core_txn.op` | Proves each P3-directed test produced expected core traffic | Must |
| P4_X_02 | `core_op x mem_source` | `cv32_l1_core_txn.op` plus `cv32_l1_mem_txn.channel` | Shows fetch/load/store traffic reaches memory-side paths | Must |
| P4_X_03 | `dcache op x byte_enable` | data `LOAD/STORE` plus `cv32_l1_core_txn.be` | Tracks store/load access width coverage | Should |
| P4_X_04 | `mem_source x mem_event` | `cv32_l1_mem_txn.channel` | Confirms read/write request/response combinations | Must |
| P4_X_05 | `test_kind x cache_event` | test context plus `cv32_l1_event_txn.event_kind` | Shows which directed test hits I/D miss/refill events | Must |
| P4_X_06 | `result x test_kind` | scoreboard final status plus test context | Prevents fake coverage from failing tests | Must |
| P4_X_07 | `icache_req x icache_rsp` | scoreboard/perf collector counters | Confirms I-cache protocol balance | Must |
| P4_X_08 | `dcache_read_req x dcache_read_last` | scoreboard/perf collector counters | Confirms D-cache read completion coverage | Must |
| P4_X_09 | `dcache_write_addr x dcache_write_data x dcache_write_rsp` | memory transaction counters | Confirms writeback handshake visibility | Must |
| P4_X_10 | `timeout_or_xz x result` | sys transaction plus scoreboard status | Ensures error cases are tracked as fail, not pass | Must |

## 6. Proposed Files To Create

| File | Purpose |
| --- | --- |
| `rtl/l1_cache/work/uvm/phase4_coverage/cv32_l1_phase4_cov_types.sv` | Coverage IDs, group IDs, status enum, expected-hit metadata |
| `rtl/l1_cache/work/uvm/phase4_coverage/cv32_l1_phase4_cov_collector.sv` | Counter-based collector using monitor analysis transactions |
| `rtl/l1_cache/work/uvm/phase4_coverage/cv32_l1_phase4_cov_reporter.sv` | CSV and terminal/Markdown report writer |
| `rtl/l1_cache/work/uvm/tests/uvm_p4_functional_coverage_test.sv` | Umbrella test that reuses Phase 3 flow and checks coverage |
| `rtl/l1_cache/logs/uvm_phase4_functional_coverage.csv` | Runtime coverage matrix output |
| `rtl/l1_cache/logs/QUESTA_phase4_functional_coverage.log` | Runtime command log |

Optional later:

- `rtl/l1_cache/work/uvm/phase4_coverage/cv32_l1_phase4_sv_covergroups.sv`

## 7. Proposed Files To Modify

| File | Why |
| --- | --- |
| `rtl/l1_cache/work/uvm/pkg/cv32_l1_uvm_pkg.sv` | Include Phase 4 coverage files and P4 test explicitly |
| `rtl/l1_cache/work/sim/cv32_l1_uvm_questa.f` | Add `+incdir+../uvm/phase4_coverage` |
| `rtl/l1_cache/work/uvm/env/cv32_l1_env.sv` | Instantiate/connect Phase 4 coverage collector to monitor analysis ports |
| `rtl/l1_cache/work/uvm/env/cv32_l1_coverage.sv` | Optional only; keep existing skeleton or bridge optional SV covergroup mode |
| `rtl/l1_cache/work/sim/run_uvm_questa.sh` | Optional plusarg/env for Phase 4 CSV path while preserving defaults |
| `rtl/l1_cache/work/sim/Makefile` | Add repeatable `run_uvm_p4_*` targets |

Expected impact:

- Phase 1/2/3 should remain unchanged because existing monitor, scoreboard, and perf collector connections remain intact.
- Phase 5/6 risk is low if Phase 4 only adds passive collector/reporting. Avoid changing performance counters or run scripts defaults.

## 8. Proposed Commands And Targets

Proposed targets:

- `run_uvm_p4_functional_coverage`
- `run_uvm_p4_coverage_suite`

Command/log convention:

- Use the user's Questa root `/home/vboxuser/altera/25.1std`.
- Use license `/media/sf_source_env/LR-166346_License.dat`.
- Prefer the existing Make targets, which call `run_uvm_questa.sh`, after
  setting the environment below.
- Keep every proposed run command logged with `tee` under `../../logs`.

Default counter-based run:

```sh
cd /media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
bash -n run_uvm_questa.sh 2>&1 | tee ../../logs/QUESTA_phase4_runner_syntax_check.log
make HPDCACHE_SRC_MODE=base run_uvm_p4_functional_coverage MAX_CYCLES=100000 \
  2>&1 | tee ../../logs/QUESTA_phase4_functional_coverage.log
```

Coverage suite:

```sh
cd /media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
make HPDCACHE_SRC_MODE=base run_uvm_p4_coverage_suite MAX_CYCLES=100000 \
  2>&1 | tee ../../logs/QUESTA_phase4_coverage_suite.log
```

Optional SV covergroup experiment:

```sh
cd /media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
QUESTA_ENABLE_COVERAGE=1 make HPDCACHE_SRC_MODE=base run_uvm_p4_functional_coverage MAX_CYCLES=100000 \
  2>&1 | tee ../../logs/QUESTA_phase4_functional_coverage_sv_cg.log
```

## 9. PASS Criteria Phase 4

Phase 4 counter-based coverage PASS requires:

- Phase 3 baseline log before implementation PASS.
- `HPDCACHE_SRC_MODE=base`.
- `QUESTA_ENABLE_COVERAGE=0` default path passes.
- UVM test finishes with `[UVM][P4_FUNC_COV][PASS]`.
- `UVM_ERROR : 0`.
- `UVM_FATAL : 0`.
- Scoreboard `strict_errors=0`.
- Must-priority P4 coverage IDs in groups A through G hit expected values.
- CSV file generated with one row per coverage ID.
- No required coverage depends on VBUF/PLRU/MSHR/RTAB deep internal paths.
- Phase 1/2 and Phase 3 rerun remain PASS after Phase 4 implementation.

## 10. FAIL Criteria Phase 4

Phase 4 fails if any of these occur:

- Phase 3 baseline before Phase 4 fails.
- Any UVM error/fatal appears.
- Scoreboard strict errors are nonzero.
- A Must-priority coverage item in groups A through G is not hit.
- Coverage report marks PASS when the underlying UVM test failed.
- CSV cannot be opened or written.
- Default flow requires `QUESTA_ENABLE_COVERAGE=1` or UCDB.
- Any source/script/filelist hardcodes absolute `/media` or Windows paths.

## 11. Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Questa Starter coverage/UCDB support may be limited | SV covergroup flow may fail or not produce useful UCDB | Use Option A as official default; keep Option B optional |
| False coverage from counters | Counters may prove event occurrence but not all deep semantics | Label output as counter-based functional coverage; keep deep items deferred |
| Coverage collector could disturb Phase 2/3 behavior | Bad connections or side effects could break existing tests | Collector must be passive only; rerun Phase 1/2/3 after implementation |
| Byte-enable coverage may be incomplete with current program | Existing stimulus may only hit full-word BE | Mark non-full BE as report/Should until dedicated stimulus exists |
| VBUF/PLRU/MSHR/RTAB path guessing | Fake or fragile coverage | Defer until monitor has real transaction source |
| Path hardcoding | Breaks host/Ubuntu portability | Use repo-relative filelist paths and runtime env paths only |
| Phase 5/6 conflict | Performance flow could be affected by extra reporting | Keep default output lightweight and do not change perf counters |

## 12. Recommended Implementation Order

1. Run exact Phase 3 baseline command and create `QUESTA_phase3_baseline_before_phase4.log`.
2. Implement counter-based coverage types and reporter.
3. Implement passive coverage collector with sys/core/mem/event analysis imps.
4. Connect collector in `cv32_l1_env`.
5. Add `uvm_p4_functional_coverage_test`.
6. Add explicit filelist/package includes.
7. Add Make targets.
8. Run default Phase 4 counter coverage with `QUESTA_ENABLE_COVERAGE=0`.
9. Rerun Phase 1/2 baseline and Phase 3 directed suite.
10. Only then try optional SV covergroup/UCDB mode with `QUESTA_ENABLE_COVERAGE=1`.

## 13. What Not To Do

- Do not edit HPDCache, CV32E40P, or CVA6 I-cache RTL.
- Do not use patched HPDCache.
- Do not enable UCDB by default.
- Do not require `QUESTA_ENABLE_COVERAGE=1` for Phase 4 PASS.
- Do not use wildcard `*.sv` in filelists.
- Do not hardcode `/media/sf_SOURCE_ENV`, `/media/sf_souce_env`, `C:/`, or `C:\` in source/script/filelist.
- Do not mark VBUF/PLRU/MSHR/RTAB deep coverage as PASS without high-confidence observable events.
- Do not implement Phase 5/6/7 as part of Phase 4.
- Do not fake coverage PASS.

## Summary Recommendation

Implement Phase 4 as counter-based functional coverage first. Use the proven Phase 2/3 monitor transaction streams as the official coverage source, generate CSV/terminal reports, and keep UCDB/SV covergroups as a later optional experiment only.
