# 01 - GTKWave signal map cho WB + VBUF owner mode

Repo root: `C:\source_env\23_5_done_final\cv-hpdcache`

GTKWave file đã đọc:

- `rtl/tb/scripts/gtkwave/wb_all_cases_one_file.gtkw`

Lưu ý đường dẫn trong `.gtkw` đang trỏ Linux path cũ:

- dumpfile: `/media/sf_cv-hpdcache/rtl/tb/logs/run_unique_set_42_cleanwave.vcd`
- savefile: `/media/sf_cv-hpdcache/rtl/tb/scripts/gtkwave/wb_all_cases_one_file.gtkw`

Khi mở trên máy khác, có thể cần chọn lại VCD tương ứng.

## Phân loại nhanh theo module

- CPU/core request side: `.gtkw` hiện không có raw `core_req_valid/ready`; chủ yếu xem request sau khi vào `hpdcache_ctrl_i.st1_*`.
- ctrl/ctrl_pe: nhóm lớn nhất, gồm decode request, hit/miss, dirty update, VBUF alloc/safe, RTAB hazard, forwarding response.
- victim select / PLRU: có `st1_victim_nline`, nhưng chưa có tín hiệu nội bộ PLRU/victim vector chi tiết.
- directory/tag/dirty/data array: có `cachedir_hit_o`, `st2_dir_updt_*`, victim dirty, data RAM arbitration; chưa có full dirty vector/tag vector.
- miss handler / refill: có `miss_mshr_*`, `mem_req_read_miss_*`, `refill_*`.
- VBUF: có alloc, capture, state, safe, forwarding, write-back, stored victim data.
- flush: có flush write path và ack để chứng minh dirty replacement owner mode không đi qua flush.
- wbuf: chỉ có `wbuf_write_o`; chưa có WBUF internal entries.
- memory request/write-back/refill response: có miss read, VBUF write request/data/response, flush write compare.
- rtab/replay/stall: có `st1_rtab_*`, `st1_rtab_deps.*`, `miss_mshr_check*`, nhưng chưa có full RTAB entry state.

## GLOBAL / cấu hình

