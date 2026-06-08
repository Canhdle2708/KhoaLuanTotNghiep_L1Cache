# 02 - Waveform Checklist D-Cache

Mục tiêu của waveform đầu tiên là chứng minh core fetch được lệnh, data request đi qua adapter, HPDCache nhận request, memory-side có refill/write-back, và VBUF hoạt động đúng khi dirty victim xuất hiện.

## A. Clock/reset

- `clk`
- `rst_n` hoặc `rst_ni`
- `fetch_enable`
- `boot_addr_i`
- `core_sleep_o`

Pass cơ bản: reset assert/deassert sạch, không có X/Z kéo dài sau reset, core bắt đầu fetch khi `fetch_enable=1`.

## B. CV32E40P instruction path

- `instr_req`
- `instr_gnt`
- `instr_rvalid`
- `instr_addr`
- `instr_rdata`

Pass cơ bản: `instr_req` được grant, `instr_rvalid` trả về sau latency memory, `instr_addr` tăng theo chương trình, không bị treo ở reset vector.

## C. CV32E40P data path

- `data_req`
- `data_gnt`
- `data_rvalid`
- `data_we`
- `data_be`
- `data_addr`
- `data_wdata`
- `data_rdata`
- `data_err` nếu có trong wrapper/adapter debug

Pass cơ bản: mỗi load/store có grant đúng protocol; load nhận `rvalid`; store không làm core treo; byte enable đúng kích thước access.

## D. Adapter

- CV32 request accepted: `cv32_data_req_i`, `cv32_data_gnt_o`
- Translated HPDCache request: `hpdcache_req_valid_o`, `hpdcache_req_ready_i`
- Outstanding state: state machine `ST_IDLE/ST_WAIT_RSP`
- TID/SID: `outstanding_tid_o`, request `tid`, response `tid`
- Response path: `hpdcache_rsp_valid_i`, `cv32_data_rvalid_o`, `cv32_data_rdata_o`
- Load/store FSM: `cv32_data_we_i`, translated `op`, `be`, `size`

Pass cơ bản: adapter chỉ giữ một outstanding request, không mất response, store/load đều sinh response cho CV32.

## E. HPDCache

- Request valid/ready: `core_req_valid`, `core_req_ready`
- Read/write op: request `op`
- Hit/miss indication: `evt_cache_read_miss_o`, `evt_cache_write_miss_o`
- Refill request: memory read request valid/ready/address/ID/len/size
- Refill response: memory read response valid/ready/data/last/error
- Victim way: victim select output trong miss handler/controller
- Dirty victim: dirty bit, victim dirty path
- Write-back request: memory write address/data/byte-enable/response
- CMO/flush nếu dùng: CMO request, flush FIFO, flush done

Pass cơ bản: load miss tạo refill, load hit không tạo memory read mới, dirty eviction tạo write-back.

## F. VBUF

- `vbuf_valid`
- `vbuf_ready`
- `vbuf_full`
- `vbuf_alloc`
- `vbuf_pop` hoặc writeback pop
- `vbuf_pending`
- `vbuf_inflight`
- `vbuf_addr`
- `vbuf_data`
- `vbuf_hit` nếu design hỗ trợ reload/hit trong VBUF
- `safe_to_overwrite` hoặc signal tương đương nếu có

Pass cơ bản: dirty victim được capture vào VBUF trước khi refill overwrite line cũ; VBUF drain khi memory-side rảnh; full phải back-pressure thay vì làm mất dirty line.

## G. Memory side

- Memory read request: `mem_req_read_valid`, `mem_req_read_ready`, `mem_req_read_addr`
- Memory read response: `mem_resp_read_valid`, `mem_resp_read_ready`, `mem_resp_read_data`, `mem_resp_read_last`
- Memory write request: `mem_req_write_valid`, `mem_req_write_ready`, `mem_req_write_addr`
- Memory write data: `mem_req_write_data_valid`, `mem_req_write_data_ready`, `mem_req_write_data`, `mem_req_write_be`, `mem_req_write_last`
- Memory write response: `mem_resp_write_valid`, `mem_resp_write_ready`, `mem_resp_write_error`
- Arbiter grant nếu có: read miss vs VBUF write-back priority/grant

Pass cơ bản: không mất request dưới backpressure, read/write IDs khớp response, write-back data/BE đúng line dirty.
