# UVM Phase 3 Directed Test Result

Date: 2026-06-04

## Status

- Implementation status: `COMPLETE`
- Ubuntu/Questa rerun status: `PASS`
- Backend: Questa Altera Starter FPGA Edition 2025.2
- HPDCACHE_SRC_MODE: `base`
- Patched HPDCache selected: no
- Questa coverage enabled: `0`
- UCDB enabled by default: no

## Baseline Before Phase 3

Command:

```sh
FULL_L1_ROOT=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master
cd "$FULL_L1_ROOT/rtl/l1_cache/work/sim" || exit 1
mkdir -p ../../logs

make HPDCACHE_SRC_MODE=base run_uvm_full_l1_basic \
  2>&1 | tee ../../logs/QUESTA_phase1_2_baseline_before_phase3.log

grep -E "\[UVM\]\[FULL_L1_BASIC\]\[PASS\]|UVM_ERROR|UVM_FATAL|run_uvm_full_l1_basic exit=0|HPDCACHE_SRC_MODE|QUESTA_ENABLE_COVERAGE|questa_enable_coverage|scoreboard|strict_errors|warnings" \
  ../../logs/QUESTA_phase1_2_baseline_before_phase3.log || true
```

Expected:

- `HPDCACHE_SRC_MODE=base`
- `QUESTA_ENABLE_COVERAGE=0`
- `UVM_ERROR : 0`
- `UVM_FATAL : 0`
- `[UVM][FULL_L1_BASIC][PASS]`

Observed rerun:

- Log: `rtl/l1_cache/logs/QUESTA_phase1_2_baseline_before_phase3_rerun.log`
- Status: `PASS`
- `[UVM][FULL_L1_BASIC][PASS]`
- `[UVM][PHASE2][SCOREBOARD] strict_errors=0 warnings=0`
- `UVM_ERROR : 0`
- `UVM_FATAL : 0`
- `run_uvm_full_l1_basic exit=0`

## Phase 3 Directed Tests

Run individual tests:

```sh
FULL_L1_ROOT=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master
cd "$FULL_L1_ROOT/rtl/l1_cache/work/sim" || exit 1
mkdir -p ../../logs

bash -n run_uvm_questa.sh
bash -n hpdcache_src_mode.sh

make HPDCACHE_SRC_MODE=base run_uvm_p3_reset_basic \
  2>&1 | tee ../../logs/QUESTA_phase3_reset_basic.log

make HPDCACHE_SRC_MODE=base run_uvm_p3_icache_directed \
  2>&1 | tee ../../logs/QUESTA_phase3_icache_directed.log

make HPDCACHE_SRC_MODE=base run_uvm_p3_dcache_directed \
  2>&1 | tee ../../logs/QUESTA_phase3_dcache_directed.log

make HPDCACHE_SRC_MODE=base run_uvm_p3_corner_ordering \
  2>&1 | tee ../../logs/QUESTA_phase3_corner_ordering.log

make HPDCACHE_SRC_MODE=base run_uvm_p3_writeback_directed \
  2>&1 | tee ../../logs/QUESTA_phase3_writeback_directed.log
```

Run suite:

```sh
make HPDCACHE_SRC_MODE=base run_uvm_p3_directed_suite \
  2>&1 | tee ../../logs/QUESTA_phase3_directed_suite.log
```

## Expected Markers

| Test | Target | PASS marker | Status |
| --- | --- | --- | --- |
| `uvm_p3_reset_basic_test` | `run_uvm_p3_reset_basic` | `[UVM][P3_RESET_BASIC][PASS]` | `PASS` |
| `uvm_p3_icache_directed_test` | `run_uvm_p3_icache_directed` | `[UVM][P3_ICACHE_DIRECTED][PASS]` | `PASS` |
| `uvm_p3_dcache_directed_test` | `run_uvm_p3_dcache_directed` | `[UVM][P3_DCACHE_DIRECTED][PASS]` | `PASS` |
| `uvm_p3_corner_ordering_test` | `run_uvm_p3_corner_ordering` | `[UVM][P3_CORNER_ORDERING][PASS]` | `PASS` |
| `uvm_p3_writeback_directed_test` | `run_uvm_p3_writeback_directed` | `[UVM][P3_WRITEBACK_DIRECTED][PASS]` | `PASS` |

