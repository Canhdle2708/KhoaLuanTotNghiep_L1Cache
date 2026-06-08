# Waveform Checklist Full L1 - CV32E40P + CVA6 I-Cache + HPDCache

## Run Reference

- Simulation target: `make HPDCACHE_SRC_MODE=base run_full_l1_basic`
- Main log: `$L1_ROOT/logs/10_full_l1_basic.log`
- Integration log: `$L1_ROOT/logs/icache_full_integration_error.log`
- Waveform: `$WORK_ROOT/waves/full_l1_basic.vcd`
- Current basic PASS marker:
  - `full L1 basic done cycles=356`
  - `instr=18`
  - `ic_miss=5`
  - `ic_refill=5`
  - `loads=3`
  - `stores=5`
  - `mem_reads=10`
  - `mem_writes=2`
  - `dcache_miss=9`

## A. Clock / Reset

- [ ] `tb_cv32e40p_full_l1_basic.dut.clk`
- [ ] `tb_cv32e40p_full_l1_basic.dut.rst_n`
- [ ] `tb_cv32e40p_full_l1_basic.dut.fetch_enable`
- [ ] `tb_cv32e40p_full_l1_basic.dut.boot_addr`
- [ ] Reset deasserts before fetch starts.
- [ ] `boot_addr` is `32'h8000_0000`.

## B. CV32E40P Instruction Port

- [ ] `instr_req`
- [ ] `instr_gnt`
- [ ] `instr_rvalid`
- [ ] `instr_addr`
- [ ] `instr_rdata`
- [ ] `instr_err`
- [ ] `instr_addr` starts at `0x80000000`.
- [ ] Instruction data matches TB program words.
- [ ] No direct instruction memory bypass is present.

## C. I-Cache Adapter

- [ ] `instr_adapter_state`
- [ ] `instr_adapter_req_accept`
- [ ] `instr_outstanding_valid`
- [ ] `instr_outstanding_addr`
- [ ] `instr_response_valid`
- [ ] `icache_addr_req.fetch_req`
- [ ] `icache_addr_req.fetch_vaddr`
- [ ] `icache_addr_rsp.fetch_valid`
- [ ] `icache_addr_rsp.fetch_paddr`
- [ ] `icache_addr_rsp.fetch_exception.valid`
- [ ] Request address is held until I-Cache accepts it.
- [ ] Identity translation maps `fetch_paddr = fetch_vaddr`.
- [ ] Translation exception remains zero.

## D. CVA6 I-Cache

- [ ] `icache_i.clk_i`
- [ ] `icache_i.rst_ni`
- [ ] `icache_i.en_i`
- [ ] `icache_i.flush_i`
- [ ] `icache_dreq.req`
- [ ] `icache_dreq.vaddr`
- [ ] `icache_drsp.ready`
- [ ] `icache_drsp.valid`
- [ ] `icache_drsp.data`
- [ ] `icache_drsp.vaddr`
- [ ] `icache_drsp.ex.valid`
- [ ] `icache_miss`
- [ ] `icache_mem_data_req`
- [ ] `icache_mem_data_ack`
- [ ] `icache_mem_rtrn_vld`
- [ ] `icache_mem_req.paddr`
- [ ] `icache_mem_req.way`
- [ ] `icache_mem_req.tid`
- [ ] `icache_mem_rtrn.data`
- [ ] `icache_mem_rtrn.rtype`
- [ ] `icache_mem_rtrn.tid`
- [ ] Tag/index/way signals if accessible in `icache_i`.
- [ ] FSM state if accessible in `icache_i`.
- [ ] Refill write enable if accessible in `icache_i`.
- [ ] Hit/miss internal signal if accessible in `icache_i`.
- [ ] First fetch produces miss/refill.
- [ ] Later sequential fetch continues after refill.

## E. CV32E40P Data Path

