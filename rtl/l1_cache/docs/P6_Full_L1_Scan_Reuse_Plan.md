# P6 Full L1 Scan And Reuse Plan

Phase: P6 / Phase 0 scan only

Date: 2026-05-28

No build, simulator, Verilator, bash, or make command was run in this phase.
This report is based only on local Windows file inspection.

## Folder Scope

| Mode | Windows path | Ubuntu candidate path | Phase 0 action |
|---|---|---|---|
| FULL_L1 | `C:\CanhDac\SOURCE_ENV\cv32_full_l1_cache\cv32e40p-master` | `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master` or `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master` | Read and report only |
| DCACHE_ONLY | `C:\CanhDac\SOURCE_ENV\cv32e40p-master` | `/media/sf_SOURCE_ENV/cv32e40p-master` | Read/reference only |
| NO_CACHE | `C:\CanhDac\SOURCE_ENV\cv32e40p-non-cache` | TBD by user environment | Read/reference only |

Rules for later phases:

- Do not merge these three folders.
- Do not modify the DCACHE_ONLY folder unless explicitly approved.
- Do not modify the NO_CACHE folder unless explicitly approved.
- Full L1 runs should use `HPDCACHE_SRC_MODE=base`.
- Do not modify HPDCache base/reference source.
- Do not fake PASS, counters, or coverage.

## Full L1 Existing Files

### Main Full L1 RTL

| Role | File |
|---|---|
| Full L1 top | `rtl/l1_cache/work/rtl/cv32e40p_full_l1_cache_top.sv` |
| CV32 instruction to CVA6 I-Cache adapter | `rtl/l1_cache/work/rtl/cv32_instr_to_cva6_icache_adapter.sv` |
| Identity translation for I-Cache | `rtl/l1_cache/work/rtl/cva6_icache_identity_translation.sv` |
| CVA6 I-Cache memory adapter | `rtl/l1_cache/work/rtl/cva6_icache_mem_adapter.sv` |
| CV32 data to HPDCache adapter | `rtl/l1_cache/work/rtl/cv32_data_to_hpdcache_adapter.sv` |
| HPDCache CV32 wrapper | `rtl/l1_cache/work/rtl/hpdcache_cv32_wrapper.sv` |
| Shared I/D memory arbiter/model | `rtl/l1_cache/work/rtl/l1_mem_arbiter.sv` |

The Full L1 top integrates:

```text
CV32E40P instruction port
  -> cv32_instr_to_cva6_icache_adapter
  -> real CVA6 I-Cache
  -> cva6_icache_mem_adapter
  -> l1_mem_arbiter/shared memory

CV32E40P data port
  -> cv32_data_to_hpdcache_adapter
  -> hpdcache_cv32_wrapper / HPDCache
  -> l1_mem_arbiter/shared memory
```

### CVA6 I-Cache Source Bundle

| Role | File/path |
|---|---|
| I-Cache bundle root | `rtl/l1_cache/cva6_icache_full` |
| I-Cache DUT | `rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv` |
| I-Cache package/filelist copy for CV32 flow | `rtl/l1_cache/work/sim/cva6_icache_full_for_cv32.f` |
| I-Cache extraction notes | `rtl/l1_cache/cva6_icache_full/docs/00_cva6_icache_extract_report.md` |
| I-Cache ports report | `rtl/l1_cache/cva6_icache_full/docs/01_cva6_icache_ports.md` |
| I-Cache dependency report | `rtl/l1_cache/cva6_icache_full/docs/02_cva6_icache_dependencies.md` |
| I-Cache integration notes | `rtl/l1_cache/cva6_icache_full/docs/03_cva6_icache_integration_notes.md` |

### Full L1 Testbenches

| Role | File |
|---|---|
| Basic smoke TB | `rtl/l1_cache/work/tb/tb_cv32e40p_full_l1_basic.sv` |
| Basic debug TB | `rtl/l1_cache/work/tb/tb_cv32e40p_full_l1_basic_debug.sv` |
| Random smoke TB | `rtl/l1_cache/work/tb/tb_cv32e40p_full_l1_random.sv` |

Observed counters/signals already present in `cv32e40p_full_l1_cache_top.sv`:

- `cycle_count`
- `instr_access_count`
- `icache_miss_count`
- `icache_refill_count`
- `core_load_count`
- `core_store_count`
- `mem_read_count`
- `mem_write_count`
- `read_miss_count`
- `write_miss_count`
- `dcache_miss_count`
- `arb_icache_read_count`
- `arb_dcache_read_count`
- `arb_dcache_write_count`
- `done`
- `pass`