Suite rerun:

- Log: `rtl/l1_cache/logs/QUESTA_phase3_directed_suite_rerun.log`
- Status: `PASS`
- All five Phase 3 PASS markers present.
- Each target completed with exit code `0`.
- Each test reported `UVM_ERROR : 0` and `UVM_FATAL : 0`.
- Each test reported `[UVM][PHASE2][SCOREBOARD] strict_errors=0 warnings=0`.

Common observed counters in the directed tests:

- `instr_accept=18`
- `instr_rsp=18`
- `load_accept=3`
- `store_accept=5`
- `load_rsp=3`
- `ic_read_req=5`
- `ic_read_rsp=5`
- `dc_read_req=5`
- `dc_read_rsp=5`
- `dc_read_last=5`
- `dc_write_addr=2`
- `dc_write_data=2`
- `dc_write_rsp=2`
- `observed_mem_read_total=10`

## Main Checks

- Reset/basic: done/pass, no timeout, no critical X/Z.
- I-cache directed: instruction accept/response, I-cache read request/response, miss/refill counters.
- D-cache directed: load accept, store accept, load response, D-cache read request/response, D-cache miss counter.
- Corner ordering: no response without pending request, no negative pending count, no timeout, no critical X/Z.
- Writeback directed: D-cache write address/data/response and `mem_write_count` sanity.

## Baseline After Phase 3

Command:

```sh
make HPDCACHE_SRC_MODE=base run_uvm_full_l1_basic \
  2>&1 | tee ../../logs/QUESTA_phase1_2_baseline_after_phase3.log
```

Expected:

- `[UVM][FULL_L1_BASIC][PASS]`
- `UVM_ERROR : 0`
- `UVM_FATAL : 0`
- scoreboard strict errors remain zero.

Observed rerun:

- Log: `rtl/l1_cache/logs/QUESTA_phase1_2_baseline_after_phase3_rerun.log`
- Status: `PASS`
- `[UVM][FULL_L1_BASIC][PASS]`
- `[UVM][PHASE2][SCOREBOARD] strict_errors=0 warnings=0`
- `UVM_ERROR : 0`
- `UVM_FATAL : 0`
- `run_uvm_full_l1_basic exit=0`

## Hardcoded Path Check

Command:

```sh
cd /media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master

grep -RIn \
  --exclude-dir=logs \
  --exclude-dir=docs \
  --exclude-dir=msim_uvm_full_l1_basic \
  --exclude-dir=work/waves \
  -E "/media/sf_SOURCE_ENV|/media/sf_souce_env|C:/|C:\\\\" \
  rtl/l1_cache/work/uvm rtl/l1_cache/work/sim \
  > rtl/l1_cache/logs/phase3_hardcoded_path_check.txt || true
```

Notes:

- Local hardcoded path scan result file: `rtl/l1_cache/logs/phase3_hardcoded_path_check.txt`
- Result after Phase 3 fixes: clean.
- `run_uvm_questa.sh` no longer hardcodes the shared `/media` license path.
- `run_uvm_questa.sh` redirects Questa transcript output to `rtl/l1_cache/logs`.
- `run_compare_3mode_perf.sh` no longer hardcodes the sibling D-cache-only repo path.
- `hpdcache_src_mode.sh` now emits generated HPDCache filelists with paths relative to `work/sim` when `realpath` is available.
- Existing generated `hpdcache_*.f` filelists were also rewritten from old absolute prefixes to relative paths.

## Limitations

- Phase 3 reuses the known-good `load_basic_program()` stimulus from `tb_cv32_l1_uvm_top`; it does not create deep PLRU/VBUF/MSHR/RTAB stimulus.
- Writeback directed is a writeback traffic sanity test, not a full dirty-eviction proof.
- Functional coverage remains deferred to Phase 4.
- Performance comparison remains outside Phase 3.

## Next Step

Phase 3 is complete. Next step: Phase 4 functional coverage.
