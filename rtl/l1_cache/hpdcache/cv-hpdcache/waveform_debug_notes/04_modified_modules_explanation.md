# 04 - Giai thich module lien quan write-back / VBUF owner mode

Tai lieu nay duoc lap theo code hien tai trong repo va `git diff` tai thoi diem doc.

Ket qua `git diff --stat` cho thay cac file tracked dang modified so voi commit hien tai:

- `rtl/src/hpdcache.sv`
- `rtl/src/hpdcache_ctrl.sv`
- `rtl/src/hpdcache_ctrl_pe.sv`
- `rtl/src/hpdcache_vbuf.sv`

Cac module khac ben duoi khong thay trong `git diff` tracked hien tai, nen duoc danh dau la **phan tich theo code hien tai**. Chung van rat quan trong de hieu waveform vi nam tren duong dirty bit, victim selection, refill, flush, RTAB va memory write arbitration.

## 1. `rtl/src/hpdcache_vbuf.sv`

Trang thai sua doi: co trong `git diff`, la module chinh cho VBUF owner mode va forwarding.

### Vai tro goc

VBUF la victim buffer dung de giu cache line bi eviction. Trong thiet ke flush-based/shadow-style, VBUF co the chi dong vai tro phu tro de giu/canh tranh voi flush path.

### Vai tro sau khi sua

Trong owner mode, VBUF tro thanh owner cua dirty replacement miss:

1. Nhan alloc khi ctrl phat hien victim dirty.
2. Tu doc/capture victim line tu data array.
3. Bao `safe_to_overwrite` sau khi capture xong de cache duoc phep refill/overwrite way cu.
4. Tu phat memory write-back cho old dirty line.
5. Free entry sau khi memory response ve.
6. Neu co request load dung nline dang nam trong VBUF, co the forward data truc tiep tu VBUF.

### Input/output moi hoac quan trong

- `alloc_i`, `alloc_ready_o`: handshake alloc entry VBUF.
- `alloc_nline_i`, `alloc_tag_i`, `alloc_set_i`, `alloc_way_i`: metadata cua victim line can capture.
- `read_enable_i`: owner mode cho phep VBUF tu phat read data array.
- `wb_enable_i`: owner mode cho phep VBUF tu write-back ra memory.
- `safe_consume_i`: ctrl consume safe event sau khi da dung no de cho refill/overwrite tiep tuc.
- `safe_to_overwrite_o`, `safe_nline_o`: bao cache line cu da duoc capture an toan.
- `capture_pending_o`, `capture_done_o`: trang thai capture victim data.
- `writeback_done_o`, `writeback_done_nline_o`: ack write-back xong, dung cho RTAB/dependency.
- `fwd_req_i`, `fwd_nline_i`, `fwd_word_i`, `fwd_hit_o`, `fwd_data_o`: giao dien forwarding moi.
- `mem_req_write_*`, `mem_req_write_data_*`, `mem_resp_write_*`: kenh write memory cua VBUF.

### FSM quan trong

FSM co cac state:

- `VBUF_IDLE`: entry rong, `alloc_ready_o = 1`.
- `VBUF_CAPTURE`: dang doc/capture victim line tu cache data array.
- `VBUF_READY`: line da capture xong, co the forward hoac write-back.
- `VBUF_MEM_REQ`: dang phat metadata write request ra memory.
- `VBUF_MEM_DATA`: dang phat cac data beat cua line.
- `VBUF_WAIT_RESP`: cho memory write response.

Thu tu dung trong waveform:

`alloc_i` -> `VBUF_CAPTURE` -> `capture_done_o` + `safe_to_overwrite_o` -> `VBUF_READY` -> `mem_req_write_valid_o` -> `mem_req_write_data_valid_o` -> `mem_resp_write_valid_i` -> `writeback_done_o` -> entry free.

### always_comb / always_ff quan trong

- FSM comb quyet dinh chuyen state va phat `data_read_o`, `mem_req_write_valid_o`, `mem_req_write_data_valid_o`.
- Capture logic ghi `victim_line_q[beat_count_q]` khi `capture_fire`.
- Safe logic set `safe_valid_q` khi capture last beat va clear khi `safe_consume_i`.
- Write-back beat counter tang khi data beat duoc accept.
- Forward comb chon word tu `victim_line_q[fwd_word_i]`.

### Signal can xem tren waveform

