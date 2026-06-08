# 02 - Adapter Design Result

Date: 2026-05-26

## Goal

Create a conservative bridge from the CV32E40P data port to a single-requester
HPDCache request/response channel.

## Adapter

File:

```text
rtl/l1_cache/work/rtl/cv32_data_to_hpdcache_adapter.sv
```

Core-side interface:

- `cv32_data_req_i`
- `cv32_data_gnt_o`
- `cv32_data_rvalid_o`
- `cv32_data_we_i`
- `cv32_data_be_i`
- `cv32_data_addr_i`
- `cv32_data_wdata_i`
- `cv32_data_rdata_o`
- `cv32_data_err_o`

HPDCache-side abstract interface:

- `hpdcache_req_valid_o`
- `hpdcache_req_ready_i`
- `hpdcache_req_o`
- `hpdcache_rsp_valid_i`
- `hpdcache_rsp_i`

## State Machine

The adapter has three states:

- `ST_IDLE`: ready to accept one CV32 data request.
- `ST_SEND`: holds a buffered HPDCache request until `hpdcache_req_ready_i`.
- `ST_WAIT_RSP`: waits for HPDCache response and then asserts CV32 `data_rvalid`.

The adapter supports one outstanding request at a time for first bring-up.

## Handshake Mapping

CV32 request accept:

```text
cv32_accept = cv32_data_req_i & cv32_data_gnt_o
```

HPDCache request fire:

```text
req_fire = req_buf_valid_q & hpdcache_req_ready_i
```

HPDCache response fire:

```text
rsp_fire = hpdcache_rsp_valid_i & (state_q == ST_WAIT_RSP)
```

`cv32_data_gnt_o` is generated from the adapter idle state and does not depend
combinationally on HPDCache `req_ready`. This avoids a ready/valid loop through
CV32 LSU, adapter, and HPDCache.

## Field Mapping

| CV32 field | HPDCache request field |
|---|---|
| `data_we = 0` | load op |
| `data_we = 1` | store op |
| `data_addr` | `addr` |
| `data_wdata` | `wdata` |
| `data_be` | `be` |
| `data_be` | `size` derived as 1B/2B/4B |
| fixed | `sid = 0` |
| counter | `tid` |
| fixed | `need_rsp = 1` |
| fixed | `phys_indexed = 1` |
| PMA | high address nibble nonzero is treated as MMIO/uncacheable |

## Test Result

Adapter TB:

```text
rtl/l1_cache/work/tb/tb_cv32_dcache_adapter_basic.sv
```

Log:

```text
rtl/l1_cache/logs/02_adapter_basic.log
```

Wave:

```text
rtl/l1_cache/work/waves/02_adapter_basic.vcd
```

Covered checks:

- load miss style delayed response
- load hit style short response
- store hit word
- load after store hit
- store miss/write-allocate style delayed ack
- load after delayed store
- byte-enable store byte lane 1
- load after byte-enable store

Final expected marker:

```text
[PHASE2][PASS] adapter basic completed 8 checks
```

Observed Ubuntu result:

```text
[MAKE_STATUS] 0
[PHASE2][PASS] adapter basic completed 8 checks
```

Simulator backend:

```text
Verilator
```

The run script was updated to use Questa/ModelSim when available and otherwise
fall back to Verilator, matching the Ubuntu tool availability.

## Risks

- Current adapter is intentionally one-outstanding only.
- Store response is required because CV32 LSU needs `data_rvalid` to close the
  transaction.
- HPDCache op/size/PMA typedefs are wrapped in `cv32_hpdcache_if_pkg.sv`; keep
  this package aligned with the real HPDCache package.
- If HPDCache supports multiple requester responses out of order later, adapter
  response matching must be expanded.

## Phase 2 Summary

Files read:

- `rtl/l1_cache/logs/error.log`
- `rtl/l1_cache/logs/02_adapter_basic.log`
- `rtl/l1_cache/work/rtl/cv32_hpdcache_if_pkg.sv`
- `rtl/l1_cache/work/rtl/cv32_data_to_hpdcache_adapter.sv`
- `rtl/l1_cache/work/rtl/hpdcache_cv32_wrapper.sv`
- `rtl/l1_cache/work/tb/tb_cv32_dcache_adapter_basic.sv`
- `rtl/l1_cache/work/sim/adapter_basic.f`
- `rtl/l1_cache/work/sim/run_adapter_basic.sh`
- `rtl/l1_cache/work/hpdcache_patched/src/hpdcache.sv`

Files created/modified:

- Modified `rtl/l1_cache/work/sim/env_ubuntu.sh`
- Modified `rtl/l1_cache/work/sim/run_adapter_basic.sh`
- Modified `rtl/l1_cache/work/tb/tb_cv32_dcache_adapter_basic.sv`
- Updated `rtl/l1_cache/docs/02_adapter_design_result.md`
- Generated `rtl/l1_cache/logs/02_adapter_basic.log`
- Generated `rtl/l1_cache/work/waves/02_adapter_basic.vcd`

Commands run:

- `make -C rtl/l1_cache/work/sim run_adapter_basic`

Pass/fail:

- Pass

Main error fixed:

- The first Verilator adapter run timed out because the testbench sampled the
  combinational `cv32_data_gnt` handshake at a clock edge and could miss the
  accept cycle. The task `drive_req` now drives at `negedge clk`, waits for the
  combinational grant, and then deasserts the request after the accepted clock.

Next step:

- Phase 3 precheck: inspect full CV32E40P + adapter + HPDCache integration
  files and run scripts before attempting the full D-cache simulation.
