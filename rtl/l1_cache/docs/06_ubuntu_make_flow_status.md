# 06 - Ubuntu Make Flow Status

Date: 2026-05-26

## Scope

This update adapts the simulation flow for Ubuntu VirtualBox shared-folder use.
The current Codex session is attached to the Windows workspace, so it cannot
directly see the VirtualBox `/media/sf_*` mount. A WSL probe was attempted and
failed because WSL is not installed.

The Ubuntu scripts now find `ROOT_WORKSPACE` at runtime with:

```bash
find /media -maxdepth 8 -type d -name "cv32e40p-master" 2>/dev/null
find /mnt -maxdepth 8 -type d -name "cv32e40p-master" 2>/dev/null
```

If both fail, they fall back to deriving the repository root from the script
location. You can also force the path:

```bash
export ROOT_WORKSPACE=/media/sf_source_env/cv32/work/cv32e40p-master
```

## Files Read

- `rtl/l1_cache/work/sim/Makefile`
- `rtl/l1_cache/work/sim/*.ps1`
- `rtl/l1_cache/work/tb/tb_cv32e40p_dcache_basic.sv`
- `rtl/l1_cache/work/tb/tb_cv32e40p_dcache_random.sv`
- `rtl/l1_cache/docs/02_adapter_basic_result.md`
- `rtl/l1_cache/docs/02_waveform_checklist_dcache.md`
- `rtl/l1_cache/docs/03_random_smoke_summary.md`

## Files Created Or Modified

- Created `rtl/l1_cache/work/sim/env_ubuntu.sh`
- Created `rtl/l1_cache/work/sim/build_cv32_dcache_basic.sh`
- Created `rtl/l1_cache/work/sim/run_baseline_original.sh`
- Created `rtl/l1_cache/work/sim/run_adapter_basic.sh`
- Created `rtl/l1_cache/work/sim/run_hpdcache_wrapper_reset_smoke.sh`
- Created `rtl/l1_cache/work/sim/run_cv32_dcache_basic.sh`
- Created `rtl/l1_cache/work/sim/run_cv32_dcache_basic_novcd.sh`
- Created `rtl/l1_cache/work/sim/run_cv32_dcache_random.sh`
- Modified `rtl/l1_cache/work/sim/Makefile`
- Created `rtl/l1_cache/docs/02_adapter_design_result.md`
- Created `rtl/l1_cache/docs/04_waveform_checklist_dcache.md`
- Created `rtl/l1_cache/docs/05_random_smoke_summary.md`
- Created `rtl/l1_cache/docs/06_ubuntu_make_flow_status.md`

No file under `rtl/l1_cache/original` was modified.

## Make Targets

Run from Ubuntu:

```bash
cd "$ROOT_WORKSPACE/rtl/l1_cache/work/sim"
```

Targets:

- `make build`: compile full `CV32E40P + adapter + HPDCache + TB`
- `make run`: run full `CV32E40P + HPDCache` basic simulation
- `make run_full`: same as `make run`
- `make run_smoke`: run adapter unit test and HPDCache wrapper reset smoke
- `make run_baseline`: run original/no-cache baseline
- `make run_adapter_basic`: run adapter unit test
- `make run_cv32_dcache_basic`: run full basic D-cache test
- `make run_cv32_dcache_basic_novcd`: run full basic D-cache test without VCD
- `make run_cv32_dcache_random`: run random seeds
- `make wave_basic`: open `03_cv32_dcache_basic.vcd`

## Commands Run In This Session

Attempted Ubuntu path probe through WSL:

```powershell
wsl -e sh -lc 'find /media -maxdepth 8 -type d -name cv32e40p-master 2>/dev/null; find /mnt -maxdepth 8 -type d -name cv32e40p-master 2>/dev/null'
```

Result:

```text
WSL is not installed.
```

Therefore no Ubuntu compile/sim was executed from this Codex session.

## Pass / Fail

- Script/Makefile adaptation: PASS.
- Ubuntu execution from this session: NOT RUN, no VirtualBox shell is attached.
- Full `make run` status on Ubuntu: pending user run.
- Prior Windows ModelSim Starter result: compile PASS, runtime timeout for full
  integration.

## Next Step

In Ubuntu VirtualBox:

```bash
find /media -maxdepth 8 -type d -name "cv32e40p-master" 2>/dev/null
find /mnt -maxdepth 8 -type d -name "cv32e40p-master" 2>/dev/null
export ROOT_WORKSPACE=/media/sf_source_env/cv32/work/cv32e40p-master
cd "$ROOT_WORKSPACE/rtl/l1_cache/work/sim"
make build
make run_smoke
make run
```

If `make run` fails, read:

```text
rtl/l1_cache/logs/03_cv32_dcache_basic.log
```

Then apply the smallest possible RTL or TB fix.

## Post-run Log Check From Codex Session

After the user reported that the run finished, the logs visible from this Codex
session were checked. The visible logs still contain Windows paths such as:

```text
C:\source_env\cv32\work\cv32e40p-master
```

No visible log currently contains the expected Ubuntu shared-folder path such
as:

```text
/media/sf_source_env/...
/media/sf_SOURCE_ENV/...
/mnt/...
```

Visible status from the synced workspace:

- `00_build_cv32_dcache.log`: compile-only PASS, `Errors: 0`.
- `02_adapter_basic.log`: adapter basic PASS, 8 checks.
- `00_run_smoke_hpdcache_wrapper_reset.log`: HPDCache wrapper reset smoke PASS.
- `03_cv32_dcache_basic.log`: full run still shows timeout in the older Windows
  ModelSim log.
- `03_cv32_dcache_basic_novcd.log`: no-VCD full run also shows timeout in the
  older Windows ModelSim log.

Conclusion: the Ubuntu run logs are either not synced into this workspace yet,
or the run was done before the Ubuntu `.sh` flow was added. To confirm Ubuntu
results, run this in Ubuntu and inspect the printed root/log paths:

```bash
cd "$ROOT_WORKSPACE/rtl/l1_cache/work/sim"
make build
make run_smoke
make run
tail -n 80 "$ROOT_WORKSPACE/rtl/l1_cache/logs/03_cv32_dcache_basic.log"
```