- `vbuf_alloc`
- `vbuf_alloc_ready`
- `vbuf_valid`
- `vbuf_full`
- `vbuf_busy`
- `vbuf_capture_pending`
- `vbuf_capture_done`
- `vbuf_safe_to_overwrite`
- `vbuf_safe_nline`
- `vbuf_data_read`
- `vbuf_data_read_ready`
- `vbuf_data_capture`
- `vbuf_data_read_data`
- `vbuf_mem_req_write_valid`
- `vbuf_mem_req_write_ready`
- `vbuf_mem_req_write_addr`
- `vbuf_mem_req_write_data_valid`
- `vbuf_mem_req_write_data`
- `vbuf_mem_req_write_last`
- `vbuf_mem_resp_write_valid`
- `vbuf_writeback_done`
- `vbuf_fwd_req`
- `vbuf_fwd_hit`
- `vbuf_fwd_data`

### Bug de xay ra

- `safe_to_overwrite_o` len qua som, truoc khi capture het line.
- `safe_to_overwrite_o` khong duoc consume, lam replay/refill sai nline sau do.
- VBUF write-back address dung new refill line thay vi old victim nline.
- Data beat capture sai thu tu word/beat.
- Forward chi hit theo nline nhung tra sai word.
- `writeback_done_o` khong map dung nline, lam RTAB dependency khong duoc clear.
- VBUF depth hien tai bi rang buoc `VBUF_DEPTH == 1`; neu test ep full thi can ky vong stall/replay, khong duoc overwrite entry.

## 2. `rtl/src/hpdcache.sv`

Trang thai sua doi: co trong `git diff`, la top-level noi VBUF voi ctrl, data array va memory write arbiter.

### Vai tro goc

Top-level HPDcache ket noi core side, ctrl, memctrl, miss handler, flush, wbuf, RTAB va memory interface.

### Vai tro sau khi sua

Top them VBUF owner path vao duong replacement:

1. Dinh nghia `VBUF_REPLACEMENT_OWNER_EN = 1'b1`.
2. Ket noi ctrl voi VBUF alloc/safe/writeback/forwarding.
3. Ket noi VBUF voi data RAM read port thong qua memctrl.
4. Them VBUF vao memory write arbiter nhu mot write client rieng.
5. Demux write response de tra response cua VBUF ve VBUF.

### Wire/logic moi hoac quan trong

- `vbuf_alloc`, `vbuf_alloc_ready`
- `vbuf_alloc_nline`, `vbuf_alloc_tag`, `vbuf_alloc_set`, `vbuf_alloc_way`
- `vbuf_safe_to_overwrite`, `vbuf_safe_nline`, `vbuf_safe_consume`
- `vbuf_writeback_done`, `vbuf_writeback_done_nline`
- `vbuf_fwd_req`, `vbuf_fwd_nline`, `vbuf_fwd_word`, `vbuf_fwd_hit`, `vbuf_fwd_data`, `vbuf_fwd_rsp_valid`
- `mem_req_write_vbuf_*`, `mem_resp_write_vbuf_*`
- `vbuf_data_read`, `vbuf_data_read_ready`, `vbuf_data_read_data`

### Logic moi quan trong

- `vbuf_drain = ~owner & flush_ack & ...`: chi lien quan non-owner/shadow compatibility.
- `vbuf_data_capture = owner ? (vbuf_data_read & vbuf_data_read_ready) : flush_data_read`.
- `vbuf_data_capture_data = owner ? vbuf_data_read_data : flush_data_read_data`.
- Memory write arbiter co 4 source: WBUF, flush, VBUF, UC.
- VBUF write ID la `HPDCACHE_VBUF_WRITE_ID`, can khong conflict voi flush/UC IDs.

### Signal can xem tren waveform

- Global owner config: `VBUF_REPLACEMENT_OWNER_EN`
- VBUF alloc/safe/writeback/forward signals o top
- Memory write arbiter grant/ready/valid neu duoc trace
- `mem_req_write_vbuf_valid`
- `mem_req_write_vbuf_addr`
- `mem_req_write_vbuf_data_valid`
- `mem_resp_write_vbuf_valid`
- `mem_req_write_flush_valid`
- `mem_req_write_wbuf_valid`

### Bug de xay ra

