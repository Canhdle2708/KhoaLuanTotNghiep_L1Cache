# 02 - Hướng dẫn xem waveform WB + VBUF owner mode

GTKWave file chính:

- `rtl/tb/scripts/gtkwave/wb_all_cases_one_file.gtkw`

VCD mà file đang trỏ tới:

- `/media/sf_cv-hpdcache/rtl/tb/logs/run_unique_set_42_cleanwave.vcd`

Nếu VCD nằm ở repo Windows hiện tại, mở lại bằng file VCD tương ứng trong
`rtl/tb/logs/`.

## Map case yêu cầu sang nhóm thực tế trong `.gtkw`

| Case yêu cầu | Nhóm trong `.gtkw` | Ghi chú |
|---|---|---|
| CASE A - Store hit write-back | `CASE 1 - WB store hit` | Kiểm tra store hit set dirty, không WBUF/memory write ngay |
| CASE B - Read miss victim invalid/clean | Một phần trong `CASE 2 - WB store miss / write-allocate` + cần nhìn load miss bằng `st1_req_is_load` | `.gtkw` chưa tách riêng read miss clean victim |
| CASE C - Write miss victim invalid/clean | `CASE 2 - WB store miss / write-allocate` | Kiểm tra MSHR/refill và dirty set sau store |
| CASE D - Read miss dirty victim | `CASE 3`, `CASE 4`, `CASE 5` | Dirty replacement owner flow chính |
| CASE E - Write miss dirty victim | `CASE 3`, `CASE 4`, `CASE 5`, và dirty replay ở `CASE 2` | Giống D cộng thêm line mới dirty |
| CASE F - VBUF full/backpressure | `CASE 3`, `CASE 4`, `CASE 6` | VBUF depth=1; xem alloc_ready/full/busy và RTAB/stall |
| CASE G - Forward/hazard line trong VBUF | `CASE 6`, `CASE 7` | Có forward interface Phase20B |
| CASE H - Explicit flush/clean/invalidate/CMO | `CASE 5` flush compare + cần thêm CMO group nếu muốn đầy đủ | `.gtkw` hiện đủ để thấy flush path không phải owner dirty replacement |

## CASE A - Store hit write-back

Mục tiêu: store cacheable hit trong WB mode chỉ cập nhật cache data + dirty bit,
không phát memory write ngay, không allocate VBUF.

### Signal cần zoom

- `st1_req_valid_q`
- `st1_req_is_store`
- `st1_req_is_uncacheable`
- `cachedir_hit_o`
- `st1_req_wr_wb`
- `st1_req_cachedata_write`
- `st1_req_cachedata_write_enable`
- `st2_dir_updt_valid_q`
- `st2_dir_updt_wback_q`
- `st2_dir_updt_dirty_q`
- `wbuf_write_o`
- `ctrl_vbuf_alloc`
- `mem_req_write_vbuf_valid`

### Thứ tự đúng theo thời gian

1. `st1_req_valid_q=1`, `st1_req_is_store=1`, `st1_req_is_uncacheable=0`.
2. `cachedir_hit_o=1`.
3. `st1_req_wr_wb=1`.
4. `st1_req_cachedata_write_enable=1` để ghi data array.
5. Một nhịp sau, `st2_dir_updt_valid_q=1`, `st2_dir_updt_wback_q=1`,
   `st2_dir_updt_dirty_q=1`.
6. `wbuf_write_o=0`, `ctrl_vbuf_alloc=0`, `mem_req_write_vbuf_valid=0`.

### Dấu hiệu đúng

- Store hit làm dirty bit lên 1.
- Không có VBUF alloc vì chưa eviction.
- Không có write memory ngay vì WB cache giữ dirty data.

### Dấu hiệu sai

- `wbuf_write_o=1` cho store hit WB: store đang bị đi WT/WBUF sai policy.
- `st2_dir_updt_dirty_q=0` sau store hit WB: mất dirty bit.
- `mem_req_write_vbuf_valid=1` hoặc `ctrl_vbuf_alloc=1`: VBUF bị dùng sai vì không có eviction.

### Module nghi ngờ nếu sai

- `hpdcache_ctrl_pe.sv`: quyết định store hit / dirty update / WBUF write.
- `hpdcache_ctrl.sv`: decode `st1_req_wr_*`, register metadata update.
- `hpdcache_memctrl.sv`: ghi data RAM / directory metadata.

