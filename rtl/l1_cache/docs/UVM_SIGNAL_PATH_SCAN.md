# UVM Signal Path Scan

Date: 2026-06-03

The UVM Phase 1 flow uses only signals confirmed at the existing Full L1 top level or in the proven basic testbench.

## DUT Instance

UVM top:

`tb_cv32_l1_uvm_top.dut`

DUT module:

`cv32e40p_full_l1_cache_top`

Source:

`rtl/l1_cache/work/rtl/cv32e40p_full_l1_cache_top.sv`

## System Signals

| UVM Interface Field | DUT Path | Direction In UVM Phase 1 |
|---|---|---|
| `sys_if.clk` | `dut.clk` | Driven by UVM top clock generator. |
| `sys_if.rst_n` | `dut.rst_n` | Driven by UVM test. |
| `sys_if.fetch_enable` | `dut.fetch_enable` | Driven by UVM test. |
| `sys_if.boot_addr` | `dut.boot_addr` | Driven by UVM test. |
| `sys_if.done` | `dut.done` | Observed by UVM top/scoreboard. |
| `sys_if.pass` | `dut.pass` | Observed by UVM top/scoreboard. |

## Counter Signals

| UVM Interface Field | DUT Path |
|---|---|
| `perf_if.cycle_count` | `dut.cycle_count` |
| `perf_if.instr_access_count` | `dut.instr_access_count` |
| `perf_if.icache_miss_count` | `dut.icache_miss_count` |
| `perf_if.icache_refill_count` | `dut.icache_refill_count` |
| `perf_if.core_load_count` | `dut.core_load_count` |
| `perf_if.core_store_count` | `dut.core_store_count` |
| `perf_if.mem_read_count` | `dut.mem_read_count` |
| `perf_if.mem_write_count` | `dut.mem_write_count` |
| `perf_if.read_miss_count` | `dut.read_miss_count` |
| `perf_if.write_miss_count` | `dut.write_miss_count` |
| `perf_if.dcache_miss_count` | `dut.dcache_miss_count` |

## Core And Cache Event Signals

| UVM Interface Field | DUT Path |
|---|---|
| `core_if.instr_req` | `dut.instr_req` |
| `core_if.instr_gnt` | `dut.instr_gnt` |
| `core_if.instr_rvalid` | `dut.instr_rvalid` |
| `core_if.instr_addr` | `dut.instr_addr` |
| `core_if.instr_rdata` | `dut.instr_rdata` |
| `core_if.data_req` | `dut.data_req` |
| `core_if.data_gnt` | `dut.data_gnt` |
| `core_if.data_rvalid` | `dut.data_rvalid` |
| `core_if.data_we` | `dut.data_we` |
| `core_if.data_be` | `dut.data_be` |
| `core_if.data_addr` | `dut.data_addr` |
| `core_if.data_wdata` | `dut.data_wdata` |
| `core_if.data_rdata` | `dut.data_rdata` |
| `cache_event_if.icache_miss` | `dut.icache_miss` |
| `cache_event_if.icache_refill_return` | `dut.icache_refill_return` |
| `cache_event_if.dcache_read_miss` | `dut.evt_cache_read_miss` |
| `cache_event_if.dcache_write_miss` | `dut.evt_cache_write_miss` |
| `cache_event_if.dcache_read_req` | `dut.evt_read_req` |
| `cache_event_if.dcache_write_req` | `dut.evt_write_req` |
| `cache_event_if.dcache_stall` | `dut.evt_stall` |
| `cache_event_if.wbuf_empty` | `dut.wbuf_empty` |
| `cache_event_if.arb_state` | `dut.arb_state` |
| `cache_event_if.instr_adapter_state` | `dut.instr_adapter_state` |
| `cache_event_if.icache_mem_adapter_state` | `dut.icache_mem_adapter_state` |

## Memory Initialization

The UVM top reuses the same memory image as `tb_cv32e40p_full_l1_basic.sv`.

Memory write path:

`dut.arbiter_i.mem[word_index(addr)]`

The index function uses:

`(addr >> 2) % dut.arbiter_i.MEM_WORDS`

## Deep Monitor Status

PLRU, VBUF, MSHR, RTAB, and detailed arbiter monitors are Phase 0 skeletons. No unconfirmed deep hierarchical paths are guessed in Phase 1.

