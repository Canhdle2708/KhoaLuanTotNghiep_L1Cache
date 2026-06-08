# Questa UVM Master Plan

Date: 2026-06-03

Project: CV32E40P + Full L1 Cache, using CVA6 I-Cache plus HPDCache base D-Cache.

## Non-Negotiable Constraints

- Simulator for this flow: Questa 2025.2 Starter.
- Future Ubuntu command suggestions must use the user's Questa environment:
  - Questa root: `/home/vboxuser/altera/25.1std`
  - License: `/media/sf_source_env/LR-166346_License.dat`
- Prefer the existing repo runner `rtl/l1_cache/work/sim/run_uvm_questa.sh`
  through Make targets after exporting the license and sourcing
  `/home/vboxuser/altera/25.1std/questa_fse/questasim.sh`.
- Do not switch commands to another Questa path such as `/home/admin/altera`
  unless the reason is checked and documented.
- Every proposed run command must write a user tee log, for example
  `2>&1 | tee ../../logs/<log_name>.log`.
- UVM flow must not use Xcelium or Verilator.
- HPDCache source mode must be `HPDCACHE_SRC_MODE=base`.
- Patched HPDCache must not be used. The UVM runner fails if patched mode or patched filelist content is detected.
- Original RTL is not modified for Phase 0/1.
- New UVM code is isolated under `rtl/l1_cache/work/uvm`.
- Logs are written under `rtl/l1_cache/logs`.
- Reports are written under `rtl/l1_cache/docs`.

## Command/Log Convention For Future Suggestions

When proposing a command for the user to run on Ubuntu, use this environment
prefix and keep the final run command logged with `tee`:

```sh
cd /media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
make <target> ... 2>&1 | tee ../../logs/<log_name>.log
```

The repo has a UVM/Questa runner at `rtl/l1_cache/work/sim/run_uvm_questa.sh`.
It is not a standalone environment setup script; it detects Questa from the
current environment or falls back to `$HOME/altera/25.1std/questa_fse`, and it
only uses its local license fallback when `LM_LICENSE_FILE` is not already set.
Therefore future commands should still set the user's license and source the
user's Questa setup before invoking the Make target or runner.

## Existing Reuse Points

| Reused Item | Path | Use In UVM Flow |
|---|---|---|
| HPDCache source selector | `rtl/l1_cache/work/sim/hpdcache_src_mode.sh` | Regenerate base HPDCache filelist. |
| HPDCache base filelist | `rtl/l1_cache/work/sim/hpdcache_base_cv32.f` | Compile HPDCache base RTL. |
| CVA6 I-Cache filelist | `rtl/l1_cache/work/sim/cva6_icache_full_for_cv32.f` | Compile I-Cache packages/RTL. |
| Full L1 basic filelist | `rtl/l1_cache/work/sim/cv32e40p_full_l1_basic.f` | Compile CV32, adapters, arbiter, Full L1 top. |
| Basic program init | `rtl/l1_cache/work/tb/tb_cv32e40p_full_l1_basic.sv` | Reimplemented in UVM top as the same memory image. |
| Full L1 top | `rtl/l1_cache/work/rtl/cv32e40p_full_l1_cache_top.sv` | DUT instance in UVM top. |

## Phase 0: Bring-Up Infrastructure

Deliverables:
- UVM interfaces for system, core, memory, cache events, and counters.
- UVM package.
- UVM environment.
- Config object.
- System/core/cache/memory monitor skeletons.
- Scoreboard skeleton with real Phase 1 pass/fail condition.
- Coverage skeleton matching the current testplan coverpoint names.
- Performance collector skeleton with CSV output.
- Explicit Questa UVM filelist.
- Questa UVM runner script.
- Makefile target `run_uvm_full_l1_basic`.

Exit criteria:
- UVM tree is created without touching legacy testbench files.
- UVM filelist has explicit file entries.
- Runner checks Questa tools and blocks patched HPDCache.

## Phase 1: UVM Full L1 Basic Smoke

Test:

`uvm_full_l1_basic_test`

Behavior:
- Instantiate the existing Full L1 top.
- Load the same basic program image as `tb_cv32e40p_full_l1_basic.sv`.
- Drive reset.
- Enable fetch.
- Wait for `done` and `pass`, or timeout.
- Check no critical X/Z on `rst_n`, `fetch_enable`, `done`, `pass`.
- Check basic evidence counters are nonzero:
  - `instr_access_count`
  - `icache_miss_count`
  - `icache_refill_count`
  - `core_load_count`
  - `core_store_count`

PASS marker:

`[UVM][FULL_L1_BASIC][PASS]`

Expected command:

```sh
cd /media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
make HPDCACHE_SRC_MODE=base run_uvm_full_l1_basic \
  2>&1 | tee ../../logs/QUESTA_uvm_full_l1_basic_user.log
```

## Later Phase Placeholders

Phase 2:
- Add real directed functional tests for reset, I-Cache, D-Cache, PLRU, writeback, VBUF, arbiter contention, and ordering.
- Convert skeleton monitor hooks into real transaction streams.

Phase 3:
- Implement real functional coverage sampling for current coverpoints and crosses.
- Correlate coverage items to the full testplan.

Phase 4:
- Add UVM performance tests for latency, throughput, memory wait sensitivity, back-to-back request efficiency, and long-run stability.

Phase 5:
- Add 3-mode performance comparison wrappers: No Cache, D-Cache only, Full L1.

Phase 6:
- Add regression report generation and trend comparison.
