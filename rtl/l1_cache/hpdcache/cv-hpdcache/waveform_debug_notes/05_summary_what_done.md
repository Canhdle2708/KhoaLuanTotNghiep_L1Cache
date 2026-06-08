# 05 - Tom tat kien thuc da lam duoc

## 1. Repo hien tai chuyen sang write-back co VBUF owner nhu the nao

Theo `git diff`, cac thay doi tracked tap trung o:

- `rtl/src/hpdcache_vbuf.sv`
- `rtl/src/hpdcache.sv`
- `rtl/src/hpdcache_ctrl.sv`
- `rtl/src/hpdcache_ctrl_pe.sv`

Flow moi can hieu la:

1. Store cacheable duoc ep theo write-back policy.
2. Store hit khong ghi memory ngay, ma update data array va set metadata `dirty=1`, `wback=1`.
3. Khi miss can replacement, victim selection chon way.
4. Neu victim clean/invalid, refill co the di tiep binh thuong.
5. Neu victim dirty, owner mode khong de `hpdcache_flush` lam owner cua dirty replacement.
6. Ctrl allocate VBUF de capture old victim line.
7. VBUF bao `safe_to_overwrite` sau khi capture xong.
8. Ctrl/miss handler moi duoc cho refill/overwrite old way.
9. VBUF tu phat write-back old victim line ra memory.
10. Sau memory response, VBUF free entry va bao `writeback_done`.

Duong quan trong nhat tren waveform:

`victim_dirty` -> `vbuf_alloc` -> `vbuf_capture_done` / `vbuf_safe_to_overwrite` -> `refill` -> `vbuf_mem_write` -> `vbuf_writeback_done` -> `vbuf_free`.

## 2. Dirty bit duoc dung de quyet dinh eviction/write-back ra sao

Dirty bit nam trong directory metadata cua moi way.

- Store hit write-back: line dang valid duoc update data array va set `dirty=1`.
- Store miss write-allocate: sau refill/store, line moi phai co `dirty=1`.
- Load miss clean refill: line moi thuong clean, tru khi request/merge lam dirty.
- Dirty victim miss: neu `dir_victim_dirty=1`, line cu phai duoc preserve truoc overwrite.

Trong owner mode, `dir_victim_dirty=1` la dieu kien bat buoc de vao VBUF owner replacement path.

Neu waveform sai:

- Dirty bit khong set sau store hit -> nghi `hpdcache_ctrl_pe.sv` hoac directory update trong `hpdcache_memctrl.sv`.
- Dirty victim bi xem la clean -> nghi victim metadata/vector/way mapping.
- Dirty bit line moi khong dung sau refill -> nghi `hpdcache_miss_handler.sv` hoac ctrl metadata update.

## 3. PLRU chon victim way ra sao

Theo `hpdcache_victim_plru.sv`, victim selection uu tien:

1. Invalid/not-fetch way.
2. Valid PLRU candidate.
3. Clean way.
4. Dirty way.

Nghia la dirty eviction chi nen xay ra khi khong con invalid/clean candidate phu hop, hoac test da ep PLRU/same-set conflict de chon dirty way.

Khi debug waveform, neu khong thay dirty eviction:

- Kiem tra dia chi test co cung set khong.
- Kiem tra PLRU update way co dung khong.
- Kiem tra valid/dirty/fetch vector cua set do.
- Kiem tra victim way co phai way vua duoc lam dirty khong.

## 4. VBUF owner khac shadow mode ra sao

Owner mode:

- VBUF tu doc data array cua victim.
- VBUF tu capture line.
- VBUF tu bao `safe_to_overwrite`.
- VBUF tu phat write-back memory.
- Dirty replacement miss khong phu thuoc `hpdcache_flush`.

Shadow/non-owner style:

- Flush path co the la nguon doc/write-back chinh.
- VBUF co the chi theo doi/capture phu tro theo flush ack.

Trong repo hien tai, top-level co `VBUF_REPLACEMENT_OWNER_EN = 1'b1`, nen expectation khi dirty replacement la:

- `st2_vbuf_alloc` phai bat.
- `st2_flush_alloc` khong nen bat cho dirty replacement owner path.
- `vbuf_mem_req_write_valid` la nguon write-back cua old dirty victim.

## 5. Co che write-back dung ky vong la gi

Write-back dung ky vong phai thoa cac diem sau:

- Store hit chi update cache va set dirty, khong memory write ngay.
- Dirty victim khong bi overwrite truoc khi VBUF capture xong.
- VBUF write-back address la old victim nline/tag, khong phai new miss address.
- VBUF write-back data la old dirty line da update moi nhat.
- Refill/overwrite way chi xay ra sau `safe_to_overwrite` / `capture_done`.
- VBUF entry free sau memory response.
- Neu request dung old nline khi line dang trong VBUF, thiet ke phai forward dung data hoac stall/replay dung cach.
- Explicit flush/clean/invalidate van co the dung `hpdcache_flush`, nhung dirty replacement owner path khong nen do flush lam owner.

## 6. Nhung case waveform can chung minh

Case nen xem theo thu tu uu tien:

1. Store hit WB: dirty bit set, khong co memory write ngay.
2. Clean/invalid victim miss: refill binh thuong, khong VBUF write-back.
3. Dirty victim miss: VBUF alloc va capture truoc overwrite.
4. VBUF capture/safe: `capture_done` va `safe_to_overwrite` den truoc refill overwrite.
5. VBUF memory write-back: old address/data di ra memory, response ve, entry free.
6. Same-line hazard/RTAB: request dung line trong VBUF bi forward hoac replay/stall dung cach.
7. VBUF load forwarding: `vbuf_fwd_req`, `vbuf_fwd_hit`, `vbuf_fwd_data`, response data.
8. Explicit flush/CMO: flush path hoat dong rieng, khong bi lan voi dirty replacement owner path.

## 7. Nhung rui ro con lai

Rui ro can dac biet de y khi xem waveform:

- `.gtkw` hien tai chua co day du raw CPU request handshake/opcode, nen viec map case co the dua vao marker/test signal neu co.
- `.gtkw` hien tai chua co day du PLRU internals va directory valid/dirty vector, nen neu victim way bat ngo thi can them signal.
- VBUF depth hien tai la 1; test VBUF full/backpressure can ky vong stall/replay ro rang.
- Memory write response ID/demux la diem de sai neu VBUF write request da ra nhung VBUF khong free.
- Forwarding chi dung neu word index va nline match dung; can so `vbuf_fwd_data` voi pattern dirty store.
- Neu simulation VCD khong dump internal signals, can them trace scope/testbench dump, nhung khong sua RTL trong nhiem vu nay.

## 8. File da tao trong `waveform_debug_notes`

- `01_gtkwave_signal_map.md`: map signal trong `.gtkw` theo module va y nghia.
- `02_wb_all_cases_waveform_guide.md`: cach xem waveform cho tung case A-H.
- `03_wb_waveform_checklist.md`: checklist tick tay khi mo GTKWave.
- `04_modified_modules_explanation.md`: giai thich module lien quan, tach ro file co `git diff` va file phan tich theo code hien tai.
- `05_summary_what_done.md`: file tom tat nay.

