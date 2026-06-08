# UVM Phase 5 Performance Collector Plan / Result

Date: 2026-06-04

## Status

Phase 5 implementation has been added to the UVM tree. The sanity, smoke,
full, and long Questa validations have been run on Ubuntu with the user's
Questa environment and all logs show `[UVM][P5_PERF][PASS]`, `UVM_ERROR=0`,
and `UVM_FATAL=0`.

## Scope

Current phase numbering:

- Phase 5: UVM Performance Collector
- Phase 6: UVM Performance Tests using the Performance / Performance test
  sheets, including P1-P29
- Phase 7: Regression / Final Report

The testplan workbook is not present inside this repo tree. Therefore this
Phase 5 implementation does not hardcode P1-P29. It prepares the collector,
CSV, and metrics needed for Phase 6 to map P1-P29 when the workbook is
available in the repo or supplied for the Phase 6 step.

## Implemented Phase 5 Pieces

- `rtl/l1_cache/work/uvm/env/cv32_l1_perf_collector.sv`
  - Measurement window start/end.
  - Counter snapshots and deltas.
  - IFETCH, LOAD, memory-read, and memory-write latency min/avg/max.
  - Raw CSV and summary CSV writing.
  - Terminal `[UVM][P5_PERF][SUMMARY]` lines.
  - `[UVM][P5_PERF][PASS]` / `[UVM][P5_PERF][FAIL]` marker.
  - Backward-compatible Phase 1/2 CSV methods.

- `rtl/l1_cache/work/uvm/tests/uvm_p5_perf_collector_test.sv`
  - Reuses the existing UVM workload path.
  - Uses the Phase 4-style benchmark image through `bench_name=uvm_p5_perf_collector`.
  - Keeps Phase 3 scoreboard checks as correctness guard.

- `rtl/l1_cache/work/sim/run_uvm_questa.sh`
  - Adds Phase 5 CSV plusargs.
  - Adds warmup/run-kind/measurement-mode plusargs.
  - Adds `ENABLE_VCD`; Phase 5 Make targets set it to `0`.

- `rtl/l1_cache/work/sim/Makefile`
  - Adds `run_uvm_p5_perf_collector_sanity`.
  - Adds `run_uvm_p5_perf_collector_smoke`.
  - Adds `run_uvm_p5_perf_collector_full`.
  - Adds `run_uvm_p5_perf_collector_long`.

## Validation Results

Observed on Ubuntu using:

- Questa root: `/home/vboxuser/altera/25.1std`
- License: `/media/sf_source_env/LR-166346_License.dat`

Sanity target:

- Command: `bash ./run_uvm_p5_codex_log.sh sanity 20000`
- Log summary: `rtl/l1_cache/logs/CODEX_P5_uvm_p5_perf_collector_sanity_ERROR_SUMMARY.log`
- Status: PASS
- `UVM_ERROR=0`, `UVM_FATAL=0`
- `measured_cycles=3421`
- `instr_count=162`, `load_count=56`, `store_count=16`
- `mem_read_count=56`, `mem_write_count=5`
- `ifetch_latency_avg=12.683230`
- `load_latency_avg=23.071429`
- `mem_read_latency_avg=42.000000`
- `mem_write_latency_avg=82.000000`

Smoke target:

- Command: `bash ./run_uvm_p5_codex_log.sh smoke 50000`
- Log summary: `rtl/l1_cache/logs/CODEX_P5_uvm_p5_perf_collector_smoke_ERROR_SUMMARY.log`
- Status: PASS
- `UVM_ERROR=0`, `UVM_FATAL=0`
- `measured_cycles=3421`
- `instr_count=162`, `load_count=56`, `store_count=16`
- `mem_read_count=56`, `mem_write_count=5`
- `ifetch_latency_avg=12.683230`
- `load_latency_avg=23.071429`
- `mem_read_latency_avg=42.000000`
- `mem_write_latency_avg=82.000000`
- Note: the current workload finishes at cycle 3425, so the smoke target has
  the same metric values as sanity even though `MAX_CYCLES=50000`.

Full target:

- Command: `bash ./run_uvm_p5_codex_log.sh full 200000`
- Log summary: `rtl/l1_cache/logs/CODEX_P5_uvm_p5_perf_collector_full_ERROR_SUMMARY.log`
- Status: PASS
- `UVM_ERROR=0`, `UVM_FATAL=0`
- `measured_cycles=3421`
- `instr_count=162`, `load_count=56`, `store_count=16`
- `mem_read_count=56`, `mem_write_count=5`
- `ifetch_latency_avg=12.683230`
- `load_latency_avg=23.071429`
- `mem_read_latency_avg=42.000000`
- `mem_write_latency_avg=82.000000`
- Note: the current workload finishes at cycle 3425, so the full target has
  the same metric values as sanity/smoke even though `MAX_CYCLES=200000`.

Long target:

- Command: `bash ./run_uvm_p5_codex_log.sh long 1000000`
- Log summary: `rtl/l1_cache/logs/CODEX_P5_uvm_p5_perf_collector_long_ERROR_SUMMARY.log`
- Status: PASS
- `UVM_ERROR=0`, `UVM_FATAL=0`
- `measured_cycles=3421`
- `instr_count=162`, `load_count=56`, `store_count=16`
- `mem_read_count=56`, `mem_write_count=5`
- `ifetch_latency_avg=12.683230`
- `load_latency_avg=23.071429`
- `mem_read_latency_avg=42.000000`
- `mem_write_latency_avg=82.000000`
- Note: the current workload finishes at cycle 3425, so the long target has
  the same metric values as sanity/smoke/full even though `MAX_CYCLES=1000000`.