| Signal đầy đủ | Module | Ý nghĩa | Khi nên lên 1 / hợp lệ | Khi nên xuống 0 / idle | Case |
|---|---|---|---|---|---|
| `i_top.hpdcache_wrapper.i_hpdcache.clk_i` | `hpdcache` | Clock DUT | Toggle liên tục trong sim | Không toggle nếu sim dừng/reset tool | Tất cả |
| `i_top.hpdcache_wrapper.i_hpdcache.rst_ni` | `hpdcache` | Reset active-low | 1 sau reset release | 0 trong reset | Tất cả |
| `i_top.hpdcache_wrapper.i_hpdcache.VBUF_REPLACEMENT_OWNER_EN` | `hpdcache` | Hằng bật owner mode cho VBUF dirty replacement | Phải là 1 trong thiết kế owner mode | Nếu 0 thì VBUF chỉ shadow/flush vẫn owner | D/E/F/G/H |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_i.read_enable_i` | `hpdcache_vbuf` | Cho VBUF tự đọc data RAM victim | 1 khi owner mode cho phép VBUF capture trực tiếp | 0 nếu shadow mode dùng flush data stream | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_i.wb_enable_i` | `hpdcache_vbuf` | Cho VBUF tự phát memory write-back | 1 trong owner mode | 0 nếu không cho VBUF tự write-back | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.HPDCACHE_VBUF_WRITE_ID[3:0]` | `hpdcache` | ID write response dùng để route ack về VBUF | Giá trị ổn định toàn sim | Không đổi | D/E |

## CASE 1 - WB store hit

| Signal đầy đủ | Module | Ý nghĩa | Khi nên lên 1 / hợp lệ | Khi nên xuống 0 / idle | Case |
|---|---|---|---|---|---|
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_req_valid_q` | `hpdcache_ctrl` | Stage 1 đang có request hợp lệ | Khi request đã vào pipeline ctrl stage 1 | Khi bubble/stall không giữ request | A/B/C/D/E/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_req_is_store` | `hpdcache_ctrl` | Request ST1 là store/AMO write class | 1 cho store | 0 cho load/CMO/prefetch | A/C/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_req_is_load` | `hpdcache_ctrl` | Request ST1 là load | 1 cho load | 0 cho store/CMO | B/D/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_req_is_uncacheable` | `hpdcache_ctrl` | Request bypass cache | 1 nếu PMA uncacheable | 0 cho cacheable WB/WT | A/B/C/D/E/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.cachedir_hit_o` | `hpdcache_ctrl` | Directory hit của request ST1 | 1 khi tag hit valid way | 0 khi miss | A/G hit/miss phân biệt |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.force_cacheable_store_wb` | `hpdcache_ctrl` | Ép cacheable store đi WB theo cấu hình | 1 khi store cacheable bị ép WB | 0 nếu dùng hint/policy bình thường | A/C/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_req_wr_wt_decoded` | `hpdcache_ctrl` | Decode hint WT gốc | 1 khi request hint WT | 0 khi không WT | A/C/E/H |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_req_wr_wb_decoded` | `hpdcache_ctrl` | Decode hint WB gốc | 1 khi request hint WB | 0 khi không WB | A/C/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_req_wr_auto_decoded` | `hpdcache_ctrl` | Decode hint AUTO gốc | 1 khi request policy auto | 0 khi explicit WB/WT | A/C/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_req_wr_wt` | `hpdcache_ctrl` | WT policy sau force logic | 1 khi request xử lý như write-through | 0 khi WB hoặc auto WB | A/C/E/H |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_req_wr_wb` | `hpdcache_ctrl` | WB policy sau force logic | 1 khi request xử lý như write-back | 0 khi WT/uncached | A/C/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_req_wr_auto` | `hpdcache_ctrl` | AUTO policy sau force logic | 1 khi policy auto còn hiệu lực | 0 khi explicit/forced | A/C/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_req_cachedata_write` | `hpdcache_ctrl` | Yêu cầu ghi data array cho store hit/refill replay | 1 khi store data sẽ ghi cache data RAM | 0 khi không ghi data array | A/C/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_req_cachedata_write_enable` | `hpdcache_ctrl` | Ghi data array thật sự được enable | 1 khi điều kiện write đủ và không bị hazard | 0 khi stall/bubble/no-write | A/C/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st2_dir_updt_valid_q` | `hpdcache_ctrl` | Giá trị valid sẽ ghi metadata directory | 1 để set line valid | 0 để invalidate/clear line | A/B/C/H |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st2_dir_updt_wback_q` | `hpdcache_ctrl` | Giá trị write-back bit sẽ ghi metadata | 1 khi line thuộc WB policy | 0 khi WT/invalid | A/B/C/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st2_dir_updt_dirty_q` | `hpdcache_ctrl` | Giá trị dirty bit sẽ ghi metadata | 1 sau store hit WB hoặc store miss WB refill/replay | 0 sau clean refill, invalidate, flush clear | A/C/E/H |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.wbuf_write_o` | `hpdcache_ctrl` | Ghi vào write buffer WT/uncached | 1 cho WT/uncached write cần memory write | 0 cho store hit WB đúng kỳ vọng | A/C/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_req_addr[55:0]` | `hpdcache_ctrl` | Địa chỉ vật lý request ST1 | Hợp lệ khi `st1_req_valid_q=1` | Không quan tâm khi ST1 invalid | A/B/C/D/E/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_req_nline[50:0]` | `hpdcache_ctrl` | `{tag,set}` của request | Hợp lệ khi request ST1 valid | Không quan tâm khi invalid | A/B/C/D/E/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_req_word[1:0]` | `hpdcache_ctrl` | Word offset trong cache line | Hợp lệ khi request ST1 valid | Không quan tâm khi invalid | A/G |

## CASE 2 - WB store miss / write-allocate