- Memory response demux nhan nham VBUF response thanh flush/WBUF/UC.
- VBUF write request bi starve neu arbiter uu tien nguon khac lien tuc.
- Top noi sai data capture owner mode, lam VBUF capture data flush hoac data stale.
- `VBUF_REPLACEMENT_OWNER_EN` bi deassert thi dirty replacement co the quay ve flush path.

## 3. `rtl/src/hpdcache_ctrl_pe.sv`

Trang thai sua doi: co trong `git diff`, la noi quyet dinh miss/hit/replay/alloc cho request pipeline.

### Vai tro goc

`ctrl_pe` la policy engine cho stage request: phan loai load/store/AMO/CMO, hit/miss, allocate MSHR, allocate flush, update directory, update data RAM, allocate RTAB/replay.

### Vai tro sau khi sua

Trong owner mode:

1. Dirty victim miss khong alloc flush nhu duong cu.
2. Neu victim dirty va VBUF chua safe, request duoc dua vao RTAB/replay va VBUF duoc alloc neu ready.
3. Khi VBUF da safe dung nline victim, request moi duoc alloc MSHR/refill va consume safe.
4. Load miss co the forward truc tiep tu VBUF neu `st1_vbuf_fwd_hit_i`.
5. Store path uu tien check VBUF dependency truoc MSHR hit de tranh write/read cung line dang trong VBUF.

### Input/output moi hoac quan trong

- `st1_vbuf_fwd_hit_i`
- `vbuf_fwd_rsp_valid_o`
- `st1_vbuf_alloc_ready_i`
- `st1_vbuf_victim_safe_i`
- `st1_vbuf_check_hit_i`
- `st2_vbuf_alloc_o`
- `st2_vbuf_safe_consume_o`
- `st1_rtab_vbuf_hit_o`

### Logic quan trong

Load miss:

- Neu owner + load + `st1_vbuf_fwd_hit_i`: response lay tu VBUF, commit request, khong can refill memory.
- Neu owner + `st1_vbuf_check_hit_i`: allocate RTAB voi dependency VBUF.
- Neu dirty victim va chua safe: allocate RTAB; owner mode chi alloc VBUF, khong alloc flush.
- Neu dirty victim da safe: allocate MSHR/refill va consume safe.

Store miss/write-back:

- Store miss WB vao clean/invalid victim: allocate MSHR/refill, sau store line moi dirty.
- Store miss WB vao dirty victim: owner mode can VBUF alloc/capture/safe truoc khi overwrite.
- Store path check VBUF hit truoc MSHR hit de tranh replay sai khi line cu dang trong VBUF.

Store hit:

- WB store hit update data RAM.
- Directory update set `wback=1`, `dirty=1`, `valid=1`, `fetch=0`.
- Khong phat memory write ngay.

### Signal can xem tren waveform

- `st1_req_valid`
- `st1_req_is_load`
- `st1_req_is_store`
- `st1_req_wr_policy_wb`
- `st1_req_cache_hit`
- `st1_req_cache_miss`
- `st1_dir_victim_dirty`
- `st1_vbuf_check_hit`
- `st1_vbuf_fwd_hit`
- `st1_vbuf_victim_safe`
- `st2_vbuf_alloc`
- `st2_vbuf_safe_consume`
- `st2_mshr_alloc`
- `st2_flush_alloc`
- `st1_rtab_alloc`
- `st1_rtab_vbuf_hit`
- `vbuf_fwd_rsp_valid`

### Bug de xay ra

- Dirty victim owner mode van phat `st2_flush_alloc`.
- Refill/MSHR alloc xay ra truoc `st1_vbuf_victim_safe`.
- Store miss dirty victim bi mat store data khi replay/refill.
- VBUF dependency vao RTAB khong duoc set, request cung nline chay qua khi line cu dang write-back.
- Load forwarding tu VBUF tra response nhung response mux khong chon VBUF data.

## 4. `rtl/src/hpdcache_ctrl.sv`

Trang thai sua doi: co trong `git diff`, la lop trung chuyen/pipe register giua ctrl_pe, memctrl, RTAB, VBUF va response mux.

### Vai tro goc

`hpdcache_ctrl` xu ly decode request, pipeline st1/st2, noi policy engine voi memctrl/miss_handler/rtab/flush/wbuf, va tao response ve core.

### Vai tro sau khi sua