## Metrics Supported

Supported and expected to be measured when the workload produces the events:

- Counter deltas:
  - `cycle_count`
  - `instr_access_count`
  - `core_load_count`
  - `core_store_count`
  - `mem_read_count`
  - `mem_write_count`
  - `icache_miss_count`
  - `icache_refill_count`
  - `dcache_miss_count`
  - `read_miss_count`
  - `write_miss_count`
- Monitor transaction deltas:
  - IFETCH accept/response
  - LOAD accept/response
  - STORE accept
  - I-cache memory read request/response
  - D-cache memory read request/last response
  - D-cache write address/data/response
- Latency:
  - IFETCH accept to response
  - LOAD accept to response
  - Memory read request to response or last response
  - Memory write address/data accepted to write response
- Derived metrics:
  - instruction/load/store per cycle
  - memory read/write per 1000 instructions
  - memory traffic per instruction
  - I-cache miss rate
  - D-cache miss rate
  - refill-per-miss sanity
  - writeback-per-store

## Metrics Intentionally Reported As N/A For Now

- Core store latency: no unambiguous core store completion event is currently
  defined.
- Hit-only versus miss/refill latency split: current collector records
  request-to-response latency but does not fake hit/miss classification.
- Dirty eviction latency, VBUF write-back latency, MSHR/RTAB latency, PLRU
  timing, and arbiter-contention latency: these need explicit high-confidence
  event definitions before they should be used as report claims.

## Output Files

- Collector default summary CSV: `rtl/l1_cache/logs/uvm_p5_perf_summary.csv`
- Collector default raw CSV: `rtl/l1_cache/logs/uvm_p5_perf_raw.csv`
- P5 Make targets write target-specific summary/raw CSV files, for example
  `uvm_p5_perf_collector_smoke_summary.csv` and
  `uvm_p5_perf_collector_smoke_raw.csv`.
- Legacy Phase 1-style perf CSV remains target-specific.
- Phase 2 transaction CSV remains target-specific.
- Questa tee logs should be saved under `rtl/l1_cache/logs`.

## Command / Log Convention

When proposing future Questa commands for this repo, use the user's Questa
environment exactly:

- Questa root: `/home/vboxuser/altera/25.1std`
- License: `/media/sf_source_env/LR-166346_License.dat`

Every command must write a tee log that can be sent back for error inspection.
Prefer existing repo targets under `rtl/l1_cache/work/sim`, with this setup
pattern:

```sh
PROJ=/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master
if [ ! -d "$PROJ" ]; then PROJ=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master; fi
cd "$PROJ/rtl/l1_cache/work/sim"
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
make HPDCACHE_SRC_MODE=base <target> MAX_CYCLES=<cycles> 2>&1 | tee ../../logs/<log_name>.log
```

For Phase 5 debug, the repo also provides a Codex-oriented log helper:

```sh
bash ./run_uvm_p5_codex_log.sh sanity 20000 2>&1 | tee ../../logs/codex_p5_sanity_driver.log
```

The helper creates:

- `rtl/l1_cache/logs/CODEX_P5_PRE_ENV.log`
- `rtl/l1_cache/logs/codex_uvm_p5_perf_collector_<kind>_cmd.log`
- `rtl/l1_cache/logs/CODEX_P5_uvm_p5_perf_collector_<kind>_ERROR_SUMMARY.log`
- `rtl/l1_cache/logs/CODEX_P5_LAST_ERROR_SUMMARY.log`

Send `CODEX_P5_LAST_ERROR_SUMMARY.log` first when asking Codex to inspect a
failure. If that file was not created, send `CODEX_P5_PRE_ENV.log`.

## PASS Criteria

Phase 5 is PASS only when:

- `[UVM][P5_PERF][PASS]` appears.
- `[UVM][P5_PERF][FAIL]` does not appear.
- `UVM_ERROR=0`.
- `UVM_FATAL=0`.
- Scoreboard strict errors are `0`.
- No timeout occurs.
- Measurement window is valid.
- Summary CSV and raw CSV are created.
- Latency min/avg/max ranges are valid.
- Request/response balance checks pass.
- Missing metrics are written as `N/A`, not invented.

## Current Limitations

- The workbook `CV32_L1Cache_Testplan_final*.xlsx` was not found inside the
  repo tree during this implementation pass.
- Phase 5 does not implement full P1-P29 performance tests. That remains Phase 6.
- Full/long targets validate the collector with larger timeouts and VCD disabled,
  but the current workload may still finish early. If the logs show too few
  measured transactions, Phase 6 should add longer workload generation rather
  than claiming long-run speedup from a short run.

## Reuse For Phase 6

Phase 6 should reuse:

- The Phase 5 collector latency/counter infrastructure.
- The raw and summary CSV schema.
- PASS/FAIL marker and request/response sanity checks.
- Scoreboard correctness guard.
- VCD-off performance target pattern.

Phase 6 should add:

- Workloads and sequences mapped to P1-P29.
- Memory-latency sweep controls.
- Cache mode comparison harnesses.
- Multi-seed aggregation.
