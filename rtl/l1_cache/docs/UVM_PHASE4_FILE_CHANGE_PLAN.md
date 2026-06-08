# UVM Phase 4 File Change Plan

Date: 2026-06-04

This is a planning document only. No implementation is performed in Phase 4 planning.

## Proposed Files To Create

| File | Purpose | Risk |
| --- | --- | --- |
| `rtl/l1_cache/work/uvm/phase4_coverage/cv32_l1_phase4_cov_types.sv` | Define coverage IDs, group IDs, result enum, and helper formatting functions | Low |
| `rtl/l1_cache/work/uvm/phase4_coverage/cv32_l1_phase4_cov_collector.sv` | Counter-based functional coverage collector using monitor transactions | Medium |
| `rtl/l1_cache/work/uvm/phase4_coverage/cv32_l1_phase4_cov_reporter.sv` | Emit CSV and Markdown/terminal coverage summary | Low |
| `rtl/l1_cache/work/uvm/tests/uvm_p4_functional_coverage_test.sv` | Reuse Phase 3 directed flow and invoke coverage report/checks | Medium |
| `rtl/l1_cache/logs/uvm_phase4_functional_coverage.csv` | Proposed runtime CSV output | Low |
| `rtl/l1_cache/logs/QUESTA_phase4_functional_coverage.log` | Proposed run log | Low |

Optional only:

| File | Purpose | Risk |
| --- | --- | --- |
| `rtl/l1_cache/work/uvm/phase4_coverage/cv32_l1_phase4_sv_covergroups.sv` | Optional SV covergroups guarded by `UVM_USE_SV_COVERGROUPS` and `QUESTA_ENABLE_COVERAGE=1` | Medium-high because of simulator/license behavior |

## Proposed Files To Modify

| File | Proposed change | Why | Phase 1/2/3 impact | Phase 5/6 conflict risk |
| --- | --- | --- | --- | --- |
| `rtl/l1_cache/work/uvm/pkg/cv32_l1_uvm_pkg.sv` | Add explicit includes for Phase 4 types, collector, reporter, and test | Needed for compile order; no wildcard | Low if appended after existing Phase 3 includes |
| `rtl/l1_cache/work/sim/cv32_l1_uvm_questa.f` | Add `+incdir+../uvm/phase4_coverage` | Needed for package includes | Low |
| `rtl/l1_cache/work/uvm/env/cv32_l1_env.sv` | Instantiate Phase 4 coverage collector and connect sys/core/mem/event analysis ports | Needed for transaction-driven coverage | Medium; avoid changing scoreboard/perf connections |
| `rtl/l1_cache/work/uvm/env/cv32_l1_coverage.sv` | Keep as optional SV covergroup shell, or bridge it to the new collector only under a guard | Avoid breaking default coverage-off flow | Medium if edited; recommended minimal/no change first |
| `rtl/l1_cache/work/sim/run_uvm_questa.sh` | Add optional Phase 4 CSV path plusarg/env only if needed | Needed for configurable output path | Low if defaults preserve existing behavior |
| `rtl/l1_cache/work/sim/Makefile` | Add `run_uvm_p4_functional_coverage` and `run_uvm_p4_coverage_suite` targets | Gives repeatable user command | Low if existing targets unchanged |

## Proposed Include Order

Within `cv32_l1_uvm_pkg.sv`, proposed Phase 4 includes should be after transaction types and before tests:

```systemverilog
`include "cv32_l1_phase4_cov_types.sv"
`include "cv32_l1_phase4_cov_reporter.sv"
`include "cv32_l1_phase4_cov_collector.sv"
...
`include "uvm_p4_functional_coverage_test.sv"
```

If optional covergroups are implemented later:

```systemverilog
`ifdef UVM_USE_SV_COVERGROUPS
  `include "cv32_l1_phase4_sv_covergroups.sv"
`endif
```

## Proposed Env Connection Plan

Add coverage collector connections parallel to scoreboard/perf collector:

```text
sys_monitor.sys_ap        -> phase4_cov.sys_export
core_monitor.core_ap      -> phase4_cov.core_export
mem_monitor.mem_ap        -> phase4_cov.mem_export
icache_monitor.event_ap   -> phase4_cov.event_export
dcache_monitor.event_ap   -> phase4_cov.event_export
```

Do not remove or reroute existing Phase 2 connections.

## Proposed Make Targets

```make
run_uvm_p4_functional_coverage:
	$(call RUN_LOGGED,HPDCACHE_SRC_MODE=base MAX_CYCLES=$(MAX_CYCLES) WRITE_RESULT_DOCS=0 UVM_TESTNAME=uvm_p4_functional_coverage_test UVM_LOG_BASENAME=uvm_p4_functional_coverage BENCH_NAME=uvm_p4_functional_coverage PASS_MARKER=[UVM][P4_FUNC_COV][PASS] FAIL_MARKER=[UVM][P4_FUNC_COV][FAIL] PHASE4_COV_CSV=$(LOG_DIR)/uvm_phase4_functional_coverage.csv bash ./run_uvm_questa.sh)

run_uvm_p4_coverage_suite: run_uvm_p3_directed_suite run_uvm_p4_functional_coverage
```

The final implementation can choose whether the P4 target runs one umbrella test or invokes the five P3 tests and merges CSV rows.

## Proposed User Commands

Command/log convention:

- Use Questa root `/home/vboxuser/altera/25.1std`.
- Use license `/media/sf_source_env/LR-166346_License.dat`.
- Prefer the existing Make targets, which call `run_uvm_questa.sh`, after
  setting the environment below.
- Keep every proposed run command logged with `tee` under `../../logs`.

Default counter-based coverage:

```sh
cd /media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
bash -n run_uvm_questa.sh 2>&1 | tee ../../logs/QUESTA_phase4_runner_syntax_check.log
make HPDCACHE_SRC_MODE=base run_uvm_p4_functional_coverage MAX_CYCLES=100000 \
  2>&1 | tee ../../logs/QUESTA_phase4_functional_coverage.log
```

Suite:

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

## Implementation Order

1. Re-run Phase 3 baseline and confirm PASS.
2. Add Phase 4 counter coverage type/report files.
3. Add collector with analysis imps for sys/core/mem/event.
4. Connect collector in env without changing scoreboard/perf behavior.
5. Add one P4 coverage test that reuses Phase 3 stimulus/check flow.
6. Add CSV/terminal coverage report.
7. Add Make targets.
8. Re-run Phase 1/2 baseline and Phase 3 suite.
9. Only after counter coverage is stable, evaluate optional SV covergroup mode.

## What Not To Change

- Do not edit HPDCache RTL.
- Do not edit CV32E40P RTL.
- Do not edit CVA6 I-cache RTL.
- Do not enable UCDB by default.
- Do not make `QUESTA_ENABLE_COVERAGE=1` the default.
- Do not use wildcard `*.sv` in filelists.
- Do not hardcode absolute Windows or `/media` paths in source/script/filelist.
- Do not mark deep VBUF/PLRU/MSHR/RTAB coverage PASS without real observed events.
