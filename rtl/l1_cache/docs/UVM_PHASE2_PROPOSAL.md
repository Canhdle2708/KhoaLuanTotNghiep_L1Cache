# UVM Phase 2 Proposal

This document is a proposal only. It does not implement Phase 2.

Scope constraints:
- Simulator target: Questa 2025.2 Starter.
- UVM flow only: do not use Xcelium or Verilator for this UVM phase.
- HPDCache source mode must remain `HPDCACHE_SRC_MODE=base`.
- Do not select patched HPDCache filelists.
- Keep `QUESTA_ENABLE_COVERAGE=0` as the default.
- Do not enable SV covergroups or UCDB by default.
- Do not use wildcard `*.sv` in UVM filelists.
- Do not delete, move, or overwrite legacy functional coverage files.

## 1. Current Phase 1 Baseline

Baseline command:

```sh
cd /media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim
make HPDCACHE_SRC_MODE=base run_uvm_full_l1_basic
```

Latest checked artifacts:
- Main log: `rtl/l1_cache/logs/uvm_full_l1_basic_questa.log`
- User tee log: `rtl/l1_cache/logs/QUESTA_uvm_full_l1_basic_user_rerun_passcheck.log`
- Result doc: `rtl/l1_cache/docs/UVM_PHASE1_QUESTA_RESULT.md`
- Performance CSV: `rtl/l1_cache/logs/uvm_perf_raw.csv`

Baseline status:
- Backend: Questa/ModelSim.
- Questa version: Questa Altera Starter FPGA Edition-64 2025.2.
- HPDCACHE_SRC_MODE: `base`.
- Patched HPDCache selected: no.
- UVM library: `mtiUvm`.
- Questa coverage enabled: `0`.
- PASS marker: `[UVM][FULL_L1_BASIC][PASS]`.
- UVM_ERROR: 0.
- UVM_FATAL: 0.
- Compile errors: 0.
- Make target: `run_uvm_full_l1_basic exit=0`.

Current counters from the PASS run:

| Counter | Value |
|---|---:|
| cycle_count | 356 |
| instr_access_count | 18 |
| icache_miss_count | 5 |
| icache_refill_count | 5 |
| core_load_count | 3 |
| core_store_count | 5 |
| mem_read_count | 10 |
| mem_write_count | 2 |
| read_miss_count | 5 |
| write_miss_count | 4 |
| dcache_miss_count | 9 |

Current CSV row:

```csv
uvm_full_l1_basic_test,FULL_L1,full_l1_basic,0,356,18,3,5,10,2,5,5,9,5,4,PASS
```

Coverage status:
- SV covergroups are disabled by default for Questa Starter compatibility.
- UCDB is not generated unless `QUESTA_ENABLE_COVERAGE=1`.
- Phase 1 currently reports counter and CSV data only.

## 2. Current UVM Structure

Existing UVM filelist:
- `rtl/l1_cache/work/sim/cv32_l1_uvm_questa.f`
- The filelist is explicit. It does not use `*.sv`.

Current UVM files:

| File | Current Role | Status |
|---|---|---|
| `work/uvm/tb/tb_cv32_l1_uvm_top.sv` | Instantiates DUT, drives clock, loads basic program, maps DUT signals to UVM interfaces, calls `run_test()` | Active |
| `work/uvm/if/cv32_l1_sys_if.sv` | System control/status interface | Active |
| `work/uvm/if/cv32_l1_core_if.sv` | Core instruction/data port interface | Active |
| `work/uvm/if/cv32_l1_mem_if.sv` | Memory interface abstraction | Active but incomplete for full split write protocol |
| `work/uvm/if/cv32_l1_cache_event_if.sv` | Cache event/counter helper interface | Active for basic events |
| `work/uvm/if/cv32_l1_perf_if.sv` | Counter interface | Active |
| `work/uvm/pkg/cv32_l1_uvm_pkg.sv` | UVM package include hub | Active |
| `work/uvm/env/cv32_l1_config.sv` | Virtual interface and plusarg config | Active |
| `work/uvm/env/cv32_l1_env.sv` | Creates scoreboard, coverage, perf collector, monitors | Active |
| `work/uvm/env/cv32_l1_scoreboard.sv` | Final done/pass/counter smoke checks | Active but Phase 1 style only |
| `work/uvm/env/cv32_l1_perf_collector.sv` | Writes final `uvm_perf_raw.csv` | Active but final-only |
| `work/uvm/env/cv32_l1_coverage.sv` | Coverage enums and optional SV covergroup skeleton | Skeleton, covergroups off by default |
| `work/uvm/monitors/cv32_l1_sys_monitor.sv` | Detects critical X/Z on system signals | Active basic monitor |
| `work/uvm/monitors/cv32_l1_core_monitor.sv` | Logs instruction accepts at UVM_DEBUG | Debug-only, no transactions |
| `work/uvm/monitors/cv32_l1_mem_monitor.sv` | Logs memory read/write request presence | Debug-only, no transactions |
| `work/uvm/monitors/cv32_l1_icache_monitor.sv` | Logs I-cache miss/refill events | Debug-only, no transactions |
| `work/uvm/monitors/cv32_l1_dcache_monitor.sv` | Logs data accepts at UVM_DEBUG | Debug-only, no transactions |
| `work/uvm/monitors/cv32_l1_vbuf_monitor.sv` | Logs write buffer not empty | Debug-only, no deep check |
| `work/uvm/monitors/cv32_l1_mshr_rtab_monitor.sv` | Announces skeleton only | Skeleton |
| `work/uvm/monitors/cv32_l1_plru_monitor.sv` | Announces skeleton only | Skeleton |
| `work/uvm/monitors/cv32_l1_arbiter_monitor.sv` | Logs arbiter visible request activity | Debug-only, no transactions |
| `work/uvm/seq/*.sv` | Placeholder sequences | Skeleton |
| `work/uvm/tests/cv32_l1_base_test.sv` | Builds cfg/env and reads plusargs | Active |
| `work/uvm/tests/uvm_full_l1_basic_test.sv` | Drives reset/fetch and final checks | Active |

## 3. Proposed Phase 2 Architecture

Phase 2 should add real monitor-produced transactions and analysis connections while keeping the Phase 1 pass path intact.

Proposed data flow:

```text
sys_monitor  -> sys_ap  -> scoreboard
core_monitor -> core_ap -> scoreboard, perf_collector
mem_monitor  -> mem_ap  -> scoreboard, perf_collector
icache_monitor/dcache_monitor -> event_ap -> perf_collector, optional scoreboard sanity
```

Recommended UVM connection style:
- Add typed `uvm_analysis_port#(...)` in each real monitor.
- Add typed `uvm_analysis_imp#(...)` or `uvm_tlm_analysis_fifo#(...)` in scoreboard.
- Prefer `uvm_tlm_analysis_fifo` for scoreboard if ordering between multiple streams needs cycle-by-cycle handling.
- Keep perf collector independent: it should receive transactions and produce CSV counts, but not decide pass/fail.
- Keep Phase 1 final counter checks until Phase 2 checks are proven stable.

Do not make PLRU/VBUF/MSHR/RTAB deep checkers in Phase 2. Keep them as skeleton or event-only because the internal protocol is higher risk and needs more signal-path validation.

## 4. Proposed Transaction Classes

Create these classes under `rtl/l1_cache/work/uvm/txn`.

### `cv32_l1_sys_txn`

Fields:
- `int unsigned cycle`
- `bit rst_n`
- `bit fetch_enable`
- `bit done`
- `bit pass`
- `bit timeout_seen`
- `bit critical_xz_seen`
- `string event_kind`

Produced by:
- `cv32_l1_sys_monitor`

Used by:
- Scoreboard for done/pass/timeout/XZ checks.
- Perf collector for run summary metadata.

### `cv32_l1_core_txn`

Fields:
- `int unsigned cycle`
- `string channel` with values `INSTR`, `DATA`
- `string op` with values `IFETCH_ACCEPT`, `IFETCH_RSP`, `LOAD_ACCEPT`, `STORE_ACCEPT`, `LOAD_RSP`, `STORE_RSP_OR_ACCEPT`
- `logic [31:0] addr`
- `logic [31:0] rdata`
- `logic [31:0] wdata`
- `logic [3:0] be`
- `bit we`
- `bit err`

Produced by:
- `cv32_l1_core_monitor`

Used by:
- Scoreboard for accepted request and response sanity.
- Perf collector for instruction/data transaction counts.

Notes:
- Store completion rule is not fully explicit at the core port. Start with store accepted count based on `data_req && data_gnt && data_we`; do not require `data_rvalid` for stores until confirmed.

### `cv32_l1_mem_txn`