- [ ] `data_req`
- [ ] `data_gnt`
- [ ] `data_rvalid`
- [ ] `data_we`
- [ ] `data_be`
- [ ] `data_addr`
- [ ] `data_wdata`
- [ ] `data_rdata`
- [ ] `data_err`
- [ ] Store to `0x00000100`.
- [ ] Load from `0x00000100`.
- [ ] Store to `0x00000200`.
- [ ] Store to `0x00000300`.
- [ ] DONE store to `0x20000004`.

## F. HPDCache

- [ ] `cache_req_valid`
- [ ] `cache_req_ready`
- [ ] `cache_req`
- [ ] `cache_rsp_valid`
- [ ] `cache_rsp`
- [ ] `evt_cache_read_miss`
- [ ] `evt_cache_write_miss`
- [ ] `evt_read_req`
- [ ] `evt_write_req`
- [ ] `evt_stall`
- [ ] `wbuf_empty`
- [ ] Read/write op visible through wrapper request.
- [ ] Load miss/refill occurs.
- [ ] Load hit or post-refill response occurs.
- [ ] Dirty victim / write-back activity visible when eviction occurs.
- [ ] Valid/dirty/tag update if accessible in `dcache_i`.

## G. VBUF

- [ ] `vbuf_valid` if accessible in `dcache_i`
- [ ] `vbuf_full` if accessible in `dcache_i`
- [ ] `vbuf_alloc` if accessible in `dcache_i`
- [ ] `vbuf_pop` if accessible in `dcache_i`
- [ ] `vbuf_inflight` if accessible in `dcache_i`
- [ ] `vbuf_writeback` if accessible in `dcache_i`
- [ ] `vbuf_addr` if accessible in `dcache_i`
- [ ] `vbuf_data` if accessible in `dcache_i`
- [ ] Write-back path reaches shared arbiter memory write channel.

## H. Arbiter / Shared Memory

- [ ] `ic_l1_read_req_valid`
- [ ] `ic_l1_read_req_ready`
- [ ] `ic_l1_read_req_addr`
- [ ] `ic_l1_read_rsp_valid`
- [ ] `ic_l1_read_rsp_ready`
- [ ] `ic_l1_read_rsp_data`
- [ ] `mem_req_read_valid`
- [ ] `mem_req_read_ready`
- [ ] `mem_req_read_addr`
- [ ] `mem_resp_read_valid`
- [ ] `mem_resp_read_ready`
- [ ] `mem_resp_read_data`
- [ ] `mem_req_write_valid`
- [ ] `mem_req_write_ready`
- [ ] `mem_req_write_addr`
- [ ] `mem_req_write_data_valid`
- [ ] `mem_req_write_data_ready`
- [ ] `mem_req_write_data`
- [ ] `mem_resp_write_valid`
- [ ] `mem_resp_write_ready`
- [ ] `arb_state`
- [ ] I-Cache read miss grant.
- [ ] D-Cache read/refill grant.
- [ ] D-Cache/VBUF write-back grant.
- [ ] Memory read response returns correct cache line.
- [ ] Memory write response completes.

## I. Counters

- [ ] `cycle_count`
- [ ] `instr_access_count`
- [ ] `icache_miss_count`
- [ ] `icache_refill_count`
- [ ] `core_load_count`
- [ ] `core_store_count`
- [ ] `mem_read_count`
- [ ] `mem_write_count`
- [ ] `read_miss_count`
- [ ] `write_miss_count`
- [ ] `dcache_miss_count`
- [ ] `arb_icache_read_count`
- [ ] `arb_dcache_read_count`
- [ ] `arb_dcache_write_count`

## Basic Pass Expectations

- [ ] PASS marker appears in `10_full_l1_basic.log`.
- [ ] No timeout.
- [ ] No severe X/Z on control handshakes.
- [ ] I-Cache miss count is nonzero.
- [ ] I-Cache refill count is nonzero.
- [ ] D-Cache load/store counts are nonzero.
- [ ] DONE marker store occurs.
- [ ] Waveform file is generated.
