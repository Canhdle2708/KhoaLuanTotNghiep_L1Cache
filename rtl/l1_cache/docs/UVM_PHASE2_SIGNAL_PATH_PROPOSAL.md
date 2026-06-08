# UVM Phase 2 Signal Path Proposal

This document is a proposal only. Do not implement LOW confidence paths directly.

Confidence definitions:
- HIGH: found directly in the current UVM top and/or Full L1 top.
- MEDIUM: inferred from current wrappers/interfaces; should be checked during implementation.
- LOW: not confirmed; do not use directly in Phase 2.

## System Signals

| Signal Name | Proposed Hierarchical Path | Confidence | Used By | Notes |
|---|---|---|---|---|
| clk | `tb_cv32_l1_uvm_top.sys_if.clk`, driven into `tb_cv32_l1_uvm_top.dut.clk` | HIGH | sys_monitor, all monitors | UVM top toggles both signals together. |
| rst_n | `tb_cv32_l1_uvm_top.sys_if.rst_n`, driven into `tb_cv32_l1_uvm_top.dut.rst_n` | HIGH | sys_monitor, scoreboard | Phase 1 drives reset from UVM test. |
| fetch_enable | `tb_cv32_l1_uvm_top.sys_if.fetch_enable`, driven into `tb_cv32_l1_uvm_top.dut.fetch_enable` | HIGH | sys_monitor, scoreboard | Phase 1 asserts after reset. |
| done | `tb_cv32_l1_uvm_top.dut.done`, mirrored to `tb_cv32_l1_uvm_top.sys_if.done` | HIGH | sys_monitor, scoreboard | Existing pass criterion. |
| pass | `tb_cv32_l1_uvm_top.dut.pass`, mirrored to `tb_cv32_l1_uvm_top.sys_if.pass` | HIGH | sys_monitor, scoreboard | Existing pass criterion. |

## Counter Signals

| Signal Name | Proposed Hierarchical Path | Confidence | Used By | Notes |
|---|---|---|---|---|
| cycle_count | `tb_cv32_l1_uvm_top.dut.cycle_count`, mirrored to `perf_if.cycle_count` | HIGH | perf_collector, scoreboard | Current PASS value: 356. |
| instr_access_count | `tb_cv32_l1_uvm_top.dut.instr_access_count`, mirrored to `perf_if.instr_access_count` | HIGH | core_monitor, scoreboard | Counts `instr_adapter_req_accept`. |
| icache_miss_count | `tb_cv32_l1_uvm_top.dut.icache_miss_count`, mirrored to `perf_if.icache_miss_count` | HIGH | icache_monitor, perf_collector | Current PASS value: 5. |
| icache_refill_count | `tb_cv32_l1_uvm_top.dut.icache_refill_count`, mirrored to `perf_if.icache_refill_count` | HIGH | icache_monitor, perf_collector | Current PASS value: 5. |
| core_load_count | `tb_cv32_l1_uvm_top.dut.core_load_count`, mirrored to `perf_if.core_load_count` | HIGH | core_monitor, scoreboard | Counts accepted loads. |
| core_store_count | `tb_cv32_l1_uvm_top.dut.core_store_count`, mirrored to `perf_if.core_store_count` | HIGH | core_monitor, scoreboard | Counts accepted stores. |
| mem_read_count | `tb_cv32_l1_uvm_top.dut.mem_read_count`, mirrored to `perf_if.mem_read_count` | HIGH | mem_monitor, perf_collector | Includes I-cache and D-cache memory reads as defined by DUT. |
| mem_write_count | `tb_cv32_l1_uvm_top.dut.mem_write_count`, mirrored to `perf_if.mem_write_count` | HIGH | mem_monitor, perf_collector | Counts DUT memory write events. |
| dcache_miss_count | `tb_cv32_l1_uvm_top.dut.dcache_miss_count`, mirrored to `perf_if.dcache_miss_count` | HIGH | dcache_monitor, perf_collector | Sum of read/write miss events. |
| read_miss_count | `tb_cv32_l1_uvm_top.dut.read_miss_count`, mirrored to `perf_if.read_miss_count` | HIGH | dcache_monitor, scoreboard | Current PASS value: 5. |
| write_miss_count | `tb_cv32_l1_uvm_top.dut.write_miss_count`, mirrored to `perf_if.write_miss_count` | HIGH | dcache_monitor, scoreboard | Current PASS value: 4. |

## Core Instruction/Data Port Signals