## CASE B - Read miss với victim invalid/clean

Mục tiêu: read miss đi refill bình thường, không dirty victim, không cần VBUF.

### Signal cần zoom

- `st1_req_valid_q`
- `st1_req_is_load`
- `cachedir_hit_o`
- `st1_dir_victim_dirty_i`
- `st2_vbuf_alloc_o`
- `ctrl_vbuf_alloc`
- `st2_mshr_alloc_o`
- `st2_mshr_alloc_q`
- `mem_req_read_miss_valid`
- `mem_resp_read_miss_valid`
- `refill_write_data`
- `refill_write_dir`
- `refill_nline`

### Thứ tự đúng theo thời gian

1. Load cacheable vào ST1: `st1_req_is_load=1`, `cachedir_hit_o=0`.
2. Victim invalid/clean: `st1_dir_victim_dirty_i=0`.
3. Không VBUF: `st2_vbuf_alloc_o=0`, `ctrl_vbuf_alloc=0`.
4. Miss được cấp MSHR: `st2_mshr_alloc_o/q=1`.
5. Memory read refill: `mem_req_read_miss_valid` bắt tay với ready.
6. Memory response về: `mem_resp_read_miss_valid`.
7. Refill ghi data: `refill_write_data=1`.
8. Cuối line ghi metadata: `refill_write_dir=1`.

### Dấu hiệu đúng

- Refill xảy ra mà không cần `vbuf_capture_pending`.
- `mem_req_write_vbuf_valid=0` vì không có old dirty line.
- Dirty bit line mới sau read miss thường 0, còn wback tùy policy.

### Dấu hiệu sai

- `ctrl_vbuf_alloc=1` dù victim clean/invalid.
- `mem_req_write_vbuf_valid=1` dù không dirty victim.
- `refill_write_data` xảy ra trước khi miss read response hợp lệ.

### Module nghi ngờ nếu sai

- `hpdcache_memctrl.sv`: victim dirty/valid/tag decode.
- `hpdcache_ctrl_pe.sv`: miss path quyết định VBUF hoặc MSHR.
- `hpdcache_miss_handler.sv`: refill FSM.

## CASE C - Write miss với victim invalid/clean

Mục tiêu: store miss write-allocate refill line, sau store line mới dirty nếu WB.

### Signal cần zoom

- `st1_req_is_store`
- `cachedir_hit_o`
- `st1_req_wr_wb`
- `st1_dir_victim_dirty_i`
- `st2_mshr_alloc_wback_q`
- `st2_mshr_alloc_dirty_q`
- `miss_mshr_alloc`
- `mem_req_read_miss_valid`
- `refill_write_data`
- `refill_write_dir`
- `st1_req_cachedata_write_enable`
- `st2_dir_updt_dirty_q`
- `ctrl_vbuf_alloc`
- `mem_req_write_vbuf_valid`

### Thứ tự đúng theo thời gian

1. Store cacheable miss: `st1_req_is_store=1`, `cachedir_hit_o=0`.
2. Victim clean/invalid: `st1_dir_victim_dirty_i=0`.
3. Không allocate VBUF.
4. Allocate MSHR với `st2_mshr_alloc_wback_q=1`.
5. Với write-allocate WB, `st2_mshr_alloc_dirty_q=1` hoặc dirty data được giữ để merge vào refill.
6. Refill data về và ghi cache.
7. Store/replay làm `st2_dir_updt_dirty_q=1` cho line mới.

### Dấu hiệu đúng

- Không có VBUF write-back old line.
- Refill line mới xảy ra.
- Line mới dirty sau store WB.
- Store data không bị mất trong `refill_data`/data array.

### Dấu hiệu sai

- `st2_mshr_alloc_dirty_q=0` và sau đó dirty bit không set cho store miss WB.
- `wbuf_write_o=1` cho path đáng ra WB.
- `ctrl_vbuf_alloc=1` khi victim clean/invalid.

### Module nghi ngờ nếu sai

- `hpdcache_ctrl_pe.sv`: store miss dirty/wback decision.
- `hpdcache_miss_handler.sv`: CBUF merge dirty store data vào refill.
- `hpdcache_memctrl.sv`: dirty metadata write.

## CASE D - Read miss với dirty victim

Mục tiêu quan trọng nhất: dirty replacement eviction được VBUF owner capture,
cache chỉ refill/overwrite sau safe, và VBUF tự write-back old line.