| Signal đầy đủ | Module | Ý nghĩa | Khi nên lên 1 / hợp lệ | Khi nên xuống 0 / idle | Case |
|---|---|---|---|---|---|
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st2_mshr_alloc_q` | `hpdcache_ctrl` | Stage 2 giữ request allocate MSHR | 1 khi miss được cấp MSHR/refill | 0 khi no miss/stall/bubble | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st2_mshr_alloc_wback_q` | `hpdcache_ctrl` | Metadata WB cho line refill mới | 1 nếu refill line mới là WB | 0 nếu clean/WT/invalid | B/C/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st2_mshr_alloc_dirty_q` | `hpdcache_ctrl` | Store miss mang dirty data vào CBUF/MSHR | 1 cho write miss WB cần line mới dirty | 0 cho read miss clean | C/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st2_mshr_alloc_need_rsp_q` | `hpdcache_ctrl` | Miss cần response về core | 1 khi request cần rsp | 0 khi prefetch/no-rsp | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.miss_mshr_alloc` | `hpdcache` / `miss_handler` | Allocate MSHR đã đưa sang miss handler | 1 khi `ctrl` cấp miss cho MSHR | 0 khi không allocate | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.miss_mshr_alloc_ready` | `hpdcache` / `miss_handler` | MSHR sẵn sàng nhận miss | 1 nếu còn entry/cbuf | 0 nếu MSHR/CBUF full, phải stall/RTAB | B/C/F |
| `i_top.hpdcache_wrapper.i_hpdcache.mem_req_read_miss_valid` | `hpdcache` | Read request refill xuống memory hợp lệ | 1 khi miss handler phát read line | 0 khi không có miss read | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.mem_req_read_miss_ready` | `hpdcache` | Memory/read arbiter accept miss read | 1 khi downstream ready | 0 khi backpressure | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st2_mshr_alloc_addr_q[55:0]` | `hpdcache_ctrl` | Địa chỉ miss được giữ ở ST2 | Hợp lệ khi `st2_mshr_alloc_q=1` | Không quan tâm khi no alloc | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st2_mshr_alloc_nline_o[50:0]` | `hpdcache_ctrl` | Nline miss gửi sang MSHR | Hợp lệ khi MSHR alloc | Không quan tâm khi no alloc | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.miss_mshr_alloc_nline[50:0]` | `hpdcache` | Nline miss ở top-level miss path | Hợp lệ khi `miss_mshr_alloc=1` | Không quan tâm khi no alloc | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.mem_req_read_miss.mem_req_addr[63:0]` | `hpdcache` | Địa chỉ read refill đi memory | Hợp lệ khi `mem_req_read_miss_valid=1` | Không quan tâm khi invalid | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.refill_req_valid` | `hpdcache` | Request refill từ memory response vào ctrl | 1 khi refill data/meta sẵn sàng xử lý | 0 khi không refill | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.refill_req_ready` | `hpdcache` | Ctrl sẵn sàng nhận refill/replay | 1 khi pipeline nhận refill | 0 khi stall/backpressure | B/C/D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.refill_busy` | `hpdcache` / `miss_handler` | Refill FSM đang ghi data/dir | 1 trong quá trình refill | 0 ở REFILL_IDLE | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.mem_resp_read_miss_valid` | `hpdcache` | Memory read response cho miss | 1 khi memory trả beat refill | 0 khi không trả beat | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.mem_resp_read_miss_ready` | `hpdcache` | Miss handler nhận beat refill | 1 khi FIFO refill sẵn sàng | 0 khi FIFO/backpressure | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.refill_write_dir` | `hpdcache_miss_handler` | Ghi directory sau refill | 1 ở cuối refill hoặc state WRITE_DIR | 0 khi chưa ghi metadata | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.refill_write_data` | `hpdcache_miss_handler` | Ghi data array bằng refill beat | 1 trong các beat refill hợp lệ | 0 khi idle/error | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.refill_core_rsp_valid` | `hpdcache_miss_handler` | Response từ refill về core | 1 khi miss load/store cần rsp hoàn tất | 0 khi no rsp/prefetch | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.refill_updt_rtab` | `hpdcache_miss_handler` | Wake/replay RTAB sau refill | 1 khi refill xong và RTAB cần cập nhật | 0 khi không replay | B/C/D/E/F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.refill_nline[50:0]` | `hpdcache_miss_handler` | Nline đang refill | Hợp lệ khi refill busy/write | Không quan tâm khi idle | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.refill_word[1:0]` | `hpdcache_miss_handler` | Word/beat offset đang refill | Hợp lệ khi refill write data | Không quan tâm khi idle | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.refill_data[0][63:0]` | `hpdcache_miss_handler` | Data beat refill sau merge store dirty data | Hợp lệ khi `refill_write_data=1` | Không quan tâm khi idle | B/C/E |

## CASE 3 - Dirty replacement owner

| Signal đầy đủ | Module | Ý nghĩa | Khi nên lên 1 / hợp lệ | Khi nên xuống 0 / idle | Case |
|---|---|---|---|---|---|
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_ctrl_pe_i.st1_dir_victim_dirty_i` | `hpdcache_ctrl_pe` | Victim được chọn đang dirty | 1 khi miss chọn victim dirty | 0 nếu victim invalid/clean | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_ctrl_pe_i.st1_vbuf_victim_safe_i` | `hpdcache_ctrl_pe` | VBUF đã capture an toàn đúng victim nline | 1 sau `vbuf_safe_to_overwrite` match victim | 0 trước khi capture safe hoặc nline khác | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_ctrl_pe_i.st2_flush_alloc_o` | `hpdcache_ctrl_pe` | Ctrl_pe muốn allocate flush entry | Trong owner mode dirty replacement chính phải 0 | 1 cho explicit flush/CMO hoặc non-owner path | D/E/H |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_ctrl_pe_i.st2_vbuf_alloc_o` | `hpdcache_ctrl_pe` | Ctrl_pe muốn allocate VBUF | 1 khi dirty victim miss cần VBUF capture | 0 khi clean victim/hit/sau alloc | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_ctrl_pe_i.st2_mshr_alloc_o` | `hpdcache_ctrl_pe` | Ctrl_pe muốn allocate MSHR | Chỉ 1 sau victim safe nếu victim dirty | 0 trong lúc chờ VBUF safe/full | B/C/D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_ctrl_pe_i.st1_rtab_alloc_o` | `hpdcache_ctrl_pe` | Request đưa vào RTAB do dependency/stall | 1 khi cần replay/stall | 0 khi request đi thẳng | F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_rtab_alloc` | `hpdcache_ctrl` | RTAB allocation sau ctrl_pe | 1 khi request được đưa vào replay table | 0 khi no replay | F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st2_flush_alloc_q` | `hpdcache_ctrl` | Registered flush alloc | Owner dirty replacement nên 0 | 1 cho explicit flush/CMO/WT dirty hit flush | D/E/H |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st2_vbuf_alloc_q` | `hpdcache_ctrl` | Registered VBUF alloc | 1 một chu kỳ khi dirty victim được cấp VBUF | 0 khi no VBUF alloc | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st2_mshr_alloc_q` | `hpdcache_ctrl` | Registered MSHR alloc | 1 sau safe_to_overwrite đối với dirty victim | 0 trước safe hoặc no miss | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.ctrl_flush_alloc` | `hpdcache` | Flush alloc top-level từ ctrl | Owner dirty replacement nên 0 | 1 cho explicit flush/CMO | D/E/H |
| `i_top.hpdcache_wrapper.i_hpdcache.ctrl_vbuf_alloc` | `hpdcache` | VBUF alloc top-level từ ctrl | 1 khi dirty replacement owner capture bắt đầu | 0 khi no dirty victim | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_victim_nline[50:0]` | `hpdcache_ctrl` | Nline victim `{victim_tag,set}` | Hợp lệ khi victim select được yêu cầu | Không quan tâm khi no miss | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.ctrl_vbuf_alloc_nline[50:0]` | `hpdcache` | Nline cũ được đưa vào VBUF | Hợp lệ khi `ctrl_vbuf_alloc=1` | Giữ/không quan tâm khi no alloc | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.flush_alloc_nline[50:0]` | `hpdcache` | Nline được đưa vào flush controller | Không được trùng dirty replacement owner chính | Hợp lệ khi explicit flush/CMO alloc | D/E/H |

## CASE 4 - VBUF capture / safe

| Signal đầy đủ | Module | Ý nghĩa | Khi nên lên 1 / hợp lệ | Khi nên xuống 0 / idle | Case |
|---|---|---|---|---|---|
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_capture_pending` | `hpdcache_vbuf` | VBUF đang capture victim data | 1 trong state `VBUF_CAPTURE` khi read_enable | 0 sau capture xong/idle/writeback | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_data_read` | `hpdcache_vbuf` | VBUF yêu cầu đọc data RAM | 1 trong capture beat chưa accept | 0 khi không capture hoặc beat đã accepted | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_data_read_ready` | `hpdcache_memctrl` | Data RAM rảnh cho VBUF đọc | 1 khi không có client ưu tiên cao hơn | 0 khi req/refill/flush/error đang chiếm data RAM | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_i.data_read_accept` | `hpdcache_vbuf` | Handshake VBUF read data accepted | 1 khi `data_read_o & data_read_ready_i` | 0 nếu chưa accept | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_i.data_read_accept_q` | `hpdcache_vbuf` | Registered accept để capture data cycle sau | 1 sau accept beat | 0 reset/idle/done | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_memctrl_i.data_vbuf_read_accept` | `hpdcache_memctrl` | Memctrl nhận read request từ VBUF | 1 khi VBUF được grant data RAM | 0 khi không grant | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_capture_done` | `hpdcache_vbuf` | VBUF đã capture đủ line | 1 pulse khi beat cuối captured | 0 mặc định các cycle khác | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_entry_ready` | `hpdcache_vbuf` | VBUF entry ready, đã giữ full victim line | 1 ở state READY | 0 khi idle/capture/writeback | D/E/G |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_safe_to_overwrite` | `hpdcache_vbuf` | Cache được phép overwrite victim cũ | 1 sau capture done cho safe nline | 0 sau `ctrl_vbuf_safe_consume` hoặc reset | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.ctrl_vbuf_safe_consume` | `hpdcache` / `ctrl` | Ctrl đã tiêu thụ safe token để refill/overwrite | 1 khi MSHR alloc tiếp tục cho dirty victim đã safe | 0 khi chưa consume/no dirty victim | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_empty` | `hpdcache_vbuf` | VBUF không giữ entry | 1 ở idle/no valid | 0 sau alloc đến writeback done | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_full` | `hpdcache_vbuf` | VBUF depth=1 đang occupied | 1 sau alloc/capture/ready/writeback | 0 idle | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_busy` | `hpdcache_vbuf` | VBUF đang capture/writeback | 1 ở CAPTURE/MEM_REQ/MEM_DATA/WAIT_RESP | 0 idle/ready | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_i.state_q[2:0]` | `hpdcache_vbuf` | FSM state VBUF | Giá trị đổi IDLE->CAPTURE->READY->MEM_REQ->MEM_DATA->WAIT_RESP | Về IDLE sau writeback done | D/E/F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_i.beat_count_q[0:0]` | `hpdcache_vbuf` | Beat index capture line | Tăng khi capture beat accepted | Reset khi alloc/done | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_captured_nline[50:0]` | `hpdcache_vbuf` | Nline victim đang nằm trong VBUF | Hợp lệ sau alloc cho đến free | Không quan tâm khi empty | D/E/G |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_safe_nline[50:0]` | `hpdcache_vbuf` | Nline đã an toàn overwrite | Hợp lệ khi `vbuf_safe_to_overwrite=1` | Không quan tâm khi safe=0 | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_data_read_word[1:0]` | `hpdcache_vbuf` | Word/beat VBUF đang đọc từ data RAM | Hợp lệ khi `vbuf_data_read=1` | Không quan tâm khi idle | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_data_read_data[0][63:0]` | `hpdcache_vbuf` / `memctrl` | Data từ data RAM đưa về VBUF | Hợp lệ sau data read accept | Không quan tâm khi no capture | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_i.victim_line_q[0][0][63:0]` | `hpdcache_vbuf` | Word 0 của victim line captured | Hợp lệ sau capture beat chứa word 0 | Không quan tâm khi empty | D/E/G |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_i.victim_line_q[0][1][63:0]` | `hpdcache_vbuf` | Word 1 của victim line captured | Hợp lệ sau capture | Không quan tâm khi empty | D/E/G |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_i.victim_line_q[0][2][63:0]` | `hpdcache_vbuf` | Word 2 của victim line captured | Hợp lệ sau capture | Không quan tâm khi empty | D/E/G |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_i.victim_line_q[0][3][63:0]` | `hpdcache_vbuf` | Word 3 của victim line captured | Hợp lệ sau capture | Không quan tâm khi empty | D/E/G |

