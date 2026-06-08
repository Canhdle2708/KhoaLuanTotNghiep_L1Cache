# TESTPLAN Full L1 CV32E40P With CVA6 I-Cache And HPDCache

## Scope

This testplan verifies the integrated L1 subsystem:

- CV32E40P instruction port through real CVA6 I-Cache.
- CV32E40P data port through HPDCache full WB/VBUF path.
- Shared L1 memory arbiter for I-Cache refill, D-Cache refill/read, and D-Cache/VBUF write-back.
- Shared memory model functional behavior.
- Basic and random smoke simulation flow.

## Current Validated Smoke Results

| Flow | Target | Status | Main Evidence |
|---|---|---:|---|
| Basic full L1 | `make HPDCACHE_SRC_MODE=base run_full_l1_basic` | PASS | `ic_miss=5`, `ic_refill=5`, `loads=3`, `stores=5`, `mem_reads=10`, `mem_writes=2` |
| Random seed 1 | `make HPDCACHE_SRC_MODE=base run_full_l1_random SEEDS="1"` | PASS | `ic_miss=15`, `ic_refill=15`, `loads=12`, `stores=17` |
| Random seed 2 | `make HPDCACHE_SRC_MODE=base run_full_l1_random SEEDS="2"` | PASS | `ic_miss=15`, `ic_refill=15`, `loads=12`, `stores=17` |
| Random seed 3 | `make HPDCACHE_SRC_MODE=base run_full_l1_random SEEDS="3"` | PASS | `ic_miss=15`, `ic_refill=15`, `loads=12`, `stores=17` |

## Test Matrix

