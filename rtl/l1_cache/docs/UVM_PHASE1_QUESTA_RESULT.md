# UVM Phase 1 Questa Result

Date: Thu Jun  4 04:15:59 AM UTC 2026

## Command

```sh
make HPDCACHE_SRC_MODE=base run_uvm_full_l1_basic
```

## Tool And Source Mode

- Backend: Questa/ModelSim
- Questa version: `Questa Altera Starter FPGA Edition-64 vsim 2025.2 Simulator 2025.05 May 31 2025`
- HPDCACHE_SRC_MODE: `base`
- HPDCACHE_PATCH_DIR: unused by base-mode selected filelist
- Patched HPDCache selected: no
- UVM library: `mtiUvm`
- Questa coverage enabled: `0`
- UVM source include: `/home/admin/altera/25.1std/questa_fse/verilog_src/uvm-1.1d/src`

## Filelists

- HPDCache: `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim/hpdcache_base_cv32.f`
- I-Cache: `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim/cva6_icache_full_for_cv32.f`
- Full L1: `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim/cv32e40p_full_l1_basic.f`
- UVM: `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim/cv32_l1_uvm_questa.f`

## Result

- Status: `PASS`
- UVM test name: `uvm_full_l1_basic_test`
- Log path: `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/logs/uvm_full_l1_basic_questa.log`
- Coverage UCDB: `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/logs/uvm_full_l1_basic.ucdb` (only generated when `QUESTA_ENABLE_COVERAGE=1`)
- Performance CSV: `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/logs/uvm_perf_raw.csv`

## Final Counters

# cycle_count = 356
# instr_access_count = 18
# icache_miss_count = 5
# icache_refill_count = 5
# core_load_count = 3
# core_store_count = 5
# mem_read_count = 10
# mem_write_count = 2
# read_miss_count = 5
# write_miss_count = 4
# dcache_miss_count = 9

## Phase 2/3/4/5/6 TODO

- Add real transaction classes and analysis ports.
- Implement directed tests for reset, I-Cache, D-Cache, PLRU, writeback, VBUF, arbiter, and ordering.
- Replace coverage skeleton sampling with real monitor-driven sampling.
- Add UVM performance latency and throughput tests.
- Add 3-mode UVM performance comparison and regression report generation.