Fields:
- `int unsigned cycle`
- `string channel` with values `ICACHE_READ`, `DCACHE_READ`, `DCACHE_WRITE_ADDR`, `DCACHE_WRITE_DATA`, `DCACHE_WRITE_RSP`
- `logic [31:0] addr`
- `logic [127:0] data`
- `logic [15:0] be`
- `logic [3:0] id`
- `logic [7:0] len`
- `logic [2:0] size`
- `bit last`
- `bit error`

Produced by:
- `cv32_l1_mem_monitor`

Used by:
- Scoreboard for no response without pending request, basic outstanding counts, and memory request sanity.
- Perf collector for read/write request counts and optional latency histograms later.

Notes:
- The D-cache write protocol is split into address, data, and response phases. Phase 2 should count them separately.

### `cv32_l1_event_txn`

Fields:
- `int unsigned cycle`
- `string event_kind`
- `logic [31:0] addr`
- `int unsigned value`

Produced by:
- `cv32_l1_icache_monitor`
- `cv32_l1_dcache_monitor`
- Optional event-only VBUF/arbiter monitors

Used by:
- Perf collector for event counts.
- Scoreboard only for low-risk sanity checks.

## 5. Proposed Monitor Implementation

### `sys_monitor`

Signal paths:
- `cfg.sys_vif.clk`
- `cfg.sys_vif.rst_n`
- `cfg.sys_vif.fetch_enable`
- `cfg.sys_vif.done`
- `cfg.sys_vif.pass`
- `cfg.sys_vif.timeout_seen`
- `cfg.sys_vif.critical_xz_seen`

Transactions:
- Emit `cv32_l1_sys_txn` on reset deassertion, fetch enable assertion, done assertion, pass assertion, timeout, and critical X/Z.

Analysis port:
- `uvm_analysis_port#(cv32_l1_sys_txn) sys_ap`

Risk:
- Low. These signals are already used by Phase 1 and mapped directly in the UVM top.

### `core_monitor`

Signal paths:
- Instruction: `cfg.core_vif.instr_req`, `instr_gnt`, `instr_rvalid`, `instr_addr`, `instr_rdata`, `instr_err`
- Data: `cfg.core_vif.data_req`, `data_gnt`, `data_rvalid`, `data_we`, `data_be`, `data_addr`, `data_wdata`, `data_rdata`, `data_err`

Transactions:
- Emit IFETCH_ACCEPT on `instr_req && instr_gnt`.
- Emit IFETCH_RSP on `instr_rvalid`.
- Emit LOAD_ACCEPT on `data_req && data_gnt && !data_we`.
- Emit STORE_ACCEPT on `data_req && data_gnt && data_we`.
- Emit LOAD_RSP on `data_rvalid && !last_accepted_store_rule`.

Analysis port:
- `uvm_analysis_port#(cv32_l1_core_txn) core_ap`

Risk:
- Medium for store response semantics. Keep store completion rule conservative.

### `mem_monitor`

Signal paths:
- I-cache read: `cfg.mem_vif.icache_read_req`, `icache_read_ready`, `icache_read_addr`, `icache_read_rsp`
- D-cache read: `cfg.mem_vif.dcache_read_req`, `dcache_read_ready`, `dcache_read_addr`, `dcache_read_rsp`
- D-cache write: `cfg.mem_vif.dcache_write_req`, `dcache_write_ready`, `dcache_write_addr`, `dcache_write_data`, `dcache_write_be`, `dcache_write_rsp`

Recommended interface extension:
- Add explicit split protocol fields to `cv32_l1_mem_if`: `mem_resp_read_ready`, `mem_resp_read_data`, `mem_resp_read_last`, `mem_req_write_data_valid`, `mem_req_write_data_ready`, `mem_req_write_data_last`, `mem_resp_write_ready`, IDs, len, size, error.

Transactions:
- Emit read request txn on valid/ready.
- Emit read response txn on response valid/ready or response valid if ready is permanently high.
- Emit write address txn on write valid/ready.
- Emit write data txn on write data valid/ready.
- Emit write response txn on response valid/ready or response valid if ready is permanently high.

Analysis port:
- `uvm_analysis_port#(cv32_l1_mem_txn) mem_ap`

Risk:
- Medium. The current UVM memory interface is less complete than the DUT internal protocol.

### `icache_monitor`

Signal paths:
- `cfg.cache_event_vif.icache_miss`
- `cfg.cache_event_vif.icache_refill_return`
- `cfg.mem_vif.icache_read_req`
- `cfg.mem_vif.icache_read_rsp`

