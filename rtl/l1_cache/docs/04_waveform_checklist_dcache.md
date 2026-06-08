# 04 - Waveform Checklist D-Cache

Date: 2026-05-26

Use this checklist with the passing Phase 3 waveform:

```text
rtl/l1_cache/work/waves/03_cv32_dcache_basic.vcd
```

GTKWave command in Ubuntu:

```bash
ROOT_WORKSPACE=$(find /media -maxdepth 8 -type d -name "cv32e40p-master" 2>/dev/null | grep "/work/" | head -n 1)
gtkwave "$ROOT_WORKSPACE/rtl/l1_cache/work/waves/03_cv32_dcache_basic.vcd" \
        "$ROOT_WORKSPACE/rtl/l1_cache/work/waves/dcache_basic.gtkw" &
```

## A. Clock / Reset

Signals:

- `tb_cv32e40p_dcache_basic.dut.clk`
- `tb_cv32e40p_dcache_basic.dut.rst_n`
- `tb_cv32e40p_dcache_basic.dut.fetch_enable`
- `tb_cv32e40p_dcache_basic.dut.core_i.boot_addr_i`

Check:

- Reset starts asserted and deasserts cleanly.
- `fetch_enable` goes high after reset.
- No persistent X/Z after reset release.

## B. CV32E40P Instruction Path

Signals:

- `tb_cv32e40p_dcache_basic.dut.instr_req`
- `tb_cv32e40p_dcache_basic.dut.instr_gnt`
- `tb_cv32e40p_dcache_basic.dut.instr_rvalid`
- `tb_cv32e40p_dcache_basic.dut.instr_addr`
- `tb_cv32e40p_dcache_basic.dut.instr_rdata`

Check:

- `instr_req` receives `instr_gnt`.
- `instr_rvalid` returns after fetch request.
- `instr_addr` advances through the small test program.

## C. CV32E40P Data Path

Signals:

- `tb_cv32e40p_dcache_basic.dut.data_req`
- `tb_cv32e40p_dcache_basic.dut.data_gnt`
- `tb_cv32e40p_dcache_basic.dut.data_rvalid`
- `tb_cv32e40p_dcache_basic.dut.data_we`
- `tb_cv32e40p_dcache_basic.dut.data_be`
- `tb_cv32e40p_dcache_basic.dut.data_addr`
- `tb_cv32e40p_dcache_basic.dut.data_wdata`
- `tb_cv32e40p_dcache_basic.dut.data_rdata`
- `tb_cv32e40p_dcache_basic.dut.data_err`

Check:

- Every CV32 data request is eventually granted.
- Loads receive `data_rvalid` and `data_rdata`.
- Stores are accepted and the final DONE store is observed.

## D. Adapter

Signals:

- `tb_cv32e40p_dcache_basic.dut.adapter_i.cv32_data_req_i`
- `tb_cv32e40p_dcache_basic.dut.adapter_i.cv32_data_gnt_o`
- `tb_cv32e40p_dcache_basic.dut.adapter_i.cv32_data_rvalid_o`
- `tb_cv32e40p_dcache_basic.dut.adapter_i.hpdcache_req_valid_o`
- `tb_cv32e40p_dcache_basic.dut.adapter_i.hpdcache_req_ready_i`
- `tb_cv32e40p_dcache_basic.dut.adapter_i.hpdcache_rsp_valid_i`
- `tb_cv32e40p_dcache_basic.dut.adapter_i.state_q`
- `tb_cv32e40p_dcache_basic.dut.adapter_i.outstanding_tid_q`

Check:

- Adapter holds one outstanding request at a time.
- `state_q` moves through idle/send/wait response and returns idle.
- CV32 `data_gnt` is aligned to HPDCache request accept.
- HPDCache response becomes CV32 `data_rvalid`.

## E. HPDCache

Signals:

- `tb_cv32e40p_dcache_basic.dut.dcache_i.req_valid_i`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.req_ready_o`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.rsp_valid_o`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.core_req_valid[0]`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.core_req_ready[0]`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.core_rsp_valid[0]`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.evt_cache_read_miss_o`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.evt_cache_write_miss_o`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.refill_req_valid`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.refill_req_ready`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.refill_write_dir`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.refill_write_data`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.miss_mshr_alloc`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.miss_mshr_alloc_dirty`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.miss_mshr_alloc_wback`

Check:

- Load/store miss events match memory refill activity.
- Refill writes data and directory/tag state.
- Dirty/wback metadata appears when eviction path is exercised.

## F. VBUF

Signals:

- `tb_cv32e40p_dcache_basic.dut.dcache_i.ctrl_vbuf_alloc`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.ctrl_vbuf_alloc_nline`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.ctrl_vbuf_alloc_set`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.ctrl_vbuf_alloc_way`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.ctrl_vbuf_safe_consume`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.vbuf_empty`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.vbuf_full`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.vbuf_busy`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.vbuf_drain`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.vbuf_entry_ready`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.vbuf_safe_to_overwrite`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.vbuf_capture_pending`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.vbuf_writeback_done`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.vbuf_alloc_ready`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.vbuf_data_capture`
- `tb_cv32e40p_dcache_basic.dut.dcache_i.vbuf_capture_done`

Check:

- `ctrl_vbuf_alloc` occurs on dirty victim capture.
- VBUF becomes non-empty/busy during capture and returns empty after drain.
- `vbuf_drain` or `vbuf_writeback_done` lines up with memory write-back completion.
- No repeated infinite alloc/write-back loop.

## G. Memory Side

Signals:

- `tb_cv32e40p_dcache_basic.dut.mem_req_read_valid`
- `tb_cv32e40p_dcache_basic.dut.mem_req_read_ready`
- `tb_cv32e40p_dcache_basic.dut.mem_req_read_addr`
- `tb_cv32e40p_dcache_basic.dut.mem_resp_read_valid`
- `tb_cv32e40p_dcache_basic.dut.mem_resp_read_ready`
- `tb_cv32e40p_dcache_basic.dut.mem_resp_read_data`
- `tb_cv32e40p_dcache_basic.dut.mem_resp_read_last`
- `tb_cv32e40p_dcache_basic.dut.mem_req_write_valid`
- `tb_cv32e40p_dcache_basic.dut.mem_req_write_ready`
- `tb_cv32e40p_dcache_basic.dut.mem_req_write_addr`
- `tb_cv32e40p_dcache_basic.dut.mem_req_write_data_valid`
- `tb_cv32e40p_dcache_basic.dut.mem_req_write_data_ready`
- `tb_cv32e40p_dcache_basic.dut.mem_req_write_data`
- `tb_cv32e40p_dcache_basic.dut.mem_req_write_be`
- `tb_cv32e40p_dcache_basic.dut.mem_req_write_last`
- `tb_cv32e40p_dcache_basic.dut.mem_resp_write_valid`
- `tb_cv32e40p_dcache_basic.dut.mem_resp_write_ready`

Check:

- Read request/response IDs and timing are consistent.
- Write address, write data, and write response complete once per write-back.
- Byte enables are correct for 128-bit line write-back.

## H. Performance / Debug Counters

Signals:

- `tb_cv32e40p_dcache_basic.dut.cycle_count`
- `tb_cv32e40p_dcache_basic.dut.core_load_count`
- `tb_cv32e40p_dcache_basic.dut.core_store_count`
- `tb_cv32e40p_dcache_basic.dut.mem_read_count`
- `tb_cv32e40p_dcache_basic.dut.mem_write_count`
- `tb_cv32e40p_dcache_basic.dut.read_miss_count`
- `tb_cv32e40p_dcache_basic.dut.write_miss_count`
- `tb_cv32e40p_dcache_basic.dut.done`
- `tb_cv32e40p_dcache_basic.dut.pass`

Expected latest Phase 3 result:

```text
cycles=90 loads=3 stores=5 mem_reads=5 mem_writes=2 read_miss=5 write_miss=4
```

Check:

- `done` and `pass` assert once.
- Counters stop at the PASS values above.
- `mem_write_count` remains small; it must not repeat hundreds of times.