These are useful starting points for I-Cache coverage and Full L1 performance.

### Full L1 Simulation Flow

| Role | File/target |
|---|---|
| Makefile | `rtl/l1_cache/work/sim/Makefile` |
| Basic full L1 runner | `rtl/l1_cache/work/sim/run_full_l1_basic.sh` |
| Random full L1 runner | `rtl/l1_cache/work/sim/run_full_l1_random.sh` |
| Basic full L1 filelist | `rtl/l1_cache/work/sim/cv32e40p_full_l1_basic.f` |
| Random full L1 filelist | `rtl/l1_cache/work/sim/cv32e40p_full_l1_random.f` |
| I-Cache filelist for CV32 | `rtl/l1_cache/work/sim/cva6_icache_full_for_cv32.f` |
| HPDCache source selection helper | `rtl/l1_cache/work/sim/hpdcache_src_mode.sh` |

Existing Makefile targets:

- `make HPDCACHE_SRC_MODE=base run_full_l1_basic`
- `make HPDCACHE_SRC_MODE=base run_full_l1_random SEEDS="1 2 3"`
- Existing D-Cache-only smoke targets also remain in this folder, but they are not the current focus.

### Full L1 Existing Logs

Existing logs indicate previous smoke PASS, but Phase 1 must reproduce them in the user's Ubuntu environment:

- `rtl/l1_cache/logs/10_full_l1_basic.log`
- `rtl/l1_cache/logs/11_full_l1_random_seed_1.log`
- `rtl/l1_cache/logs/11_full_l1_random_seed_2.log`
- `rtl/l1_cache/logs/11_full_l1_random_seed_3.log`

Previous observed markers:

- Basic: `full L1 basic done cycles=356 instr=18 ic_miss=5 ic_refill=5 loads=3 stores=5 mem_reads=10 mem_writes=2 dcache_miss=9`
- Random seed 1: `cycles=550 instr=60 ic_miss=15 ic_refill=15 loads=12 stores=17 mem_reads=28 mem_writes=6 dcache_miss=26`
- Random seed 2: `cycles=530 instr=60 ic_miss=15 ic_refill=15 loads=12 stores=17 mem_reads=27 mem_writes=4 dcache_miss=24`
- Random seed 3: `cycles=533 instr=60 ic_miss=15 ic_refill=15 loads=12 stores=17 mem_reads=27 mem_writes=4 dcache_miss=24`

These are historical evidence only. They are not a substitute for Phase 1 reproduction.

## D-Cache Only Reuse Candidates

Source folder:

`C:\CanhDac\SOURCE_ENV\cv32e40p-master`

The following files are good reuse candidates. They should be copied/adapted into the Full L1 folder in later phases instead of modifying the DCACHE_ONLY folder.

### Functional Coverage Framework

| Reuse item | Source file | Intended Full L1 adaptation |
|---|---|---|
| Coverage status/package style | `rtl/l1_cache/work/tb/dcache_cov_pkg.sv` | Create `l1_cov_pkg.sv` or `l1_icache_cov_pkg.sv` |
| Event monitor structure | `rtl/l1_cache/work/tb/dcache_event_monitor.sv` | Create `l1_event_monitor.sv`, add I-Cache and arbiter events |
| Check scoreboard/CSV writer | `rtl/l1_cache/work/tb/dcache_check_scoreboard.sv` | Create `l1_check_scoreboard.sv` and/or `l1_icache_check_scoreboard.sv` |
| D-Cache coverage TB | `rtl/l1_cache/work/tb/tb_cv32e40p_dcache_func_cov.sv` | Use as pattern for Full L1 coverage TB only |
| D-Cache coverage filelist | `rtl/l1_cache/work/sim/cv32e40p_dcache_func_cov_verilator.f` | Create Full L1 coverage filelists |
| Coverage suite runner | `rtl/l1_cache/work/sim/run_dcache_cov_suite.sh` | Create `run_l1_icache_cov_suite.sh` and `run_full_l1_cov_suite.sh` |
| Makefile targets | `rtl/l1_cache/work/sim/Makefile` | Copy target style, not the file itself |

The DCACHE_ONLY coverage flow currently has a useful terminal style:

```text
[COV_TABLE]
CheckID,Group,Status
...
[COV_SUMMARY] total=... pass=... fail=... not_run=... instrumentation_missing=... excluded=...
[LOG] ...
[CSV] ...
```

It also has stable CSV format:

```text
check_id,group,bench_name,status,hit_count,pass,fail_reason,required_events,observed_events
```