### Signal cần zoom

Nhóm owner decision:

- `st1_dir_victim_dirty_i`
- `st1_vbuf_victim_safe_i`
- `st2_flush_alloc_o`
- `st2_vbuf_alloc_o`
- `st2_mshr_alloc_o`
- `ctrl_flush_alloc`
- `ctrl_vbuf_alloc`
- `st1_victim_nline`
- `ctrl_vbuf_alloc_nline`

Nhóm capture/safe:

- `vbuf_capture_pending`
- `vbuf_data_read`
- `vbuf_data_read_ready`
- `data_vbuf_read_accept`
- `vbuf_capture_done`
- `vbuf_safe_to_overwrite`
- `ctrl_vbuf_safe_consume`
- `vbuf_captured_nline`
- `vbuf_safe_nline`
- `victim_line_q[*]`

Nhóm refill/writeback:

- `st2_mshr_alloc_q`
- `mem_req_read_miss_valid`
- `refill_write_data`
- `refill_write_dir`
- `mem_req_write_vbuf_valid`
- `mem_req_write_vbuf.mem_req_addr`
- `mem_req_write_vbuf_data.mem_req_w_data`
- `mem_resp_write_vbuf_valid`
- `vbuf_writeback_done`

### Thứ tự đúng theo thời gian

1. Read miss chọn victim: `cachedir_hit_o=0`, `st1_dir_victim_dirty_i=1`.
2. Vì chưa safe: `st1_vbuf_victim_safe_i=0`.
3. Owner mode: `st2_vbuf_alloc_o=1`, còn `st2_flush_alloc_o=0`.
4. Top thấy `ctrl_vbuf_alloc=1`; `ctrl_vbuf_alloc_nline` bằng `st1_victim_nline`.
5. VBUF vào capture: `vbuf_capture_pending=1`.
6. VBUF đọc data RAM: `vbuf_data_read=1`; khi memctrl rảnh, `data_vbuf_read_accept=1`.
7. Dữ liệu cũ được lưu vào `victim_line_q`.
8. Capture đủ line: `vbuf_capture_done=1`, `vbuf_safe_to_overwrite=1`.
9. Ctrl consume safe: `ctrl_vbuf_safe_consume=1`.
10. Chỉ sau safe/consume, miss mới được MSHR/refill: `st2_mshr_alloc_q=1`, `mem_req_read_miss_valid=1`.
11. Refill ghi line mới: `refill_write_data`, `refill_write_dir`.
12. VBUF tự write-back old line: `mem_req_write_vbuf_valid`, `mem_req_write_vbuf_data_valid`.
13. Memory ack: `mem_resp_write_vbuf_valid`.
14. VBUF free/done: `vbuf_writeback_done=1`, sau đó `vbuf_empty=1`.

### Dấu hiệu đúng

- Dirty replacement không đi qua `ctrl_flush_alloc`.
- Refill không overwrite trước `vbuf_safe_to_overwrite`.
- Write-back address/data lấy từ old victim, không phải new refill line.

### Dấu hiệu sai

- `st2_mshr_alloc_o/q=1` trước khi `vbuf_safe_to_overwrite=1`.
- `st2_flush_alloc_o=1` cho dirty replacement owner path.
- `vbuf_capture_done` không lên nhưng refill vẫn xảy ra.
- `mem_req_write_vbuf.mem_req_addr` bằng địa chỉ line mới thay vì old victim.
- `vbuf_writeback_done` không bao giờ lên, VBUF kẹt full.

### Module nghi ngờ nếu sai

- `hpdcache_ctrl_pe.sv`: gating dirty victim before MSHR/refill.
- `hpdcache_vbuf.sv`: capture/safe/writeback FSM.
- `hpdcache_memctrl.sv`: data_vbuf_read arbitration/data mux.
- `hpdcache.sv`: write arbiter and write response demux.

## CASE E - Write miss với dirty victim

Mục tiêu: giống CASE D, nhưng line mới sau refill/store phải dirty và giữ đúng
store data.

### Signal cần zoom

Tất cả CASE D, thêm:

- `st1_req_is_store`
- `st1_req_wr_wb`
- `st2_mshr_alloc_dirty_q`
- `st2_mshr_alloc_wback_q`
- `refill_data`
- `st1_req_cachedata_write_enable`
- `st2_dir_updt_dirty_q`

