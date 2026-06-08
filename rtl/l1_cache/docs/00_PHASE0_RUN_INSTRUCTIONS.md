# Phase 0 Run Instructions

Run these commands in Ubuntu VirtualBox, not Windows:

```bash
ls /media
ls /media/$USER 2>/dev/null || true
find /media -maxdepth 8 -type d -name "cv32e40p-master" 2>/dev/null

export ROOT_WORKSPACE=<Ubuntu path found above>
cd "$ROOT_WORKSPACE"
bash rtl/l1_cache/work/sim/phase0_setup_scan.sh
```

Then send back:

```bash
tail -n 120 rtl/l1_cache/logs/error.log
tail -n 120 rtl/l1_cache/logs/00_phase0_scan.log
```

Expected generated files:

- `rtl/l1_cache/logs/error.log`
- `rtl/l1_cache/logs/00_phase0_scan.log`
- `rtl/l1_cache/docs/00_scan_cv32_hpdcache.md`
- `rtl/l1_cache/work/sim/run_and_log.sh`