Transactions:
- Emit event txns for miss/refill.

Analysis port:
- `uvm_analysis_port#(cv32_l1_event_txn) event_ap`

Risk:
- Low for event count. Do not implement deep I-cache correctness in Phase 2.

### `dcache_monitor`

Signal paths:
- `cfg.cache_event_vif.dcache_read_miss`
- `cfg.cache_event_vif.dcache_write_miss`
- `cfg.cache_event_vif.dcache_read_req`
- `cfg.cache_event_vif.dcache_write_req`
- `cfg.core_vif.data_req`, `data_gnt`, `data_we`, `data_be`, `data_addr`

Transactions:
- Emit event txns for read miss, write miss, read event, write event.

Analysis port:
- `uvm_analysis_port#(cv32_l1_event_txn) event_ap`

Risk:
- Low for event count, medium if trying to classify miss type. Keep classification out of Phase 2.

### VBUF/MSHR/RTAB/PLRU/Arbiter

Recommendation:
- Keep VBUF/MSHR/RTAB/PLRU as skeleton or event-only in Phase 2.
- Arbiter may emit low-risk event txns for I-read, D-read, and D-write visible request activity.

Rationale:
- Deep paths are not fully validated.
- False failures are likely if Phase 2 tries to check replacement/writeback internals too early.

## 6. Proposed Scoreboard Checks

Implement these Phase 2 checks:

| Checker | Source | PASS Rule |
|---|---|---|
| done/pass | sys txns and final sys vif | `done==1` and `pass==1` by test end |
| timeout | sys txns and test loop | no timeout |
| critical X/Z | sys monitor | no X/Z on rst_n/fetch_enable/done/pass |
| instruction accepted/response count | core txns | accepted instruction count > 0 and responses are not greater than accepts plus configured tolerance |
| data accepted/load response/store count | core txns | load/store accepts > 0; load responses do not exceed load accepts |
| no response without pending request | core/mem txns | response requires nonzero outstanding count |
| no double response | core/mem txns | each response decrements one pending request only once |
| memory read/write sanity | mem txns | read/write request counts > 0 for baseline; no negative pending counts |
| counter consistency | perf vif and txn counts | observed counts match DUT counters where definitions align |

Start strictness:
- Instruction accept count should match `instr_access_count` if `instr_access_count` is confirmed to mean `instr_adapter_req_accept`.
- Core load/store accept counts should match `core_load_count` and `core_store_count`.
- Memory read/write observed counts may initially be WARN-only if interface semantics are incomplete.

## 7. Proposed CSV Outputs

Keep current CSV:
- `rtl/l1_cache/logs/uvm_perf_raw.csv`

Propose new CSV:
- `rtl/l1_cache/logs/uvm_phase2_transaction_counts.csv`

Header:

```csv
test_name,cache_mode,bench_name,seed,result,cycles,instr_accept,instr_rsp,data_load_accept,data_store_accept,data_load_rsp,icache_read_req,icache_read_rsp,dcache_read_req,dcache_read_rsp,dcache_write_addr,dcache_write_data,dcache_write_rsp,core_pending_final,mem_read_pending_final,mem_write_pending_final,scoreboard_errors,scoreboard_warnings
```

Do not replace `uvm_perf_raw.csv`; add the Phase 2 CSV as an additional report.

## 8. File Change Plan

Files proposed to create:
- `rtl/l1_cache/work/uvm/txn/cv32_l1_sys_txn.sv`
- `rtl/l1_cache/work/uvm/txn/cv32_l1_core_txn.sv`
- `rtl/l1_cache/work/uvm/txn/cv32_l1_mem_txn.sv`
- `rtl/l1_cache/work/uvm/txn/cv32_l1_event_txn.sv`
- Optional: `rtl/l1_cache/docs/UVM_PHASE2_RESULT.md` after implementation and regression.