1. Force cacheable store sang write-back policy trong flow hien tai.
2. Tinh `st1_vbuf_victim_safe` bang `vbuf_safe_to_overwrite_i` va match `safe_nline`.
3. Register metadata alloc VBUF o stage2: nline/tag/set/way.
4. Tao VBUF forwarding request cho load miss cacheable.
5. Them VBUF forwarding vao response mux voi priority sau refill/CMO/UC va truoc data RAM read fallback.

### Input/output moi hoac quan trong

- `vbuf_alloc_o`
- `vbuf_alloc_nline_o`
- `vbuf_alloc_tag_o`
- `vbuf_alloc_set_o`
- `vbuf_alloc_way_o`
- `vbuf_safe_to_overwrite_i`
- `vbuf_safe_nline_i`
- `vbuf_safe_consume_o`
- `vbuf_fwd_req_o`
- `vbuf_fwd_nline_o`
- `vbuf_fwd_word_o`
- `vbuf_fwd_hit_i`
- `vbuf_fwd_data_i`
- `vbuf_fwd_rsp_valid_o`

### Logic quan trong

- `force_cacheable_store_wb`: cacheable store duoc xem nhu WB store.
- `st1_vbuf_victim_safe = vbuf_safe_to_overwrite_i & (vbuf_safe_nline_i == st1_victim_nline)`.
- `vbuf_fwd_req_o` chi bat cho owner mode, load, cacheable, khong uncacheable, khong CMO/prefetch, va cache miss.
- Response mux can chon `vbuf_fwd_data_i` khi `core_rsp_vbuf_fwd_valid`.

### Signal can xem tren waveform

- `st1_req_wr_policy_wb`
- `st1_vbuf_victim_safe`
- `st1_victim_nline`
- `vbuf_safe_nline`
- `st2_vbuf_alloc_q`
- `st2_vbuf_alloc_nline_q`
- `st2_vbuf_safe_consume_q`
- `vbuf_fwd_req`
- `vbuf_fwd_nline`
- `vbuf_fwd_word`
- `vbuf_fwd_rsp_valid`
- `core_rsp_valid`
- `core_rsp_rdata`

### Bug de xay ra

- `safe_nline` match sai voi victim nline, refill bi release sai request.
- Stage2 alloc VBUF luu sai tag/set/way khi pipeline stall/rollback.
- VBUF forwarding request bat ca khi cache hit, co the tao response sai.
- Response mux priority lam VBUF forward bi che boi data RAM stale.

## 5. `rtl/src/hpdcache_memctrl.sv`

Trang thai sua doi: phan tich theo code hien tai, khong thay modified trong `git diff` tracked.

### Vai tro goc

Memctrl quan ly directory/tag/dirty/fetch/wback metadata, data RAM read/write, victim selection, va cac request tu ctrl/refill/flush/VBUF/error handler.

### Vai tro trong owner mode

Memctrl khong nhat thiet la owner cua write-back, nhung no cung cap:

1. Victim metadata cho ctrl: valid/wback/dirty/tag/way.
2. Victim data cho VBUF capture thong qua data read port.
3. Metadata update khi store hit/refill.
4. Dirty bit read/write de xac dinh eviction dirty.

### Input/output quan trong

- `dir_victim_valid_o`
- `dir_victim_wback_o`
- `dir_victim_dirty_o`
- `dir_victim_tag_o`
- `data_vbuf_read_i`
- `data_vbuf_read_ready_o`
- `data_vbuf_read_set_i`
- `data_vbuf_read_word_i`
- `data_vbuf_read_way_i`
- `data_vbuf_read_data_o`
- `data_refill_i`, `data_refill_way_i`, `data_refill_set_i`
- Directory write signals tu ctrl/refill.

### Logic quan trong

- Directory hit/victim output duoc tinh tu vector way.
- Victim select nhan valid/wback/dirty/fetch vector.
- Data write priority co refill/request/AMO/error.
- Data read arbitration uu tien request read, flush read, VBUF read accept, error read.
- `data_vbuf_read_ready_o` chi len khi khong co request/refill/flush/error tranh port.

### Signal can xem tren waveform

- `st1_dir_victim_valid`
- `st1_dir_victim_wback`
- `st1_dir_victim_dirty`
- `st1_dir_victim_tag`
- `st1_dir_victim_way`
- `data_vbuf_read`
- `data_vbuf_read_ready`
- `data_vbuf_read_set`
- `data_vbuf_read_word`
- `data_vbuf_read_way`
- `data_vbuf_read_data`
- `data_req_write`
- `data_refill`
- `dir_updt`
- `dir_updt_dirty`