Current DCACHE_ONLY coverage result file shows:

```text
[COV_SUMMARY] total=50 pass=50 fail=0 not_run=0 instrumentation_missing=0 excluded=11
```

For Full L1, this status must not be copied as evidence. The benchmarks and checkers must run under the Full L1 instruction path.

### D-Cache Coverage Benchmarks Worth Reusing

From `P5_DCache_Functional_Coverage_Closure.md`:

- `reset_idle`
- `basic_load_store`
- `repeated_load`
- `store_hit_dirty`
- `store_miss_clean_victim`
- `dirty_eviction_vbuf`
- `vbuf_forward_load`
- `vbuf_full_backpressure`
- `load_miss_variants`
- `store_byte_half_corner`
- `store_conflict_dirty`
- `plru_update_after_hit`
- `multi_dirty_eviction`
- `vbuf_ordering`
- `memory_backpressure_latency`
- `reset_during_miss`
- `reset_during_vbuf`
- `uncached_access`
- `unaligned_access`

These can be adapted for Full L1 Group A/C/D/E/F/H. Group B and G require new Full L1/I-Cache-specific checks.

### Performance Framework

| Reuse item | Source file | Intended Full L1 adaptation |
|---|---|---|
| Benchmark generator | `rtl/l1_cache/work/tb/perf_benchmark_programs.svh` | Reuse/adapt for Full L1 perf TB |
| Perf monitor | `rtl/l1_cache/work/tb/perf_monitor.sv` | Reuse/adapt with I-Cache counters |
| Perf memory model | `rtl/l1_cache/work/tb/perf_memory_model.sv` | Reuse concepts if Full L1 TB needs standalone memory model |
| D-Cache perf TB | `rtl/l1_cache/work/tb/tb_cv32e40p_perf_dcache.sv` | Pattern for FULL_L1 perf TB |
| No-cache perf TB | `rtl/l1_cache/work/tb/tb_cv32e40p_perf_no_cache.sv` | Pattern/reference only |
| Verilator perf runner | `rtl/l1_cache/work/sim/run_perf_verilator.sh` | Pattern for `run_full_l1_perf_verilator.sh` |
| Verilator perf sweep | `rtl/l1_cache/work/sim/run_perf_verilator_sweep.sh` | Pattern for 3-mode compare script |
| Perf filelists | `rtl/l1_cache/work/sim/cv32e40p_perf_*_verilator.f` | Pattern for Full L1 perf filelist |

Useful benchmark names already present in DCACHE_ONLY:

- `basic_load_store`
- `repeated_load`
- `array_sum`
- `store_then_load_many`
- `stride_access`

Phase 4 should add or adapt:

- `tight_loop_fetch`
- `mixed_i_d_locality`

### DCACHE_ONLY Files Not To Touch

Do not edit these in Phase 0 or later unless explicitly approved:

- `C:\CanhDac\SOURCE_ENV\cv32e40p-master\rtl\l1_cache\work\tb\*.sv`
- `C:\CanhDac\SOURCE_ENV\cv32e40p-master\rtl\l1_cache\work\sim\*.sh`
- `C:\CanhDac\SOURCE_ENV\cv32e40p-master\rtl\l1_cache\work\sim\Makefile`
- `C:\CanhDac\SOURCE_ENV\cv32e40p-master\rtl\l1_cache\logs\*.csv`
- `C:\CanhDac\SOURCE_ENV\cv32e40p-master\rtl\l1_cache\logs\*.log`

Read/reference/copy-adapt only.

## No-Cache Folder Notes

Source folder:

`C:\CanhDac\SOURCE_ENV\cv32e40p-non-cache`

Observed files include the older baseline/no-cache smoke flow:

- `rtl/l1_cache/work/tb/tb_cv32e40p_baseline_original.sv`
- `rtl/l1_cache/work/sim/cv32e40p_baseline.f`
- `rtl/l1_cache/work/sim/run_baseline_original.sh`
- `rtl/l1_cache/work/sim/Makefile`

This folder does not contain the newer DCACHE_ONLY performance/coverage framework found in `C:\CanhDac\SOURCE_ENV\cv32e40p-master`.

For Phase 4, prefer one of these approaches:

1. Use the known-good `NO_CACHE` Verilator perf target in the DCACHE_ONLY folder as the no-cache mode reference, while keeping the dedicated `cv32e40p-non-cache` folder untouched.
2. If the user requires using the separate `cv32e40p-non-cache` folder, copy-adapt only the performance benchmark infrastructure into that folder after explicit approval.

## Full L1 Testplan Status

