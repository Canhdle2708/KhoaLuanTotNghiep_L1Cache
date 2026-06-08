# 05 - Progress: make build / make run Status

Date: 2026-05-26

## Direct answer

GTKWave for the full `CV32E40P + HPDCache` integration is not usable yet.

There is a VCD path:

```text
rtl/l1_cache/work/waves/03_cv32_dcache_basic.vcd
```

but the full simulation times out before reaching a useful functional point.
So this VCD is not proof that CV32E40P is running load/store through HPDCache.

## Target status

| Target | Meaning | Current status |
|---|---|---|
| `make build` | Compile real `CV32E40P + adapter + HPDCache + TB` | Verified PASS via PowerShell script |
| `make run` | Run real full integration simulation | Current FAIL/TIMEOUT |
| `make run_full` | Alias for real full integration run | Current FAIL/TIMEOUT |
| `make run_smoke` | Adapter unit test plus HPDCache wrapper reset-only smoke | Verified PASS via PowerShell scripts |
| `make wave_basic` | Open `03_cv32_dcache_basic.vcd` in GTKWave | File exists, but waveform is not functionally useful yet |

Note: on the current shell, `make` is not found in PATH. The same targets can
be run directly with PowerShell scripts from `rtl/l1_cache/work/sim`.

## Commands verified or prepared

Compile-only full integration, verified PASS:

```powershell
cd rtl/l1_cache/work/sim
powershell -ExecutionPolicy Bypass -File .\build_cv32_dcache_basic.ps1
```

Real full integration run:

```powershell
cd rtl/l1_cache/work/sim
powershell -ExecutionPolicy Bypass -File .\run_cv32_dcache_basic.ps1
```

Smoke run, verified PASS:

```powershell
cd rtl/l1_cache/work/sim
powershell -ExecutionPolicy Bypass -File .\run_adapter_basic.ps1
powershell -ExecutionPolicy Bypass -File .\run_hpdcache_wrapper_reset_smoke.ps1
```

Observed PASS markers:

```text
[BUILD][PASS] CV32E40P + HPDCache compile-only completed
[PHASE2][PASS] adapter basic completed 8 checks
[SMOKE][PASS] PASS marker found
```

## Logs

- Build log: `rtl/l1_cache/logs/00_build_cv32_dcache.log`
- Smoke log: `rtl/l1_cache/logs/00_run_smoke_hpdcache_wrapper_reset.log`
- Full run log: `rtl/l1_cache/logs/03_cv32_dcache_basic.log`
- Full no-VCD run log: `rtl/l1_cache/logs/03_cv32_dcache_basic_novcd.log`

## Main blocker

The full design compiles, but ModelSim Intel FPGA Starter does not complete the
full simulation within the timeout. The log reports:

```text
Design size of 13291 statements exceeds ModelSim-Intel FPGA Starter Edition recommended capacity.
Expect performance to be adversely affected.
```

The next step is to either use a faster/full simulator or add a reduced RTL
smoke configuration before claiming `make run` PASS for the real integration.