### Bug de xay ra

- VBUF bi starvation neu data read port lien tuc bi request/flush/refill chiem.
- Victim dirty/tag output khong tuong ung voi victim way da chon.
- Data read way/set/word sai lam VBUF capture nham line.
- Directory dirty bit khong set sau WB store, lam eviction clean gia.

## 6. `rtl/src/hpdcache_miss_handler.sv`

Trang thai sua doi: phan tich theo code hien tai, khong thay modified trong `git diff` tracked.

### Vai tro goc

Miss handler quan ly MSHR, phat read/refill request xuong memory, nhan refill response, ghi data array va update directory.

### Vai tro trong owner mode

Miss handler khong capture dirty victim. No chi nen refill/overwrite sau khi ctrl cho phep MSHR alloc, ma dieu kien dirty victim owner mode la VBUF da capture/safe.

### Input/output quan trong

- `mshr_alloc`
- `mshr_alloc_nline`
- `mshr_alloc_way`
- `mshr_alloc_dirty`
- `mshr_alloc_wback`
- `refill_req_valid`
- `refill_req_ready`
- `refill_rsp_valid`
- `refill_write_data`
- `refill_write_dir`
- `refill_nline`
- `refill_way`
- `refill_done`/meta FIFO consume signals neu co trace.

### Logic quan trong

- FSM refill: `REFILL_IDLE`, `REFILL_WRITE`, `REFILL_WRITE_DIR`, `REFILL_INVAL`.
- Refill data co the merge dirty store data vao clean refill line.
- Directory duoc update o last beat / write-dir stage.
- Dirty bit cua line moi phu thuoc loai miss: load miss thuong clean, store miss WB dirty.

### Signal can xem tren waveform

- `st2_mshr_alloc`
- `mshr_alloc_dirty`
- `mshr_alloc_wback`
- `refill_req_valid`
- `refill_req_ready`
- `refill_rsp_valid`
- `refill_data`
- `refill_write_data`
- `refill_write_dir`
- `refill_way`
- `refill_nline`

### Bug de xay ra

- MSHR alloc/refill xay ra truoc VBUF safe, overwrite dirty line truoc capture.
- Store miss dirty merge khong dung byte enable, lam mat store data.
- Directory update sau refill khong set dirty cho write miss WB.
- Error refill path clear dirty/valid sai.

## 7. `rtl/src/hpdcache_flush.sv`

Trang thai sua doi: phan tich theo code hien tai, khong thay modified trong `git diff` tracked.

### Vai tro goc

Flush controller doc cache line tu data array va ghi line do ra memory cho explicit flush/clean hoac dirty replacement trong thiet ke cu.

### Vai tro trong owner mode

Flush van quan trong cho explicit flush/clean/invalidate/CMO hoac non-owner compatibility. Dirty replacement miss trong owner mode khong nen phu thuoc vao flush path.

### Input/output quan trong

- `flush_alloc_i`
- `flush_alloc_ready_o`
- `flush_alloc_nline_i`
- `flush_alloc_way_i`
- `flush_data_read_o`
- `flush_data_read_data_i`
- `flush_ack_o`
- `flush_ack_nline_o`
- `mem_req_write_valid_o`
- `mem_req_write_data_valid_o`
- `mem_resp_write_valid_i`

### FSM quan trong

- `FLUSH_IDLE`: san sang accept flush alloc neu FIFO/memory meta/data san sang.
- `FLUSH_SEND`: doc cac word cua line va dua vao data resizer.

### Signal can xem tren waveform

- `flush_alloc`
- `flush_alloc_ready`
- `flush_busy`
- `flush_data_read`
- `flush_mem_req_write_valid`
- `flush_mem_req_write_addr`
- `flush_ack`
- `flush_ack_nline`

### Bug de xay ra

- Dirty replacement owner mode van kich `flush_alloc`.
- Flush ack bi nham voi VBUF writeback done trong RTAB/top demux.
- Explicit CMO flush bi hong do VBUF chiem data read port sai uu tien.

## 8. `rtl/src/hpdcache_wbuf.sv`

Trang thai sua doi: phan tich theo code hien tai, khong thay modified trong `git diff` tracked.

### Vai tro goc

WBUF gom/coalesce store write-through hoac uncacheable writes, theo doi hazard voi read/replay, va phat write request/data ra memory.