## CASE 5 - VBUF memory write-back

| Signal đầy đủ | Module | Ý nghĩa | Khi nên lên 1 / hợp lệ | Khi nên xuống 0 / idle | Case |
|---|---|---|---|---|---|
| `i_top.hpdcache_wrapper.i_hpdcache.mem_req_write_vbuf_valid` | `hpdcache` / `vbuf` | VBUF phát write request metadata | 1 ở VBUF_MEM_REQ | 0 khi không gửi writeback | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.mem_req_write_vbuf_ready` | `hpdcache` / write arbiter | Memory write arbiter ready cho VBUF req | 1 khi accept metadata | 0 khi backpressure | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.mem_req_write_vbuf_data_valid` | `hpdcache` / `vbuf` | VBUF phát write data beat | 1 ở VBUF_MEM_DATA | 0 khi no data beat | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.mem_req_write_vbuf_data_ready` | `hpdcache` / write arbiter | Memory write data ready | 1 khi accept beat | 0 khi backpressure | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.mem_resp_write_vbuf_valid` | `hpdcache` | Write response routed về VBUF | 1 khi memory ack đúng VBUF write ID | 0 khi no response/response cho client khác | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.mem_resp_write_vbuf_ready` | `hpdcache_vbuf` | VBUF ready nhận write response | 1 ở WAIT_RESP | 0 khi không chờ response | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_i.wb_data_fire` | `hpdcache_vbuf` | Data beat write-back được accept | 1 khi state MEM_DATA và ready | 0 khi no beat/backpressure | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_i.wb_done_fire` | `hpdcache_vbuf` | Write-back hoàn tất theo response | 1 khi WAIT_RESP và response valid | 0 mặc định | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_writeback_done` | `hpdcache_vbuf` | Pulse done top-level | 1 cùng `wb_done_fire` | 0 cycle khác | D/E/G |
| `i_top.hpdcache_wrapper.i_hpdcache.mem_req_write_flush_valid` | `hpdcache_flush` / top | Flush controller phát write metadata | 0 trong dirty replacement owner chính | 1 khi explicit flush/CMO hoặc non-owner flush | D/E/H |
| `i_top.hpdcache_wrapper.i_hpdcache.mem_req_write_flush_data_valid` | `hpdcache_flush` / top | Flush controller phát write data | 0 trong dirty replacement owner chính | 1 khi explicit flush/CMO | D/E/H |
| `i_top.hpdcache_wrapper.i_hpdcache.mem_resp_write_flush_valid` | `hpdcache` | Write response routed về flush | 0 cho VBUF writeback | 1 cho flush write response | D/E/H |
| `i_top.hpdcache_wrapper.i_hpdcache.flush_data_read` | `hpdcache_flush` | Flush đọc data RAM | 0 khi dirty replacement owner do VBUF | 1 khi explicit flush đọc dirty line | D/E/H |
| `i_top.hpdcache_wrapper.i_hpdcache.flush_ack` | `hpdcache_flush` | Flush writeback ack | 0 cho VBUF writeback | 1 khi flush write ack | D/E/H |
| `i_top.hpdcache_wrapper.i_hpdcache.mem_req_write_vbuf.mem_req_addr[63:0]` | `hpdcache_vbuf` / top | Địa chỉ write-back old dirty line | Hợp lệ khi `mem_req_write_vbuf_valid=1`; phải bằng old victim line address | Không quan tâm khi invalid | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.mem_req_write_vbuf_data.mem_req_w_data[255:0]` | `hpdcache_vbuf` / top | Data write-back old dirty line | Hợp lệ khi `mem_req_write_vbuf_data_valid=1`; phải khớp victim_line_q | Không quan tâm khi invalid | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_writeback_done_nline[50:0]` | `hpdcache_vbuf` | Nline vừa writeback xong | Hợp lệ khi `vbuf_writeback_done=1` | Không quan tâm khi no done | D/E/G |
| `i_top.hpdcache_wrapper.i_hpdcache.flush_ack_nline[50:0]` | `hpdcache_flush` | Nline flush vừa ack | Hợp lệ khi `flush_ack=1` | Không quan tâm khi no ack | D/E/H |