Files proposed to modify in the later implementation task:
- `rtl/l1_cache/work/sim/cv32_l1_uvm_questa.f` to explicitly include new txn files.
- `rtl/l1_cache/work/uvm/pkg/cv32_l1_uvm_pkg.sv` to include txn classes before env/monitor classes.
- `rtl/l1_cache/work/uvm/env/cv32_l1_env.sv` to connect analysis ports to scoreboard/perf collector.
- `rtl/l1_cache/work/uvm/env/cv32_l1_scoreboard.sv` to receive and check transactions.
- `rtl/l1_cache/work/uvm/env/cv32_l1_perf_collector.sv` to receive txns and write Phase 2 CSV.
- `rtl/l1_cache/work/uvm/monitors/cv32_l1_sys_monitor.sv`
- `rtl/l1_cache/work/uvm/monitors/cv32_l1_core_monitor.sv`
- `rtl/l1_cache/work/uvm/monitors/cv32_l1_mem_monitor.sv`
- `rtl/l1_cache/work/uvm/monitors/cv32_l1_icache_monitor.sv`
- `rtl/l1_cache/work/uvm/monitors/cv32_l1_dcache_monitor.sv`
- `rtl/l1_cache/work/uvm/if/cv32_l1_mem_if.sv` if split write/read response fields are needed.
- `rtl/l1_cache/work/uvm/tb/tb_cv32_l1_uvm_top.sv` only if new `cv32_l1_mem_if` fields must be connected.

Files not to touch:
- HPDCache source files.
- CV32E40P source files.
- CVA6 I-cache source files.
- Legacy functional coverage testbenches/scripts/logs.
- Patched HPDCache filelists or patched source trees.

Makefile/script changes:
- Not required for the first Phase 2 compile if the existing `run_uvm_full_l1_basic` target remains sufficient.
- Keep `QUESTA_ENABLE_COVERAGE=0` default.
- If adding `UVM_PHASE2_TXN_CSV_FILE`, pass it as a plusarg only after the initial compile-only step is stable.

## 9. Risk Assessment

Key risks:
- Store completion rule is not explicit at the core port.
- DUT counter definitions may not exactly match UVM observed transaction counts.
- Memory write protocol separates address, data, and response phases.
- `cv32_l1_mem_if` is currently less complete than the DUT internal memory protocol.
- Questa Starter can reject SV covergroups/UCDB via the `svverification` feature.
- Internal hierarchical paths may change if the integration top changes.
- A strict scoreboard can create false failures before transaction semantics are confirmed.

Mitigation:
- Implement Phase 2 in small steps and rerun Phase 1 after each step.
- Start with compile-only transaction classes.
- Add one monitor and one analysis path at a time.
- Make ambiguous checks WARN-only until definitions are proven.
- Keep current Phase 1 pass checks as the fallback pass/fail source until the new scoreboard is stable.

## 10. Recommended Implementation Order

1. Add transaction classes under `work/uvm/txn`.
2. Update `cv32_l1_uvm_questa.f` and `cv32_l1_uvm_pkg.sv` explicitly; run compile/regression.
3. Add `sys_monitor.sys_ap` and scoreboard sys transaction sink.
4. Add `core_monitor.core_ap` and count instruction/data transactions.
5. Add `mem_monitor.mem_ap` for visible read/write request/response transactions.
6. Add scoreboard pending count checks as WARN-only first, then promote stable checks to ERROR.
7. Add perf collector transaction count CSV.
8. Rerun `make HPDCACHE_SRC_MODE=base run_uvm_full_l1_basic`.
9. Create `UVM_PHASE2_RESULT.md` only after implementation passes.

## 11. Proposed PASS Criteria for Phase 2

Phase 2 should pass only if:
- `run_uvm_full_l1_basic exit=0`.
- `[UVM][FULL_L1_BASIC][PASS]` is present.
- UVM_ERROR is 0.
- UVM_FATAL is 0.
- `QUESTA_ENABLE_COVERAGE=0` default remains active.
- HPDCache filelist is base mode.
- Transaction CSV is generated.
- No negative pending request count is observed.
- Stable transaction counts match the corresponding DUT counters.

## 12. Proposed FAIL Criteria for Phase 2

Phase 2 should fail if:
- DUT does not assert done/pass.
- Timeout occurs.
- Critical X/Z is detected on system control/status signals.
- A response appears with no pending request on a strict checked channel.
- A double response is detected on a strict checked channel.
- Required transaction CSV cannot be written.
- UVM_ERROR or UVM_FATAL is nonzero.
- Patched HPDCache is selected.
- Coverage database is enabled by default.

## 13. Deferred to Later Phases

Defer these items:
- Directed tests beyond the existing basic program.
- Real SV functional coverage and cross coverage.
- UCDB generation by default.
- Deep PLRU replacement correctness.
- Deep VBUF forwarding/writeback correctness.
- Deep MSHR/RTAB replay correctness.
- Performance latency/throughput suite.
- 3-mode UVM cache comparison.
- Random UVM sequences.