### Vai tro trong owner mode

WBUF khong phai owner cua dirty replacement. Trong waveform no duoc dung de phan biet:

- WB store hit khong nen tao memory write qua WBUF ngay.
- WT/UC store co the di qua WBUF.
- WBUF hazard van co the lam request replay/stall doc lap voi VBUF.

### Input/output quan trong

- `write_i`
- `write_ready_o`
- `write_addr_i`
- `write_data_i`
- `read_hit_o`
- `replay_open_hit_o`
- `replay_pend_hit_o`
- `replay_sent_hit_o`
- `replay_not_ready_o`
- `mem_req_write_valid_o`
- `mem_req_write_data_valid_o`
- `mem_resp_write_valid_i`

### Logic quan trong

- Directory states: `WBUF_FREE`, `WBUF_OPEN`, `WBUF_PEND`, `WBUF_SENT`.
- Write coalescing/timeout chuyen OPEN sang PEND.
- Memory response chuyen SENT ve FREE.

### Signal can xem tren waveform

- `wbuf_empty`
- `wbuf_full`
- `wbuf_write`
- `wbuf_write_ready`
- `wbuf_read_hit`
- `wbuf_mem_req_write_valid`
- `wbuf_mem_req_write_addr`
- `wbuf_mem_req_write_data_valid`

### Bug de xay ra

- WB store hit bi dua nham vao WBUF/memory ngay.
- WBUF hazard bi nham voi VBUF hazard khi debug replay.
- Arbiter uu tien WBUF lam VBUF write-back bi delay lau; delay hop le nhung can khong mat data.

## 9. `rtl/src/hpdcache_victim_sel.sv`

Trang thai sua doi: phan tich theo code hien tai, khong thay modified trong `git diff` tracked.

### Vai tro goc

Wrapper chon policy victim: direct-mapped, random, hoac PLRU.

### Vai tro trong owner mode

Victim select quyet dinh way nao bi eviction. Neu way dirty, ctrl se kich VBUF owner flow. Do do waveform dirty replacement phai bat dau tu victim select dung.

### Input/output quan trong

- `sel_victim_i`
- `sel_dir_valid_i`
- `sel_dir_wback_i`
- `sel_dir_dirty_i`
- `sel_dir_fetch_i`
- `sel_victim_set_i`
- `sel_victim_way_o`
- `updt_i`, `updt_set_i`, `updt_way_i`

### Signal can xem tren waveform

- `st1_req_cachedir_sel_victim`
- `dir_valid_vector`
- `dir_dirty_vector`
- `dir_fetch_vector`
- `sel_victim_way`
- `victim_way`
- `victim_dirty`

### Bug de xay ra

- Victim way dang fetch van bi chon.
- Victim dirty vector khong match directory.
- Debug test khong ep dung same-set conflict nen khong tao dirty eviction that.

## 10. `rtl/src/hpdcache_victim_plru.sv`

Trang thai sua doi: phan tich theo code hien tai, khong thay modified trong `git diff` tracked.

### Vai tro goc

Pseudo-LRU replacement policy. Moi set co vector `plru_q`; access/update se set bit way vua dung, khi full thi reset theo way hien tai.

### Vai tro trong owner mode

PLRU chon candidate victim sau khi uu tien invalid, PLRU clean/dirty theo code hien tai:

1. Uu tien unused way: `~fetch & ~valid`.
2. Sau do PLRU way: `~fetch & valid & ~plru_q`.
3. Sau do clean way.
4. Sau do dirty way.

Neu cuoi cung victim dirty, VBUF owner phai capture truoc refill.

### Input/output quan trong

- `updt_i`
- `updt_set_i`
- `updt_way_i`
- `sel_dir_valid_i`
- `sel_dir_dirty_i`
- `sel_dir_fetch_i`
- `sel_victim_set_i`
- `sel_victim_way_o`
- `plru_q` neu duoc trace.

### Signal can xem tren waveform

- `victim_plru_i.plru_q`
- `unused_ways`
- `plru_ways`
- `clean_ways`
- `dirty_ways`
- `sel_victim_way_o`

### Bug de xay ra

- Test khong update PLRU nhu mong doi nen victim khac voi ke hoach.
- Dirty way duoc chon khi van con invalid/clean way, can kiem tra vector valid/fetch/dirty.
- PLRU state khong trace trong `.gtkw`, kho giai thich victim neu thieu signal.