### Thứ tự đúng theo thời gian

1. Store miss dirty victim: `st1_req_is_store=1`, `cachedir_hit_o=0`,
   `st1_dir_victim_dirty_i=1`.
2. VBUF owner capture old dirty victim như CASE D.
3. Sau safe, store miss được MSHR/refill.
4. MSHR/refill giữ dirty store data: `st2_mshr_alloc_dirty_q=1`.
5. Refill line mới và merge store data.
6. Metadata line mới set `dirty=1`, `wback=1`.
7. VBUF write-back old line độc lập.

### Dấu hiệu đúng

- Old dirty line không mất vì đã vào VBUF.
- New line dirty vì store miss WB.
- Data write-back VBUF là old line, không lẫn với store data mới.

### Dấu hiệu sai

- New line dirty không set.
- Store data không xuất hiện trong refill/data response.
- VBUF victim data bị overwrite bởi new line.

### Module nghi ngờ nếu sai

- `hpdcache_ctrl_pe.sv`: `st2_mshr_alloc_dirty_o` cho write miss.
- `hpdcache_miss_handler.sv`: dirty data CBUF/refill merge.
- `hpdcache_vbuf.sv`: giữ old victim line ổn định trong khi refill line mới.

## CASE F - VBUF full / backpressure

Mục tiêu: VBUF depth=1, dirty eviction tiếp theo phải stall/replay khi entry
đang busy/full.

### Signal cần zoom

- `vbuf_full`
- `vbuf_busy`
- `vbuf_empty`
- `vbuf_alloc_ready`
- `st2_vbuf_alloc_o`
- `st2_mshr_alloc_o`
- `st1_rtab_alloc_o`
- `st1_rtab_alloc`
- `st1_rtab_deps.vbuf_hit`
- `vbuf_capture_pending`
- `vbuf_writeback_done`

### Thứ tự đúng theo thời gian

1. Dirty eviction đầu tiên allocate VBUF, `vbuf_full=1`.
2. Khi VBUF chưa ready/empty, `vbuf_alloc_ready=0`.
3. Dirty victim miss kế tiếp không được cấp `st2_vbuf_alloc_o` nếu VBUF full.
4. Pipeline giữ/stall hoặc đưa request vào RTAB.
5. Không được `st2_mshr_alloc_o=1` cho victim dirty chưa safe.
6. Khi `vbuf_writeback_done=1` hoặc entry free, miss kế tiếp mới tiếp tục.

### Dấu hiệu đúng

- Không overwrite victim khi VBUF chưa capture.
- Không allocate VBUF lần hai khi depth=1 full.
- Request bị giữ bằng stall/RTAB, sau đó replay.

### Dấu hiệu sai

- `st2_vbuf_alloc_o=1` khi `vbuf_alloc_ready=0`.
- `st2_mshr_alloc_o=1` dù victim dirty và chưa safe.
- `vbuf_captured_nline` đổi trước khi old writeback done, làm mất old dirty line.

### Module nghi ngờ nếu sai

- `hpdcache_ctrl_pe.sv`: điều kiện `st1_vbuf_alloc_ready_i`.
- `hpdcache_vbuf.sv`: `alloc_ready_o`, `full_o`, `busy_o`.
- `hpdcache_rtab.sv`: replay/dependency nếu request được đưa vào RTAB.

## CASE G - Forward/hazard với line đang nằm trong VBUF

Repo hiện có forward interface. `.gtkw` có cả hazard-stall và load-forwarding
groups.

### Signal cần zoom

Hazard/stall:

- `vbuf_check_hit`
- `st1_vbuf_check_hit_i`
- `st1_rtab_vbuf_hit_o`
- `st1_rtab_deps.vbuf_hit`
- `st1_rtab_alloc`
- `vbuf_writeback_done`
- `vbuf_writeback_done_nline`

Forward:

- `vbuf_fwd_req`
- `vbuf_fwd_hit`
- `vbuf_i.fwd_entry_valid`
- `vbuf_fwd_nline`
- `vbuf_captured_nline`
- `vbuf_fwd_word`
- `vbuf_fwd_data`
- `st1_vbuf_fwd_rsp_valid`
- `core_rsp_vbuf_fwd_valid`
- `core_rsp_o[0].rdata`
- `mem_req_read_miss_valid`

### Thứ tự đúng theo thời gian