## CASE 6 - Same-line VBUF hazard / RTAB

| Signal đầy đủ | Module | Ý nghĩa | Khi nên lên 1 / hợp lệ | Khi nên xuống 0 / idle | Case |
|---|---|---|---|---|---|
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_check_hit` | `hpdcache_vbuf` | Request/MHSR check nline hit entry VBUF | 1 khi nline đang nằm trong VBUF và chưa done | 0 khi no match/empty/done | F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_ctrl_pe_i.st1_vbuf_check_hit_i` | `hpdcache_ctrl_pe` | VBUF hazard input vào ctrl_pe | 1 khi request cùng nline với VBUF | 0 khi no VBUF dependency | F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_ctrl_pe_i.st1_vbuf_fwd_hit_i` | `hpdcache_ctrl_pe` | VBUF forwarding hit input | 1 khi load miss có thể lấy data từ VBUF | 0 khi no forward | G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_ctrl_pe_i.st1_rtab_vbuf_hit_o` | `hpdcache_ctrl_pe` | RTAB dependency do VBUF | 1 khi request phải đợi VBUF writeback/done | 0 khi không phụ thuộc VBUF hoặc đã forward | F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_ctrl_pe_i.st1_rtab_mshr_hit_o` | `hpdcache_ctrl_pe` | RTAB dependency do MSHR same-line | 1 khi request trùng miss đang pending | 0 khi không trùng MSHR | B/F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_rtab_deps.vbuf_hit` | `hpdcache_ctrl` / `rtab` | Dependency field lưu VBUF hit | 1 trong RTAB entry chờ VBUF | 0 nếu không chờ VBUF | F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_rtab_deps.mshr_hit` | `hpdcache_ctrl` / `rtab` | Dependency field lưu MSHR hit | 1 trong RTAB entry chờ MSHR | 0 nếu không chờ MSHR | F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_rtab_check` | `hpdcache_ctrl` | Check RTAB dependency cho request | 1 khi request cần kiểm tra replay dependencies | 0 khi no check | F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_rtab_check_hit` | `hpdcache_ctrl` | Request hit existing RTAB entry | 1 nếu đã có request same-line pending | 0 nếu no existing RTAB hit | F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.miss_mshr_check` | `hpdcache` / `miss_handler` | Check MSHR same-line | 1 khi ctrl check miss table | 0 khi no check | B/F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.miss_mshr_hit` | `hpdcache` / `miss_handler` | MSHR same-line hit | 1 khi nline đã có MSHR pending | 0 khi no pending miss | B/F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_ctrl_pe_i.st1_mshr_hit_i` | `hpdcache_ctrl_pe` | MSHR hit input vào ctrl_pe | 1 khi same-line MSHR pending | 0 khi no hit | B/F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.refill_updt_rtab` | `hpdcache_miss_handler` | Refill wake RTAB | 1 khi refill xong có thể replay | 0 khi no wake | B/F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_writeback_done_nline[50:0]` | `hpdcache_vbuf` | Nline VBUF done dùng để clear RTAB vbuf dependency | Hợp lệ khi `vbuf_writeback_done=1` | Không quan tâm khi no done | F/G |
| `i_top.hpdcache_wrapper.i_hpdcache.miss_mshr_check_nline[50:0]` | `hpdcache` / `miss_handler` | Nline đang check MSHR | Hợp lệ khi `miss_mshr_check=1` | Không quan tâm khi no check | B/F/G |