## 11. `rtl/src/hpdcache_rtab.sv`

Trang thai sua doi: phan tich theo code hien tai, khong thay modified trong `git diff` tracked.

### Vai tro goc

RTAB giu cac request bi replay do dependency: MSHR full/hit, directory unavailable/fetch, WBUF hazard, flush hit/not ready, fence/pending transaction.

### Vai tro trong owner mode

RTAB them/giu dependency VBUF:

- Request gap line dang trong VBUF co the bi dua vao RTAB voi `vbuf_hit`.
- Dependency `vbuf_hit` duoc clear khi VBUF write-back ack dung nline: `vbuf_ack_i & (vbuf_ack_nline_i == nline)`.
- Sau clear dependency, request co the replay.

### Input/output quan trong

- `alloc_i`, `alloc_deps_i`
- `deps_q[*].vbuf_hit`
- `vbuf_ack_i`
- `vbuf_ack_nline_i`
- `pop_try_valid_o`
- `pop_commit_i`
- `pop_rback_i`
- `check_hit_o`

### Logic quan trong

- `match_vbuf_nline[i] = (vbuf_ack_nline_i == nline[i])`.
- `deps_rst[i].vbuf_hit = vbuf_ack_i & match_vbuf_nline[i]`.
- `ready = valid_q & head_q & nodeps`.

### Signal can xem tren waveform

- `rtab_alloc`
- `rtab_alloc_deps_vbuf_hit`
- `rtab_deps_q`
- `rtab_vbuf_ack`
- `rtab_vbuf_ack_nline`
- `rtab_pop_try_valid`
- `rtab_pop_commit`
- `rtab_pop_rback`

### Bug de xay ra

- VBUF ack dung nhung RTAB dependency khong clear do nline mismatch.
- Request hazard cung nline khong vao RTAB, chay qua khi dirty line con trong VBUF.
- Pop/replay xay ra truoc writeback_done neu thiet ke yeu cau stall den done.

## 12. Memory write arbiter / memory interface

File chinh da doc:

- `rtl/src/utils/hpdcache_mem_req_write_arbiter.sv`
- Top-level ket noi trong `rtl/src/hpdcache.sv`

Trang thai sua doi: arbiter utility phan tich theo code hien tai; top-level ket noi VBUF co trong `git diff`.

### Vai tro goc

Arbiter chon mot trong nhieu write sources de phat memory request va data. Grant request duoc dua vao FIFO de dam bao data beats di theo dung source da grant.

### Vai tro trong owner mode

VBUF la mot write source moi ben canh WBUF, flush va UC. Owner write-back duoc xac nhan bang:

1. `vbuf_mem_req_write_valid` len.
2. Arbiter grant VBUF port.
3. Memory request address la old victim nline.
4. Data beats tu VBUF di ra memory.
5. Response demux ve VBUF.

### Signal can xem tren waveform

- `mem_req_write_vbuf_valid`
- `mem_req_write_vbuf_ready`
- `mem_req_write_vbuf_addr`
- `mem_req_write_vbuf_data_valid`
- `mem_req_write_vbuf_data_ready`
- `mem_req_write_vbuf_data`
- `mem_req_write_valid`
- `mem_req_write_addr`
- `mem_req_write_data_valid`
- `mem_resp_write_valid`
- `mem_resp_write_id`
- `mem_resp_write_vbuf_valid`

### Bug de xay ra

- VBUF request valid nhung khong bao gio ready do arbitration/backpressure.
- Request channel grant VBUF nhung data channel lai lay source khac, gay corrupt write-back.
- Write response ID demux sai, VBUF khong free entry.
- Dia chi write-back la new line address thay vi old victim address.

## Lien ket waveform theo module

Khi mo waveform, nen doc theo thu tu:

1. `ctrl_pe`: phat hien miss/hit, dirty victim, quyet dinh VBUF/flush/MSHR.
2. `victim_sel` / `memctrl`: victim way/tag/dirty co dung khong.
3. `vbuf`: alloc -> capture -> safe -> writeback -> done.
4. `miss_handler`: refill chi bat dau sau safe.
5. `memory arbiter`: VBUF write request/data/response.
6. `rtab`: request hazard/replay duoc clear dung luc.
7. `flush`: dam bao dirty replacement owner mode khong di qua flush, nhung CMO explicit van con dung flush neu test co.

