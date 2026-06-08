# 04 - HPDCache Wrapper Reset Debug

Date: 2026-05-26

## Scope

Tai lieu nay ghi lai debug rieng cho `hpdcache_cv32_wrapper` sau khi full
`CV32E40P + HPDCache` bi timeout trong Phase 3. Muc tieu la tach loi compile,
loi reset/wrapper, loi VBUF, va gioi han simulator.

Khong sua RTL goc cua CV32E40P. Khong sua folder `rtl/l1_cache/original`.

## Files read

- `rtl/l1_cache/work/rtl/hpdcache_cv32_wrapper.sv`
- `rtl/l1_cache/work/rtl/cv32_data_to_hpdcache_adapter.sv`
- `rtl/l1_cache/work/tb/tb_hpdcache_cv32_wrapper_reset.sv`
- `rtl/l1_cache/hpdcache/cv-hpdcache/rtl/src/hpdcache.sv`
- `rtl/l1_cache/hpdcache/cv-hpdcache/rtl/src/hpdcache_ctrl.sv`
- `rtl/l1_cache/hpdcache/cv-hpdcache/rtl/src/hpdcache_ctrl_pe.sv`
- `rtl/l1_cache/hpdcache/cv-hpdcache/rtl/src/hpdcache_vbuf.sv`
- `rtl/l1_cache/logs/05_hpdcache_wrapper_reset.log`
- `rtl/l1_cache/logs/06_hpdcache_wrapper_reset_disable_vbuf_owner.log`
- `rtl/l1_cache/logs/07_hpdcache_wrapper_reset_tieoff_vbuf.log`
- `rtl/l1_cache/logs/08_hpdcache_wrapper_reset_head_triplet.log`
- `rtl/l1_cache/logs/09_hpdcache_wrapper_reset_head_triplet_novcd.log`
- `rtl/l1_cache/logs/10_hpdcache_wrapper_reset_iterlimit.log`
- `rtl/l1_cache/logs/03_cv32_dcache_basic_novcd.log`

## Files created or modified

- Created `rtl/l1_cache/work/sim/run_hpdcache_wrapper_reset_tieoff_vbuf.ps1`
- Created `rtl/l1_cache/work/sim/run_hpdcache_wrapper_reset_head_triplet.ps1`
- Created `rtl/l1_cache/work/sim/run_hpdcache_wrapper_reset_head_triplet_novcd.ps1`
- Created `rtl/l1_cache/work/sim/run_hpdcache_wrapper_reset_iterlimit.ps1`
- Created `rtl/l1_cache/work/sim/run_cv32_dcache_basic_novcd.ps1`
- Created `rtl/l1_cache/work/sim/hpdcache_head_triplet.Flist`
- Created generated HEAD copies under `rtl/l1_cache/work/hpdcache_patched/src/`:
  - `head_hpdcache.sv`
  - `head_hpdcache_ctrl.sv`
  - `head_hpdcache_ctrl_pe.sv`
  - `head_hpdcache_vbuf.sv`
- Modified `rtl/l1_cache/work/hpdcache_patched/src/hpdcache.sv` for a debug-only
  VBUF tieoff experiment.
- Modified `rtl/l1_cache/work/tb/tb_hpdcache_cv32_wrapper_reset.sv` so `rst_n`
  starts at `1'b0`.
- Modified `rtl/l1_cache/work/rtl/hpdcache_cv32_wrapper.sv`:
  - `nRequesters = 1`
  - `lowLatency = 1'b0`
- Modified `rtl/l1_cache/work/sim/Makefile` to expose the debug targets.

## Commands run

```powershell
powershell -ExecutionPolicy Bypass -File .\run_hpdcache_wrapper_reset.ps1
powershell -ExecutionPolicy Bypass -File .\run_hpdcache_wrapper_reset_disable_vbuf_owner.ps1
powershell -ExecutionPolicy Bypass -File .\run_hpdcache_wrapper_reset_tieoff_vbuf.ps1
powershell -ExecutionPolicy Bypass -File .\run_hpdcache_wrapper_reset_head_triplet.ps1
powershell -ExecutionPolicy Bypass -File .\run_hpdcache_wrapper_reset_head_triplet_novcd.ps1
powershell -ExecutionPolicy Bypass -File .\run_hpdcache_wrapper_reset_iterlimit.ps1
powershell -ExecutionPolicy Bypass -File .\run_cv32_dcache_basic_novcd.ps1
```

