# Phase 2 - CV32 Data to HPDCache Adapter Basic Result

Date: 2026-05-26

## Goal

Create and unit-test a small adapter that converts the CV32E40P data interface
into a single-requester HPDCache-style request/response channel.

This phase does not modify CV32E40P original RTL and does not modify the
HPDCache source tree.

## Files Created

- `rtl/l1_cache/work/rtl/cv32_hpdcache_if_pkg.sv`
- `rtl/l1_cache/work/rtl/cv32_data_to_hpdcache_adapter.sv`
- `rtl/l1_cache/work/rtl/hpdcache_cv32_wrapper.sv`
- `rtl/l1_cache/work/tb/tb_cv32_dcache_adapter_basic.sv`
- `rtl/l1_cache/work/sim/adapter_basic.f`
- `rtl/l1_cache/work/sim/run_adapter_basic.ps1`
- `rtl/l1_cache/logs/02_adapter_basic.log`
- `rtl/l1_cache/work/waves/02_adapter_basic.vcd`

## Adapter Behavior

Adapter module:

`cv32_data_to_hpdcache_adapter`

Core-side signals:

- `cv32_data_req_i`
- `cv32_data_gnt_o`
- `cv32_data_rvalid_o`
- `cv32_data_we_i`
- `cv32_data_be_i`
- `cv32_data_addr_i`
- `cv32_data_wdata_i`
- `cv32_data_rdata_o`
- `cv32_data_err_o`

HPDCache-side abstract requester signals:

- `hpdcache_req_valid_o`
- `hpdcache_req_ready_i`
- `hpdcache_req_o`
- `hpdcache_rsp_valid_i`
- `hpdcache_rsp_i`

The adapter is intentionally conservative:

- One outstanding request at a time.
- CV32 request is captured into a one-entry skid buffer when the adapter is idle.
- `data_gnt` no longer depends combinationally on HPDCache `req_ready`; this cuts the
  CV32 LSU -> adapter -> HPDCache -> adapter -> CV32 LSU ready/valid loop.
- The buffered request is sent to HPDCache after capture and held until
  `hpdcache_req_ready_i`.
- `tid` increments per accepted request.
- `need_rsp = 1'b1` for both load and store so the CV32 LSU sees a closing
  `data_rvalid`.
- Cacheable requests default to write-back policy hint.
- `cv32_data_err_o` is exposed for integration/debug, but `cv32e40p_top` has no
  data error input in this codebase.

## Mapping

| CV32E40P data field | Adapter / HPDCache-style field |
|---|---|
| `data_we == 0` | `CV32_HPDCACHE_REQ_LOAD` |
| `data_we == 1` | `CV32_HPDCACHE_REQ_STORE` |
| `data_addr` | `req.addr` |
| `data_wdata` | `req.wdata` |
| `data_be` | `req.be` |
| `data_be` | `req.size`: 1B/2B/4B derived from byte-enable pattern |
| fixed | `sid = 0` |
| counter | `tid` |
| fixed | `need_rsp = 1` |
| fixed | `phys_indexed = 1` |
| fixed | `pma.uncacheable = 0`, `pma.io = 0`, `wr_policy_hint = WB` |
| response | `data_rvalid`, `data_rdata`, `data_err` |

## Testbench

Testbench:

`rtl/l1_cache/work/tb/tb_cv32_dcache_adapter_basic.sv`

The TB uses a fake HPDCache responder so the adapter can be tested without
mixing in HPDCache refill/VBUF behavior yet.

Covered checks:

1. Load miss style delayed response
2. Load hit style short response
3. Store hit word
4. Load after store hit
5. Store miss/write-allocate style delayed ack
6. Load after delayed store
7. Byte-enable store on byte lane 1
8. Load after byte-enable store

Important log line:

```text
[PHASE2][PASS] adapter basic completed 8 checks
```

## Result

Pass.

Compile:

- `vlog` completed with `Errors: 0, Warnings: 0`

Simulation:

- `vsim` completed with `Errors: 0, Warnings: 0`
- Waveform generated at `rtl/l1_cache/work/waves/02_adapter_basic.vcd`

## Wrapper Note

Created `rtl/l1_cache/work/rtl/hpdcache_cv32_wrapper.sv` as the next integration
layer. It instantiates the real `hpdcache` module with a small CV32-oriented
32-bit requester / 128-bit memory-data configuration:

- 32-bit physical address
- 32-bit requester word
- 4 words per cache line
- 16 sets
- 2 ways
- write-back enabled
- ECC scrubber disabled for first bring-up

This wrapper has not yet been fully validated against the HPDCache RTL compile
in Phase 2. It is staged for Phase 3 integration and compile cleanup.

## Phase 2 Summary

Files read:

- `rtl/l1_cache/hpdcache/cv-hpdcache/rtl/src/hpdcache_pkg.sv`
- `rtl/l1_cache/hpdcache/cv-hpdcache/rtl/include/hpdcache_typedef.svh`
- `rtl/l1_cache/hpdcache/cv-hpdcache/rtl/src/hpdcache.sv`
- `rtl/l1_cache/hpdcache/cv-hpdcache/rtl/tb/hpdcache_wrapper.sv`
- `rtl/l1_cache/logs/02_adapter_basic.log`

Files created/modified:

- Created `rtl/l1_cache/work/rtl/cv32_hpdcache_if_pkg.sv`
- Created `rtl/l1_cache/work/rtl/cv32_data_to_hpdcache_adapter.sv`
- Created `rtl/l1_cache/work/rtl/hpdcache_cv32_wrapper.sv`
- Created `rtl/l1_cache/work/tb/tb_cv32_dcache_adapter_basic.sv`
- Created `rtl/l1_cache/work/sim/adapter_basic.f`
- Created `rtl/l1_cache/work/sim/run_adapter_basic.ps1`
- Created `rtl/l1_cache/logs/02_adapter_basic.log`
- Created `rtl/l1_cache/work/waves/02_adapter_basic.vcd`
- Created `rtl/l1_cache/docs/02_adapter_basic_result.md`
- Modified `rtl/l1_cache/work/rtl/cv32_data_to_hpdcache_adapter.sv` to add the
  one-entry request skid buffer.
- Modified `rtl/l1_cache/work/tb/tb_cv32_dcache_adapter_basic.sv` to check
  HPDCache request mapping when the buffered request fires.

Commands run:

- `rg -n` searches for HPDCache request size behavior
- `powershell -ExecutionPolicy Bypass -File .\run_adapter_basic.ps1`

Pass/fail:

- Pass.

Main errors:

- None in final adapter compile/sim.

Next step:

- Phase 3: compile HPDCache with the CV32 wrapper, create
  `cv32e40p_l1_dcache_top.sv`, connect the CV32 data path through the adapter
  and HPDCache wrapper, and bring up a basic core-level D-cache test.
