# 03 - WB/VBUF waveform checklist

File wave nên mở:

- `rtl/tb/scripts/gtkwave/wb_all_cases_one_file.gtkw`

Checklist chính:

- [ ] Case store hit WB: `cachedir_hit_o=1`, `st1_req_is_store=1`, `st1_req_wr_wb=1`.
- [ ] Case store hit WB: `st1_req_cachedata_write_enable=1`.
- [ ] Case store hit WB: `st2_dir_updt_dirty_q=1`.
- [ ] Case store hit WB: không có memory write ngay (`wbuf_write_o=0`, `mem_req_write_vbuf_valid=0`).
- [ ] Case clean/invalid victim miss: `st1_dir_victim_dirty_i=0`.
- [ ] Case clean/invalid victim miss: không VBUF write-back (`ctrl_vbuf_alloc=0`, `mem_req_write_vbuf_valid=0`).
- [ ] Case clean/invalid victim miss: MSHR/refill chạy (`st2_mshr_alloc_q=1`, `mem_req_read_miss_valid=1`, `refill_write_data=1`).
- [ ] Case write miss clean/invalid victim: refill xảy ra.
- [ ] Case write miss clean/invalid victim: line mới set WB/dirty đúng (`st2_mshr_alloc_wback_q=1`, `st2_mshr_alloc_dirty_q=1` hoặc `st2_dir_updt_dirty_q=1` sau replay).
- [ ] Case dirty victim miss: `st1_dir_victim_dirty_i=1`.
- [ ] Case dirty victim miss: VBUF alloc trước khi overwrite (`st2_vbuf_alloc_o=1`, `ctrl_vbuf_alloc=1`).
- [ ] Case dirty victim miss: flush không own replacement (`st2_flush_alloc_o=0`, `ctrl_flush_alloc=0` tại đoạn replacement).
- [ ] VBUF capture data cũ đúng: `vbuf_data_read=1`, `data_vbuf_read_accept=1`, `victim_line_q[*]` nhận old data.
- [ ] VBUF safe: `vbuf_capture_done=1` rồi `vbuf_safe_to_overwrite=1`.
- [ ] Refill chỉ xảy ra sau safe_to_overwrite/capture_done: `st2_mshr_alloc_q` và `refill_write_data` không đi trước safe token của dirty victim.
- [ ] Ctrl consume safe đúng: `ctrl_vbuf_safe_consume=1` khi miss tiếp tục.
- [ ] VBUF write-back address đúng old victim address: `mem_req_write_vbuf.mem_req_addr` tương ứng `vbuf_captured_nline`.
- [ ] VBUF write-back data đúng old victim data: `mem_req_write_vbuf_data.mem_req_w_data` khớp `victim_line_q[*]`.
- [ ] VBUF write-back handshake đủ: `mem_req_write_vbuf_valid/ready`, `mem_req_write_vbuf_data_valid/ready`.
- [ ] Memory accept write-back: `mem_resp_write_vbuf_valid=1`.
- [ ] VBUF entry free sau write-back response: `vbuf_writeback_done=1`, sau đó `vbuf_empty=1` hoặc `vbuf_full=0`.
- [ ] hpdcache_flush không xử lý dirty replacement miss owner mode: không có `mem_req_write_flush_valid` cho old replacement nline.
- [ ] Explicit flush/CMO vẫn có thể dùng flush path: khi CMO/flush thật sự xảy ra, `flush_data_read` và `mem_req_write_flush_valid` có thể lên.
- [ ] Không mất store data sau write miss dirty victim: line mới dirty và data store được merge vào refill/new cache line.
- [ ] Nếu VBUF full thì cache stall/replay đúng: `vbuf_alloc_ready=0` không đi kèm alloc mới sai, request được giữ bằng stall/RTAB.
- [ ] Same-line VBUF hazard không đọc stale memory: `st1_rtab_vbuf_hit_o=1` nếu chưa forward/writeback xong.
- [ ] VBUF forwarding đúng nếu có: `vbuf_fwd_req=1`, `vbuf_fwd_hit=1`, `core_rsp_vbuf_fwd_valid=1`.
- [ ] VBUF forwarding data đúng: `core_rsp_o[0].rdata` bằng `vbuf_fwd_data`.
- [ ] Forward thành công không tạo refill thừa cho same nline: `mem_req_read_miss_valid=0` tại đoạn forward hit.
- [ ] Data RAM arbitration không đụng nhau: trong sanity group, các client read/write/refill/flush/VBUF không cùng chiếm RAM sai.

Thứ tự kiểm nhanh nên dùng:

1. Dirty victim owner path: CASE 3 -> CASE 4 -> CASE 5.
2. Store hit WB: CASE 1.
3. Store miss/write-allocate: CASE 2.
4. VBUF hazard/forward: CASE 6 -> CASE 7.
5. Flush/CMO phân biệt owner replacement: CASE 5 và nếu có CMO trong trace thì mở thêm CMO signals.