Run directory:

```text
rtl/l1_cache/work/sim
```

## Results

| Run | Purpose | Result |
|---|---|---|
| `05_hpdcache_wrapper_reset.log` | Wrapper reset-only, current patched HPDCache | Compile PASS, runtime timeout |
| `06_hpdcache_wrapper_reset_disable_vbuf_owner.log` | Disable VBUF replacement-owner path | Compile PASS, runtime timeout |
| `07_hpdcache_wrapper_reset_tieoff_vbuf.log` | Tie off VBUF outputs in patched copy | Compile PASS, runtime timeout |
| `08_hpdcache_wrapper_reset_head_triplet.log` | Use HEAD copies of `hpdcache`, `ctrl`, `ctrl_pe`, `vbuf` | Compile PASS, runtime timeout with VCD |
| `09_hpdcache_wrapper_reset_head_triplet_novcd.log` | Same HEAD triplet, no VCD, 60s timeout | PASS marker at 245 ns |
| `10_hpdcache_wrapper_reset_iterlimit.log` | Try low iteration-limit probe | Timeout before useful report |
| `03_cv32_dcache_basic_novcd.log` | Full CV32 + HPDCache, no VCD, suppress warning 8315 | Timeout at `run -all` |

Important PASS marker:

```text
[PHASE3DBG][PASS] wrapper reset-only advanced to time 245000 req_ready=0 rsp_valid=0 wbuf_empty=1
```

The wrapper reset-only run reached 245 ns in about 38 seconds wall-clock when
VCD was disabled. ModelSim returned process exit code 1 because the TB uses
`$finish`, but the log has `Errors: 0` and the explicit PASS marker.

## Main observations

- The HPDCache wrapper is not failing at compile.
- The HPDCache wrapper can advance past time 0 in a no-VCD reset-only test.
- Tying off VBUF did not by itself solve the earlier time-0 timeout, so the
  runtime issue is not isolated only to the instantiated VBUF module.
- Using HEAD versions of the main HPDCache control/VBUF files also did not make
  the VCD reset-only run fast enough, but the no-VCD run passed.
- Full `CV32E40P + adapter + HPDCache` still does not complete within 180s
  no-VCD on ModelSim Intel FPGA Starter.
- The log reports that the design size exceeds the ModelSim Starter recommended
  capacity:

```text
Design size of 13291 statements exceeds ModelSim-Intel FPGA Starter Edition recommended capacity.
Expect performance to be adversely affected.
```

## Adapter fix found during debug

The original adapter had a combinational ready path risk:

```text
CV32 data_req -> adapter req_valid -> HPDCache req_ready -> adapter data_gnt -> CV32 LSU
```

This was fixed by adding a one-entry skid buffer in:

```text
rtl/l1_cache/work/rtl/cv32_data_to_hpdcache_adapter.sv
```

After that change, the adapter basic TB passed again:

```text
[PHASE2][PASS] adapter basic completed 8 checks
```

## Current conclusion

Phase 3 is no longer blocked by compile errors. It is blocked by full-design
runtime on the available ModelSim Intel FPGA Starter setup. The next debug
step should reduce simulator load or change simulator, instead of making broad
RTL edits.

## Recommended next steps

1. Run the full top on full Questa or another faster SystemVerilog simulator if
   available.
2. If staying with ModelSim Starter, add a reduced RTL smoke path:
   - smaller HPDCache config,
   - or a temporary behavioral cache wrapper only for CV32 waveform bring-up,
   - or a direct HPDCache-wrapper load/store TB without CV32.
3. Keep the real HPDCache integration files as-is until the reduced debug path
   identifies a functional mismatch.
4. Once the full sim advances, inspect:
   - CV32 instruction fetch,
   - CV32 data request/grant/rvalid,
   - adapter request buffer state,
   - HPDCache read/write miss events,
   - refill traffic,
   - dirty write-back/VBUF traffic,
   - DONE-store or timeout condition.
