# PHASE I0 - Full I-Cache Integration Precheck

- Time: Wed May 27 07:41:48 AM UTC 2026
- CV32_ROOT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master`
- L1_ROOT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache`
- ICACHE_ROOT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full`
- HPDCACHE_ROOT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/hpdcache/cv-hpdcache`
- WORK_ROOT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work`

## Required Path Checks

- [OK] CV32_ROOT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master`
- [OK] L1_ROOT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache`
- [OK] ICACHE_ROOT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full`
- [OK] I-Cache DUT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv`
- [OK] I-Cache filelist: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/sim/cva6_icache_full.f`
- [OK] I-Cache integration notes: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/docs/03_cva6_icache_integration_notes.md`
- [OK] HPDCACHE_ROOT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/hpdcache/cv-hpdcache`
- [OK] HPDCache DUT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/hpdcache/cv-hpdcache/rtl/src/hpdcache.sv`
- [OK] D-Cache-only top: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/rtl/cv32e40p_l1_dcache_top.sv`
- [OK] CV32 data to HPDCache adapter: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/rtl/cv32_data_to_hpdcache_adapter.sv`
- [OK] Work Makefile: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim/Makefile`

## I-Cache Full Bundle

- ICACHE_ROOT path: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full`
- I-Cache DUT file: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv`
- I-Cache filelist: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/sim/cva6_icache_full.f`
- Integration notes: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/docs/03_cva6_icache_integration_notes.md`

## HPDCache Full Bundle

- HPDCACHE_ROOT path: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/hpdcache/cv-hpdcache`
- HPDCache DUT file: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/hpdcache/cv-hpdcache/rtl/src/hpdcache.sv`

## Current D-Cache-Only Work/Sim

- D-Cache-only top: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/rtl/cv32e40p_l1_dcache_top.sv`
- Data adapter: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/rtl/cv32_data_to_hpdcache_adapter.sv`
- Makefile: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim/Makefile`

### D-Cache-related testbench files found

- `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/tb/tb_cv32_dcache_adapter_basic.sv`
- `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/tb/tb_cv32e40p_dcache_basic.sv`
- `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/tb/tb_cv32e40p_dcache_random.sv`
- `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/tb/tb_hpdcache_cv32_wrapper_reset.sv`

## HPDCache Source Mode

- Detected mode status: `BASE_DEFAULT_OR_SET`

Relevant Makefile lines:

```text
7:HPDCACHE_SRC_MODE ?= base
8:export HPDCACHE_SRC_MODE
15:	  echo "[HPDCACHE_SRC_MODE] $(HPDCACHE_SRC_MODE)"; \
35:	run_cv32_dcache_basic \
36:	run_cv32_dcache_basic_novcd \
37:	run_cv32_dcache_random \
39:	wave_basic \
46:run: run_cv32_dcache_basic
48:run_full: run_cv32_dcache_basic
56:run_cv32_dcache_basic:
57:	$(call RUN_LOGGED,bash ./run_cv32_dcache_basic.sh)
59:run_cv32_dcache_basic_novcd:
60:	$(call RUN_LOGGED,bash ./run_cv32_dcache_basic_novcd.sh)
62:run_cv32_dcache_random:
63:	$(call RUN_LOGGED,bash ./run_cv32_dcache_random.sh $(SEEDS))
65:run_smoke: run_adapter_basic run_cv32_dcache_basic
67:wave_basic:
```

## Risks Before Integration

- Need confirm `HPDCACHE_SRC_MODE` selects the full HPDCache WB+VBUF source mode before running full L1.
- Need preserve existing D-Cache-only top and Makefile targets.
- Need inspect CVA6 I-Cache typedef/config/interface before creating any adapter.
- Need avoid old I-Cache path outside `cv32e40p-master`.
- No RTL/source files were modified in this precheck.