| Signal Name | Proposed Hierarchical Path | Confidence | Used By | Notes |
|---|---|---|---|---|
| instr_req | `tb_cv32_l1_uvm_top.dut.instr_req`, mirrored to `core_if.instr_req` | HIGH | core_monitor | Request from CV32E40P instruction port. |
| instr_gnt | `tb_cv32_l1_uvm_top.dut.instr_gnt`, mirrored to `core_if.instr_gnt` | HIGH | core_monitor | Accept when `instr_req && instr_gnt`. |
| instr_rvalid | `tb_cv32_l1_uvm_top.dut.instr_rvalid`, mirrored to `core_if.instr_rvalid` | HIGH | core_monitor, scoreboard | Instruction response valid. |
| instr_addr | `tb_cv32_l1_uvm_top.dut.instr_addr`, mirrored to `core_if.instr_addr` | HIGH | core_monitor | Use on accept. |
| instr_rdata | `tb_cv32_l1_uvm_top.dut.instr_rdata`, mirrored to `core_if.instr_rdata` | HIGH | core_monitor | Use on response. |
| instr_err | `tb_cv32_l1_uvm_top.dut.instr_err`, mirrored to `core_if.instr_err` | HIGH | core_monitor, scoreboard | Should stay low in basic pass. |
| data_req | `tb_cv32_l1_uvm_top.dut.data_req`, mirrored to `core_if.data_req` | HIGH | core_monitor, dcache_monitor | Data port request. |
| data_gnt | `tb_cv32_l1_uvm_top.dut.data_gnt`, mirrored to `core_if.data_gnt` | HIGH | core_monitor, dcache_monitor | Accept when `data_req && data_gnt`. |
| data_rvalid | `tb_cv32_l1_uvm_top.dut.data_rvalid`, mirrored to `core_if.data_rvalid` | HIGH | core_monitor, scoreboard | Load response valid. Store semantics need confirmation. |
| data_we | `tb_cv32_l1_uvm_top.dut.data_we`, mirrored to `core_if.data_we` | HIGH | core_monitor | 0=load, 1=store. |
| data_be | `tb_cv32_l1_uvm_top.dut.data_be`, mirrored to `core_if.data_be` | HIGH | core_monitor | Byte enable. |
| data_addr | `tb_cv32_l1_uvm_top.dut.data_addr`, mirrored to `core_if.data_addr` | HIGH | core_monitor | Use on accepted data request. |
| data_wdata | `tb_cv32_l1_uvm_top.dut.data_wdata`, mirrored to `core_if.data_wdata` | HIGH | core_monitor | Store data. |
| data_rdata | `tb_cv32_l1_uvm_top.dut.data_rdata`, mirrored to `core_if.data_rdata` | HIGH | core_monitor | Load response data. |
| data_err | `tb_cv32_l1_uvm_top.dut.data_err`, mirrored to `core_if.data_err` | HIGH | core_monitor, scoreboard | Should stay low in basic pass. |

## Memory Interface Signals

| Signal Name | Proposed Hierarchical Path | Confidence | Used By | Notes |
|---|---|---|---|---|
| mem_req_read_valid | `tb_cv32_l1_uvm_top.dut.mem_req_read_valid` | HIGH | mem_monitor | D-cache memory read request valid. |
| mem_req_read_ready | `tb_cv32_l1_uvm_top.dut.mem_req_read_ready` | HIGH | mem_monitor | D-cache memory read request ready. |
| mem_req_read_addr | `tb_cv32_l1_uvm_top.dut.mem_req_read_addr` | HIGH | mem_monitor | D-cache memory read address. |
| mem_resp_read_valid | `tb_cv32_l1_uvm_top.dut.mem_resp_read_valid` | HIGH | mem_monitor | D-cache memory read response valid. |
| mem_resp_read_ready | `tb_cv32_l1_uvm_top.dut.mem_resp_read_ready` | HIGH | mem_monitor | D-cache memory read response ready. |
| mem_resp_read_data | `tb_cv32_l1_uvm_top.dut.mem_resp_read_data` | HIGH | mem_monitor | 128-bit D-cache memory read data. |
| mem_resp_read_last | `tb_cv32_l1_uvm_top.dut.mem_resp_read_last` | HIGH | mem_monitor | Last beat. |
| mem_req_write_valid | `tb_cv32_l1_uvm_top.dut.mem_req_write_valid` | HIGH | mem_monitor | D-cache memory write address/control valid. |
| mem_req_write_ready | `tb_cv32_l1_uvm_top.dut.mem_req_write_ready` | HIGH | mem_monitor | D-cache memory write address/control ready. |
| mem_req_write_addr | `tb_cv32_l1_uvm_top.dut.mem_req_write_addr` | HIGH | mem_monitor | D-cache memory write address. |
| mem_req_write_data_valid | `tb_cv32_l1_uvm_top.dut.mem_req_write_data_valid` | HIGH | mem_monitor | Split write data valid. |
| mem_req_write_data_ready | `tb_cv32_l1_uvm_top.dut.mem_req_write_data_ready` | HIGH | mem_monitor | Split write data ready. |
| mem_req_write_data | `tb_cv32_l1_uvm_top.dut.mem_req_write_data` | HIGH | mem_monitor | 128-bit write data. |
| mem_req_write_data_be | `tb_cv32_l1_uvm_top.dut.mem_req_write_be` | HIGH | mem_monitor | DUT names this `mem_req_write_be`, not `mem_req_write_data_be`. |
| mem_req_write_data_last | `tb_cv32_l1_uvm_top.dut.mem_req_write_last` | HIGH | mem_monitor | DUT names this `mem_req_write_last`. |
| mem_resp_write_valid | `tb_cv32_l1_uvm_top.dut.mem_resp_write_valid` | HIGH | mem_monitor | Write response valid. |
| mem_resp_write_ready | `tb_cv32_l1_uvm_top.dut.mem_resp_write_ready` | HIGH | mem_monitor | Write response ready. |