| ID | Scenario | Mục tiêu | Stimulus | Expected behavior | Signal cần xem | Pass/fail criteria | Counter liên quan |
|---|---|---|---|---|---|---|---|
| FL1_BASIC_001 | Basic full L1 integration | Chứng minh CV32E40P fetch qua CVA6 I-Cache và data qua HPDCache | Run `run_full_l1_basic`; program fetch, load, store, DONE marker | Fetch tạo I-Cache miss/refill, data path có load/store, DONE store xuất hiện | `instr_req/gnt/rvalid/addr/rdata`, `icache_miss`, `mem_*`, `data_*`, `done` | PASS marker, không timeout, không fatal | `cycle_count`, `instr_access_count`, `icache_miss_count`, `icache_refill_count`, `core_load_count`, `core_store_count` |
| FL1_IC_001 | I-Cache first fetch miss/refill | Xác nhận fetch đầu tiên không bypass cache | Start at `BOOT_ADDR=0x80000000` with cold I-Cache | I-Cache requests refill before returning instruction | `icache_dreq`, `icache_drsp`, `icache_mem_data_req`, `icache_mem_rtrn_vld` | `icache_miss_count > 0` and `icache_refill_count > 0` | `icache_miss_count`, `icache_refill_count`, `arb_icache_read_count` |
| FL1_IC_002 | I-Cache sequential fetch after refill | Xác nhận instruction stream tiếp tục sau refill | Program has sequential instructions across multiple lines | CV32 receives valid instruction data in order | `instr_addr`, `instr_rdata`, `instr_response_valid`, `icache_drsp.valid` | Program reaches DONE without illegal fetch trap or timeout | `instr_access_count`, `cycle_count` |
| FL1_IC_003 | Identity translation | Xác nhận virtual fetch maps identity to physical fetch | Fetch addresses from `0x80000000` | `fetch_paddr = fetch_vaddr`, exception zero | `icache_addr_req.fetch_vaddr`, `icache_addr_rsp.fetch_paddr`, `fetch_exception.valid` | No translation exception, instruction data matches program | `instr_access_count`, `icache_miss_count` |
| FL1_IC_004 | I-Cache flush/fence.i readiness | Chuẩn bị test nếu flush/fence.i được kích hoạt sau | Assert `flush_i` or execute fence.i when supported by wrapper/TB | Cache invalidates and refetches cleanly | `flush_i`, `icache_miss`, tag valid bits if accessible | Refetch after flush returns correct instruction | `icache_miss_count`, `icache_refill_count` |
| FL1_DC_001 | D-Cache load miss/refill | Xác nhận load lần đầu đi qua HPDCache refill | Basic/random program loads from initialized addresses | HPDCache issues read request to arbiter, response returns data | `data_req/gnt/rvalid`, `mem_req_read_*`, `mem_resp_read_*`, `evt_cache_read_miss` | Load returns expected data, no data error | `core_load_count`, `read_miss_count`, `mem_read_count` |
| FL1_DC_002 | D-Cache load hit/post-refill response | Xác nhận load sau refill tiếp tục đúng | Repeat load to same or nearby line | Load completes without deadlock and returns stable data | `data_rvalid`, `cache_rsp_valid`, HPD hit signal if accessible | Data response matches expected value | `core_load_count`, `dcache_miss_count` |
| FL1_DC_003 | D-Cache store dirty | Xác nhận store đi qua HPDCache và tạo dirty line | Stores to `0x100`, `0x200`, `0x300` style addresses | Store accepted, line becomes dirty if cacheable | `data_we`, `data_addr`, `data_wdata`, dirty bits if accessible | Store is granted and later load/write-back observes data | `core_store_count`, `write_miss_count` |
| FL1_WB_001 | Dirty write-back / VBUF path | Xác nhận dirty victim write-back ra arbiter | Use conflict/pressure addresses or random smoke stores | HPDCache/VBUF produces memory write request/data/response | `mem_req_write_*`, `mem_req_write_data_*`, `mem_resp_write_*`, VBUF signals if accessible | `mem_write_count > 0`, write response completes | `mem_write_count`, `arb_dcache_write_count` |
| FL1_VBUF_001 | VBUF allocation and drain | Xác nhận VBUF không bị kẹt | Store pressure with evictions | VBUF allocates, eventually pops/writebacks | `vbuf_valid`, `vbuf_full`, `vbuf_alloc`, `vbuf_pop`, `vbuf_inflight` if accessible | No full-stall deadlock, DONE reached | `mem_write_count`, `cycle_count` |
| FL1_ARB_001 | I-Cache vs D-Cache read contention | Xác nhận arbiter chia sẻ memory giữa I/D read | Program with instruction misses while D loads occur | Both I and D read requests receive service | `ic_l1_read_req_*`, `mem_req_read_*`, `arb_state` | No starvation, both read counters increase | `arb_icache_read_count`, `arb_dcache_read_count`, `mem_read_count` |
| FL1_ARB_002 | D write-back lower priority but no starvation | Xác nhận write-back không chặn read miss và không mất response | Dirty write-back plus I/D read pressure | Reads make progress, writes eventually complete | `mem_req_write_*`, `mem_resp_write_*`, `arb_state` | DONE reached, write response observed | `arb_dcache_write_count`, `mem_write_count` |
| FL1_RST_001 | Reset clean startup | Xác nhận reset đưa cache/adapters/top về state sạch | Apply reset, then fetch enable | No stale valid response before fetch, first access deterministic | `rst_n`, adapter states, cache valid/ready signals | No X/Z severe, first fetch reaches I-Cache | `cycle_count`, `instr_access_count` |
| FL1_RANDOM_001 | Random smoke seeds | Chạy mixed instruction/data pressure nhẹ | `make HPDCACHE_SRC_MODE=base run_full_l1_random SEEDS="1 2 3"` | All seeds reach DONE, no timeout | Same as basic plus per-seed logs | PASS marker for each seed | `icache_miss_count`, `core_load_count`, `core_store_count`, `mem_read_count`, `mem_write_count` |
| FL1_PERF_001 | Performance measurement baseline | Thu thập baseline counters sau khi functional pass | Reuse basic/random flows | Counters are stable and comparable across runs | All counters listed in waveform checklist | Report cycles/misses/refills, no new functional fail | All exposed counters |

## Required Logs And Artifacts

| Artifact | Path |
|---|---|
| Main integration log | `$L1_ROOT/logs/icache_full_integration_error.log` |
| Basic full L1 log | `$L1_ROOT/logs/10_full_l1_basic.log` |
| Random seed 1 log | `$L1_ROOT/logs/11_full_l1_random_seed_1.log` |
| Random seed 2 log | `$L1_ROOT/logs/11_full_l1_random_seed_2.log` |
| Random seed 3 log | `$L1_ROOT/logs/11_full_l1_random_seed_3.log` |
| Basic waveform | `$WORK_ROOT/waves/full_l1_basic.vcd` |
| Random seed 1 waveform | `$WORK_ROOT/waves/full_l1_random_seed_1.vcd` |
| Waveform checklist | `$L1_ROOT/docs/13_waveform_checklist_full_l1.md` |

## Pass Criteria Summary

- I-Cache DUT is the real CVA6 I-Cache source from `$ICACHE_ROOT/rtl/cva6_icache.sv`.
- Instruction path is `CV32E40P instr port -> adapter -> CVA6 I-Cache -> memory adapter -> arbiter -> memory`.
- No instruction memory bypass exists in full L1 top.
- HPDCache full source mode is `base` unless deliberately changed by test command.
- Basic full L1 reaches DONE with I-Cache miss/refill and D-Cache load/store.
- Random smoke seeds `1 2 3` reach DONE without timeout.
- Waveforms are generated for basic and random seed 1.
- No severe X/Z appears on reset, valid/ready, request/response, or DONE control paths.