## CASE 7 - VBUF load forwarding

| Signal đầy đủ | Module | Ý nghĩa | Khi nên lên 1 / hợp lệ | Khi nên xuống 0 / idle | Case |
|---|---|---|---|---|---|
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_fwd_req` | `hpdcache_ctrl` -> `vbuf` | Load miss hỏi VBUF có data không | 1 khi load cacheable miss và owner mode | 0 cho hit/store/uncached/CMO | G |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_fwd_hit` | `hpdcache_vbuf` | VBUF forward hit đúng nline | 1 khi `fwd_req` match captured nline sau capture | 0 khi no match/capture chưa xong/done | G |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_i.fwd_entry_valid` | `hpdcache_vbuf` | Entry có thể forward | 1 khi valid và không IDLE/CAPTURE | 0 khi empty/capture chưa xong | G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_vbuf_fwd_rsp_valid` | `hpdcache_ctrl` | Ctrl_pe tạo response từ VBUF ở ST1 | 1 khi load cần rsp và VBUF hit | 0 khi no forward | G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.core_rsp_vbuf_fwd_valid` | `hpdcache_ctrl` | Response mux chọn data VBUF | 1 khi response data lấy từ VBUF | 0 khi response từ data RAM/refill/CMO/UC | G |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_fwd_rsp_valid` | `hpdcache` | Forward response valid xuất từ ctrl về top/VBUF unused tracking | 1 khi response forward hợp lệ | 0 khi no forward | G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.st1_rsp_valid` | `hpdcache_ctrl` | Response ST1 valid | 1 khi hit/forward/certain response ready | 0 khi no response | A/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.core_rsp_valid` | `hpdcache_ctrl` | Response mux valid nội bộ | 1 khi core response sẽ phát | 0 khi no response | A/B/C/G |
| `i_top.hpdcache_wrapper.i_hpdcache.core_rsp_valid_o[0]` | `hpdcache` | Response valid ra core port 0 | 1 khi core nhận response | 0 khi no response | A/B/C/G |
| `i_top.hpdcache_wrapper.i_hpdcache.mem_req_read_miss_valid` | `hpdcache` | Read memory miss | Với forward đúng nên không bật cho same nline load | 1 nếu thật sự cần refill từ memory | G |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_fwd_nline[50:0]` | `hpdcache_ctrl` -> `vbuf` | Nline load đang hỏi forward | Hợp lệ khi `vbuf_fwd_req=1` | Không quan tâm khi no req | G |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_fwd_word[1:0]` | `hpdcache_ctrl` -> `vbuf` | Word offset cần forward | Hợp lệ khi `vbuf_fwd_req=1` | Không quan tâm khi no req | G |
| `i_top.hpdcache_wrapper.i_hpdcache.vbuf_fwd_data[0][63:0]` | `hpdcache_vbuf` | Data đọc từ victim_line_q để forward | Hợp lệ khi `vbuf_fwd_hit=1` | 0/không quan tâm khi no hit | G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.core_rsp_vbuf_fwd_data[0][63:0]` | `hpdcache_ctrl` | Data VBUF vào response mux | Hợp lệ khi `core_rsp_vbuf_fwd_valid=1` | Không quan tâm khi no forward | G |
| `i_top.hpdcache_wrapper.i_hpdcache.core_rsp_o[0].rdata[0][63:0]` | `hpdcache` | Data response về core | Hợp lệ khi `core_rsp_valid_o[0]=1`; với forward phải bằng VBUF data | Không quan tâm khi no response | A/B/C/G |
| `i_top.hpdcache_wrapper.i_hpdcache.core_rsp_o[0].tid[5:0]` | `hpdcache` | Transaction ID response | Hợp lệ khi response valid | Không quan tâm khi no response | A/B/C/G |
| `i_top.hpdcache_wrapper.i_hpdcache.core_rsp_o[0].sid[2:0]` | `hpdcache` | Source ID response | Hợp lệ khi response valid | Không quan tâm khi no response | A/B/C/G |

## SANITY - Data RAM arbitration and response mux

| Signal đầy đủ | Module | Ý nghĩa | Khi nên lên 1 / hợp lệ | Khi nên xuống 0 / idle | Case |
|---|---|---|---|---|---|
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_memctrl_i.data_req_read_i` | `hpdcache_memctrl` | Core load/hit read data RAM | 1 khi read hit cần data array | 0 khi no read | A/G sanity |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_memctrl_i.data_req_write_i` | `hpdcache_memctrl` | Core store writes data RAM | 1 khi store hit/replay writes cache | 0 khi no store write | A/C/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_memctrl_i.data_amo_write_i` | `hpdcache_memctrl` | AMO write data RAM | 1 khi AMO update | 0 normally for WB cases | H/AMO |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_memctrl_i.data_refill_i` | `hpdcache_memctrl` | Refill writes data RAM | 1 khi refill beat ghi cache | 0 khi no refill | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_memctrl_i.data_flush_read_i` | `hpdcache_memctrl` | Flush reads data RAM | 1 cho flush/CMO | 0 cho VBUF dirty replacement owner | D/E/H |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_memctrl_i.data_vbuf_read_i` | `hpdcache_memctrl` | VBUF reads data RAM | 1 khi VBUF capture victim | 0 khi no capture | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_memctrl_i.data_vbuf_read_ready_o` | `hpdcache_memctrl` | VBUF reader ready | 1 khi data RAM không bị client ưu tiên cao chiếm | 0 khi backpressure | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_memctrl_i.data_vbuf_read_accept` | `hpdcache_memctrl` | VBUF read accepted | 1 khi read_i & ready_o | 0 otherwise | D/E/F |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_memctrl_i.data_err_read_i` | `hpdcache_memctrl` | ECC/error scrub read | 1 khi error path đọc RAM | 0 normally | Sanity |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_memctrl_i.data_err_write_i` | `hpdcache_memctrl` | ECC/error scrub write | 1 khi repair write | 0 normally | Sanity |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_memctrl_i.data_way[3:0]` | `hpdcache_memctrl` | Way one-hot đang truy cập data RAM | Hợp lệ khi có read/write/refill/VBUF/flush client | Không quan tâm khi no access | A/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_memctrl_i.data_vbuf_read_word_i[1:0]` | `hpdcache_memctrl` | Word VBUF muốn đọc | Hợp lệ khi `data_vbuf_read_i=1` | Không quan tâm khi idle | D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.hpdcache_memctrl_i.data_vbuf_read_data_o[0][63:0]` | `hpdcache_memctrl` | Data RAM output cho VBUF | Hợp lệ sau accept | Không quan tâm khi no VBUF read | D/E/G |
| `i_top.hpdcache_wrapper.i_hpdcache.hpdcache_ctrl_i.core_rsp_valid` | `hpdcache_ctrl` | Core response valid nội bộ | 1 khi bất kỳ nguồn response valid | 0 khi no response | A/B/C/G |
| `i_top.hpdcache_wrapper.i_hpdcache.refill_core_rsp_valid` | `hpdcache_miss_handler` | Response từ refill | 1 khi miss refill trả core | 0 khi no refill response | B/C/D/E |
| `i_top.hpdcache_wrapper.i_hpdcache.uc_core_rsp_valid` | `hpdcache_uncached` | Response từ uncached path | 1 cho uncached access | 0 cho WB cases cacheable | Sanity |
| `i_top.hpdcache_wrapper.i_hpdcache.cmo_core_rsp_valid` | `hpdcache_cmo` | Response từ CMO path | 1 khi CMO done | 0 cho normal load/store | H |

## Tín hiệu quan trọng còn thiếu trong `.gtkw` hiện tại

Các nhóm này không có hoặc chưa đủ trong `wb_all_cases_one_file.gtkw`; xem thêm
`missing_signals_to_add.md` ở bước 7 nếu cần mở rộng:

- Raw CPU valid/ready/request opcode tại wrapper/core port.
- Victim way one-hot/tag/valid/wback đầy đủ: hiện có dirty và nline, nhưng thiếu `st1_dir_victim_way`, `st1_dir_victim_tag`, `st1_dir_victim_valid`, `st1_dir_victim_wback`.
- PLRU internal update/selected state trong `hpdcache_victim_plru`.
- Directory valid/dirty/wback vector theo set/way trong `hpdcache_memctrl`.
- VBUF alloc tag/set/way đầy đủ: hiện có nline, chưa có `ctrl_vbuf_alloc_tag/set/way`.
- Full WBUF internals: hiện chỉ có `wbuf_write_o`.