Full L1 testplan:

`rtl/l1_cache/docs/TESTPLAN_Full_L1_CV32_ICache_DCache.md`

It currently uses `FL1_*` check IDs, not the A/B/C/D/E/F/G/H CheckID scheme from the DCACHE_ONLY plan.

Existing Full L1 testplan IDs:

- `FL1_BASIC_001`
- `FL1_IC_001`
- `FL1_IC_002`
- `FL1_IC_003`
- `FL1_IC_004`
- `FL1_DC_001`
- `FL1_DC_002`
- `FL1_DC_003`
- `FL1_WB_001`
- `FL1_VBUF_001`
- `FL1_ARB_001`
- `FL1_ARB_002`
- `FL1_RST_001`
- `FL1_RANDOM_001`
- `FL1_PERF_001`

For Phase 2 Group B, recommended mapping is:

| Proposed Group B CheckID | Based on testplan ID | Scenario |
|---|---|---|
| B_IC_01 | `FL1_IC_001` | I-Cache receives/fires first fetch and observes miss/refill |
| B_IC_02 | `FL1_IC_002` | Sequential fetch returns valid instruction responses after refill |
| B_IC_03 | `FL1_IC_003` | Identity translation has no exception and physical address follows virtual fetch |
| B_IC_04 | `FL1_IC_004` | Flush/fence.i readiness if stimulus exists; otherwise NOT_RUN until implemented |
| B_IC_05 | `FL1_BASIC_001` | Program reaches DONE through I-Cache fetch path |
| B_IC_06 | `FL1_RANDOM_001` | Random smoke fetch path has I-Cache miss/refill and no timeout |

These should be documented as proposed Full L1 Group B IDs unless the user later supplies a separate A-H testplan for Full L1.

## Files To Create Or Modify In Later Phases

Do not create these until their phase is approved.

### Phase 1

Potential fix files only if smoke fails due to path issues:

- `rtl/l1_cache/work/sim/cva6_icache_full_for_cv32.f`
- `rtl/l1_cache/work/sim/run_full_l1_basic.sh`
- `rtl/l1_cache/work/sim/run_full_l1_random.sh`
- `rtl/l1_cache/work/sim/Makefile`
- New report: `rtl/l1_cache/docs/P6_Full_L1_Reproduce_Smoke_Result.md`

### Phase 2

Likely new files:

- `rtl/l1_cache/work/tb/l1_icache_cov_pkg.sv`
- `rtl/l1_cache/work/tb/l1_icache_event_monitor.sv`
- `rtl/l1_cache/work/tb/l1_icache_check_scoreboard.sv`
- `rtl/l1_cache/work/tb/tb_cv32e40p_l1_icache_func_cov.sv`
- `rtl/l1_cache/work/sim/cv32e40p_l1_icache_func_cov_verilator.f`
- `rtl/l1_cache/work/sim/run_l1_icache_cov_suite.sh`
- Makefile target: `verilator_l1_icache_func_cov_suite`
- New report: `rtl/l1_cache/docs/P7_ICache_Functional_Coverage_Result.md`

### Phase 3

Likely new files:

- `rtl/l1_cache/work/tb/full_l1_cov_pkg.sv`
- `rtl/l1_cache/work/tb/full_l1_event_monitor.sv`
- `rtl/l1_cache/work/tb/full_l1_check_scoreboard.sv`
- `rtl/l1_cache/work/tb/tb_cv32e40p_full_l1_func_cov.sv`
- `rtl/l1_cache/work/sim/cv32e40p_full_l1_func_cov_verilator.f`
- `rtl/l1_cache/work/sim/run_full_l1_cov_suite.sh`
- Makefile target: `verilator_full_l1_func_cov_suite`
- New report: `rtl/l1_cache/docs/P8_Full_L1_Functional_Coverage_Result.md`

### Phase 4

Likely new/adapted files:

- `rtl/l1_cache/work/tb/full_l1_perf_benchmark_programs.svh`
- `rtl/l1_cache/work/tb/tb_cv32e40p_perf_full_l1.sv`
- `rtl/l1_cache/work/sim/cv32e40p_perf_full_l1_verilator.f`
- `rtl/l1_cache/work/sim/run_full_l1_perf_verilator.sh`
- `rtl/l1_cache/work/sim/run_compare_3mode_perf.sh`
- Makefile target: `verilator_full_l1_perf`
- New report: `rtl/l1_cache/docs/P9_Performance_Compare_3Mode_Result.md`

## Files Not To Modify

Do not modify:

- HPDCache base/reference under `rtl/l1_cache/hpdcache/cv-hpdcache`
- CV32E40P upstream RTL under `rtl/*.sv` unless explicitly approved
- DCACHE_ONLY folder contents
- NO_CACHE folder contents
- Existing Full L1 smoke RTL/testbench unless Phase 1 reproduction identifies a real blocker

Avoid using:

- `rtl/l1_cache/work/hpdcache_patched`
- generated `obj_dir*`
- generated `msim*`
- old stale logs as proof of new PASS

## Hardcoded Path Risks

Known risks found during scan:

- `rtl/l1_cache/work/sim/cva6_icache_full_for_cv32.f` contains absolute Ubuntu paths under `/media/sf_source_env/cv32_full_l1_cache/...`.
- Generated HPDCache filelists such as `hpdcache_base_cv32.f` are generated with absolute paths.
- The user environment may mount the shared folder as either `/media/sf_SOURCE_ENV` or `/media/sf_source_env`.
- `hpdcache_src_mode.sh` has an internal default of `patched`, while the Full L1 Makefile sets `HPDCACHE_SRC_MODE ?= base`. Always run Phase 1 with explicit `HPDCACHE_SRC_MODE=base`.
- Some docs are stale: the handoff note still says I-Cache is not integrated, while Full L1 files/logs show I-Cache integration exists. Use current RTL/logs over the stale note.
- This folder is not a git repository in the scanned Windows location, so changes need extra care and explicit file-level tracking.

If Phase 1 fails because `cva6_icache_full_for_cv32.f` points at the wrong mount path, the preferred fix is to regenerate the filelist from `ROOT_WORKSPACE` or convert it to relative paths. Do not modify functional RTL for a path-only failure.

## Phase Plan And Gates

### Phase 1 - Reproduce Full L1 Smoke

Goal:

- Re-run basic and random smoke in the user's Ubuntu environment.
- Confirm `HPDCACHE_SRC_MODE=base`.

Gate:

- If basic or random smoke fails, stop and debug only path/script/filelist issues first.
- If smoke passes, create `P6_Full_L1_Reproduce_Smoke_Result.md`, then ask for user confirmation before Phase 2.

### Phase 2 - I-Cache Functional Coverage / Group B

Goal:

- Add a focused I-Cache functional coverage suite in the Full L1 folder.
- Terminal output must match the short `[COV_TABLE]` style.

Gate:

- If compile/run fails, debug only the focused I-Cache suite.
- Do not proceed to Full L1 A-H coverage until user confirms.

### Phase 3 - Full L1 Functional Coverage A/B/C/D/E/F/G/H

Goal:

- Reuse/adapt DCACHE_ONLY A/C/D/E/F/H logic under the Full L1 instruction path.
- Add Group B and Group G.

Gate:

- Do not copy PASS statuses from DCACHE_ONLY.
- PASS only with Full L1 run evidence.

### Phase 4 - Performance Compare 3 Modes

Goal:

- Compare NO_CACHE, DCACHE_ONLY, and FULL_L1.
- Use compatible benchmark bodies and CSV schema.

Gate:

- Do not claim speedup unless measured from pasted user logs/CSV.
- Report cases where FULL_L1 is not faster.

## Phase 1 User Commands

Use these commands in Ubuntu. They first locate the Full L1 folder using either shared-folder casing, then run the two smoke targets.

```sh
FULL_L1_ROOT=""
for p in \
  /media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master \
  /media/sf_source_env/cv32_full_l1_cache/cv32e40p-master
do
  if [ -d "$p/rtl/l1_cache/work/sim" ]; then
    FULL_L1_ROOT="$p"
    break
  fi
done

if [ -z "$FULL_L1_ROOT" ]; then
  echo "[P6][FAIL] Cannot find Full L1 cv32e40p-master under /media/sf_SOURCE_ENV or /media/sf_source_env"
  exit 1
fi

echo "[P6] FULL_L1_ROOT=$FULL_L1_ROOT"
cd "$FULL_L1_ROOT/rtl/l1_cache/work/sim" || exit 1

make HPDCACHE_SRC_MODE=base run_full_l1_basic 2>&1 | tee ../../../logs/P6_run_full_l1_basic_user.log
make HPDCACHE_SRC_MODE=base run_full_l1_random SEEDS="1 2 3" 2>&1 | tee ../../../logs/P6_run_full_l1_random_user.log
```

After running, paste the terminal output or at least these two logs:

- `rtl/l1_cache/logs/P6_run_full_l1_basic_user.log`
- `rtl/l1_cache/logs/P6_run_full_l1_random_user.log`