## I-Cache L1 Memory Signals

| Signal Name | Proposed Hierarchical Path | Confidence | Used By | Notes |
|---|---|---|---|---|
| ic_l1_read_req_valid | `tb_cv32_l1_uvm_top.dut.ic_l1_read_req_valid` | HIGH | mem_monitor, icache_monitor | I-cache memory read request. |
| ic_l1_read_req_ready | `tb_cv32_l1_uvm_top.dut.ic_l1_read_req_ready` | HIGH | mem_monitor, icache_monitor | I-cache memory read ready. |
| ic_l1_read_req_addr | `tb_cv32_l1_uvm_top.dut.ic_l1_read_req_addr` | HIGH | mem_monitor, icache_monitor | I-cache refill address. |
| ic_l1_read_rsp_valid | `tb_cv32_l1_uvm_top.dut.ic_l1_read_rsp_valid` | HIGH | mem_monitor, icache_monitor | I-cache read response. |
| ic_l1_read_rsp_ready | `tb_cv32_l1_uvm_top.dut.ic_l1_read_rsp_ready` | HIGH | mem_monitor, icache_monitor | I-cache response ready. |
| ic_l1_read_rsp_data | `tb_cv32_l1_uvm_top.dut.ic_l1_read_rsp_data` | HIGH | mem_monitor | Data is wider than current `cv32_l1_mem_if`; add only if needed. |

## Cache Event Signals

| Signal Name | Proposed Hierarchical Path | Confidence | Used By | Notes |
|---|---|---|---|---|
| icache_miss | `tb_cv32_l1_uvm_top.dut.icache_miss`, mirrored to `cache_event_if.icache_miss` | HIGH | icache_monitor | Event pulse. |
| icache_refill_return | `tb_cv32_l1_uvm_top.dut.icache_refill_return`, mirrored to `cache_event_if.icache_refill_return` | HIGH | icache_monitor | Event pulse. |
| dcache_read_miss | `tb_cv32_l1_uvm_top.dut.evt_cache_read_miss`, mirrored to `cache_event_if.dcache_read_miss` | HIGH | dcache_monitor | Event pulse. |
| dcache_write_miss | `tb_cv32_l1_uvm_top.dut.evt_cache_write_miss`, mirrored to `cache_event_if.dcache_write_miss` | HIGH | dcache_monitor | Event pulse. |
| dcache_read_req | `tb_cv32_l1_uvm_top.dut.evt_read_req`, mirrored to `cache_event_if.dcache_read_req` | HIGH | dcache_monitor | Event pulse. |
| dcache_write_req | `tb_cv32_l1_uvm_top.dut.evt_write_req`, mirrored to `cache_event_if.dcache_write_req` | HIGH | dcache_monitor | Event pulse. |
| dcache_stall | `tb_cv32_l1_uvm_top.dut.evt_stall`, mirrored to `cache_event_if.dcache_stall` | HIGH | dcache_monitor | Event/status signal. |
| wbuf_empty | `tb_cv32_l1_uvm_top.dut.wbuf_empty`, mirrored to `cache_event_if.wbuf_empty` | HIGH | vbuf_monitor | Only use as event/status in Phase 2. |
| arb_state | `tb_cv32_l1_uvm_top.dut.arb_state`, mirrored to `cache_event_if.arb_state` | HIGH | arbiter_monitor | State encoding should remain non-checking in Phase 2. |
| instr_adapter_state | `tb_cv32_l1_uvm_top.dut.instr_adapter_state`, mirrored to `cache_event_if.instr_adapter_state` | HIGH | core/icache monitor | State encoding should remain informational. |
| icache_mem_adapter_state | `tb_cv32_l1_uvm_top.dut.icache_mem_adapter_state`, mirrored to `cache_event_if.icache_mem_adapter_state` | HIGH | icache/mem monitor | State encoding should remain informational. |

## LOW Confidence Paths

Do not implement these directly in Phase 2 without a separate scan:

| Signal Name | Proposed Hierarchical Path | Confidence | Used By | Notes |
|---|---|---|---|---|
| PLRU internal selected way | Internal HPDCache hierarchy under `dut.dcache_i` | LOW | plru_monitor | Deep hierarchy not validated. |
| VBUF forward hit internals | Internal HPDCache hierarchy under `dut.dcache_i` | LOW | vbuf_monitor | Use visible events/counters only in Phase 2. |
| MSHR allocation internals | Internal HPDCache hierarchy under `dut.dcache_i` | LOW | mshr_rtab_monitor | Defer deep checker. |
| RTAB replay internals | Internal HPDCache hierarchy under `dut.dcache_i` | LOW | mshr_rtab_monitor | Defer deep checker. |