1. VBUF đã capture xong line: `vbuf_i.fwd_entry_valid=1`.
2. Load miss cùng nline phát `vbuf_fwd_req=1`.
3. Nếu nline match: `vbuf_fwd_hit=1`.
4. Ctrl_pe không allocate MSHR cho memory refill stale.
5. `st1_vbuf_fwd_rsp_valid=1`, sau đó `core_rsp_vbuf_fwd_valid=1`.
6. `core_rsp_o[0].rdata` bằng `vbuf_fwd_data`.
7. Nếu không forward được, request phải có `st1_rtab_vbuf_hit_o=1` và chờ
   `vbuf_writeback_done`.

### Dấu hiệu đúng

- Forward chỉ khi VBUF entry đã capture xong, không trong CAPTURE.
- Data trả về là victim dirty mới nhất trong VBUF.
- Không tạo `mem_req_read_miss_valid` cho cùng nline khi forward thành công.

### Dấu hiệu sai

- `vbuf_fwd_hit=1` khi `fwd_entry_valid=0`.
- `core_rsp_o.rdata` khác `vbuf_fwd_data`.
- Vừa forward response vừa allocate MSHR/refill same nline.

### Module nghi ngờ nếu sai

- `hpdcache_vbuf.sv`: `fwd_hit_o`, `fwd_data_comb`.
- `hpdcache_ctrl.sv`: `vbuf_fwd_req_o`, response mux.
- `hpdcache_ctrl_pe.sv`: priority giữa forward, VBUF hazard, MSHR hazard.

## CASE H - Explicit flush/clean/invalidate/CMO

Mục tiêu: explicit CMO/flush vẫn có thể dùng `hpdcache_flush`, nhưng dirty
replacement miss owner mode không dùng flush làm owner.

### Signal cần zoom

- `ctrl_flush_alloc`
- `st2_flush_alloc_o`
- `st2_flush_alloc_q`
- `flush_alloc_nline`
- `mem_req_write_flush_valid`
- `mem_req_write_flush_data_valid`
- `mem_resp_write_flush_valid`
- `flush_data_read`
- `flush_ack`
- `flush_ack_nline`
- `ctrl_vbuf_alloc`
- `mem_req_write_vbuf_valid`

### Thứ tự đúng theo thời gian

Dirty replacement owner:

1. `st1_dir_victim_dirty_i=1`.
2. `ctrl_vbuf_alloc=1`.
3. `ctrl_flush_alloc=0`.
4. `mem_req_write_vbuf_valid=1` về sau.

Explicit flush/CMO:

1. CMO/flush request được decode.
2. `ctrl_flush_alloc` hoặc `cmo_flush_alloc` làm `flush_alloc`.
3. `flush_data_read=1`.
4. `mem_req_write_flush_valid/data_valid=1`.
5. `flush_ack=1`.

### Dấu hiệu đúng

- Có thể thấy flush path hoạt động cho CMO.
- Với dirty replacement miss trong owner mode, flush write path không pulse.
- VBUF write path mới là path ghi old dirty victim ra memory.

### Dấu hiệu sai

- Dirty replacement owner vẫn tạo `ctrl_flush_alloc=1`.
- `mem_req_write_flush_valid=1` cùng nline old victim trong replacement miss
  thay vì VBUF.
- Explicit flush không còn phát writeback khi line dirty.

### Module nghi ngờ nếu sai

- `hpdcache_ctrl_pe.sv`: phân biệt dirty replacement vs CMO/flush.
- `hpdcache_flush.sv`: explicit flush FSM.
- `hpdcache.sv`: mux `flush_alloc = ctrl_flush_alloc | cmo_flush_alloc`.

## Cách zoom thực tế trong GTKWave

1. Bắt đầu ở `CASE 3 - Dirty replacement owner`, tìm pulse
   `st1_dir_victim_dirty_i=1`.
2. Zoom quanh đoạn đó khoảng vài chục cycle.
3. Xác nhận `st2_vbuf_alloc_o` lên trước, `st2_mshr_alloc_o` chưa lên nếu
   `st1_vbuf_victim_safe_i=0`.
4. Kéo xuống `CASE 4` cùng thời điểm để xem capture/safe.
5. Kéo xuống `CASE 5` cùng thời điểm để xem VBUF write-back và flush không
   tham gia.
6. Sau đó mới xem `CASE 7` để kiểm tra forward, vì forward phụ thuộc VBUF đã
   capture xong.
