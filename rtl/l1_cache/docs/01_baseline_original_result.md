# Phase 1 - Baseline Original / No-Cache Simulation Result

Date: 2026-05-26

## Goal

Confirm that CV32E40P can run a minimal no-cache baseline before adding
HPDCache to the data path.

This phase does not modify `rtl/l1_cache/original` and does not modify CV32E40P
production RTL.

## Ubuntu Workspace

Detected workspace:

```text
/media/sf_source_env/cv32/work/cv32e40p-master
```

All commands were run from the workspace through the Ubuntu shared-folder path.

## Testbench

Baseline testbench:

```text
rtl/l1_cache/work/tb/tb_cv32e40p_baseline_original.sv
```

The testbench instantiates:

- `cv32e40p_top`
- Direct one-cycle instruction memory
- Direct one-cycle data memory

The hardcoded RV32I program performs:

1. Store `0x55` to `0x0000_0100`
2. Load back from `0x0000_0100`
3. Add one
4. Store `0x56` to `0x0000_0104`
5. Store to memory-mapped DONE address `0x2000_0004`

Pass condition:

- `mem[0x100] == 32'h0000_0055`
- `mem[0x104] == 32'h0000_0056`
- DONE store observed

## Compile/Run Flow

Simulator backend used in Ubuntu:

```text
Verilator
```

The previous baseline script expected Questa/ModelSim (`vlib/vlog/vsim`), but
those tools were not present in the Ubuntu PATH. The script was updated to use
Questa when available and otherwise fall back to Verilator.

Main command:

```bash
make -C rtl/l1_cache/work/sim run_baseline
```

Log:

```text
rtl/l1_cache/logs/01_baseline_original.log
```

Waveform:

```text
rtl/l1_cache/work/waves/01_baseline_original.vcd
```

## Result

Pass.

Important log lines:

```text
[MAKE_STATUS] 0
[PHASE1][PASS] baseline no-cache load/store completed at cycle 15
```

Waveform was generated:

```text
rtl/l1_cache/work/waves/01_baseline_original.vcd
```

## Instruction Path Behavior

The baseline instruction path is an ideal one-cycle memory model:

- `instr_gnt = instr_req`
- `instr_rvalid` returns one cycle after `instr_req`
- `instr_addr` starts from `boot_addr_i = 32'h0000_0000`
- `instr_rdata` is read from the testbench program memory

The core fetched the hardcoded program and reached the DONE store.

## Data Path Behavior

The baseline data path is direct memory, no cache:

- `data_gnt = data_req`
- `data_rvalid` returns one cycle after `data_req`
- `data_we = 1` performs a byte-enable-aware store
- `data_we = 0` returns a word from testbench memory

Observed behavior:

- Store to `0x0000_0100` completed
- Load from `0x0000_0100` returned `0x0000_0055`
- Store to `0x0000_0104` completed with `0x0000_0056`
- DONE store to `0x2000_0004` ended the run

## Notes From Debug

Issues encountered and fixed:

- Baseline script originally sourced `env_ubuntu.sh`, which required HPDCache
  discovery even though Phase 1 is no-cache. Fixed by making the baseline
  script set only the paths it needs.
- Root detection initially selected an `/original/` workspace. Fixed by
  preferring the script-relative workspace and `/work/` search results.
- Verilator reported `BLKANDNBLK` errors in CV32E40P CSR performance counter
  generate logic. This is a tool compatibility issue for the baseline build.
  Fixed by adding Verilator waivers in the baseline script:
  `-Wno-BLKANDNBLK`, `-Wno-COMBDLY`, and `-Wno-UNOPTFLAT`.

No CV32E40P source RTL was patched.

## Measurement Points

Recommended baseline start:

- First cycle after `rst_n == 1` and `fetch_enable == 1`

Recommended baseline end:

- DONE store:
  `data_req && data_gnt && data_we && data_addr == 32'h2000_0004`

Current smoke baseline:

- PASS at testbench cycle 15

This is a bring-up smoke baseline, not the final performance benchmark.

## Phase 1 Summary

Files read:

- `rtl/l1_cache/logs/error.log`
- `rtl/l1_cache/logs/01_baseline_original.log`
- `rtl/l1_cache/work/tb/tb_cv32e40p_baseline_original.sv`
- `rtl/l1_cache/work/sim/cv32e40p_baseline.f`
- `rtl/l1_cache/work/sim/Makefile`
- `rtl/cv32e40p_cs_registers.sv`

Files created/modified:

- Modified `rtl/l1_cache/work/sim/run_baseline_original.sh`
- Updated `rtl/l1_cache/docs/01_baseline_original_result.md`
- Generated `rtl/l1_cache/logs/01_baseline_original.log`
- Generated `rtl/l1_cache/work/waves/01_baseline_original.vcd`

Commands run:

- `make -C rtl/l1_cache/work/sim run_baseline`

Pass/fail:

- Pass

Next step:

- Phase 2 precheck: inspect existing adapter/wrapper/testbench files and
  HPDCache interface details before running or editing adapter tests.
