# Missing / recommended signals for GTKWave

File `.gtkw` da doc:

- `rtl/tb/scripts/gtkwave/wb_all_cases_one_file.gtkw`

Ghi chu: user ban dau nhac `scripts/gtkwave/wb_all_cases_one_file.gtkw`, nhung trong repo hien tai file thuc te nam duoi `rtl/tb/scripts/gtkwave/wb_all_cases_one_file.gtkw`.

Danh sach duoi day la cac signal nen them vao GTKWave neu da co san trong VCD/FST. Neu GTKWave khong tim thay signal trong dump, can them trace/dump scope tu testbench/sim config. Khong can va khong nen sua RTL chi de debug waveform neu signal da ton tai trong hierarchy.

## 1. CPU/core request side

| Signal can them | Module/scope du kien | Ly do can xem | Case lien quan |
|---|---|---|---|
| Core request valid/ready | core requester / TB / `hpdcache` top request interface | Xac dinh cycle request that su duoc accept | A, B, C, D, E, G |
| Core request opcode/type | core requester / TB / `hpdcache` top request interface | Phan biet load/store/CMO/prefetch | A-H |
| Core request address | core requester / TB / `hpdcache` top request interface | Kiem tra same-set/different-tag va old/new line | B, C, D, E, G |
| Core request wdata/be | core requester / TB / `hpdcache` top request interface | Doi pattern store voi data array/VBUF write-back | A, C, E, G |
| Core response valid/ready | `hpdcache_ctrl` response path / top | Biet request nao da tra loi | A, B, C, G |
| Core response data/error | `hpdcache_ctrl` response path / top | Kiem tra load forwarding va refill data | B, D, G |
| Test case marker/id | TB neu co | De zoom dung case trong one-file waveform | A-H |

## 2. Victim select / PLRU

| Signal can them | Module/scope du kien | Ly do can xem | Case lien quan |
|---|---|---|---|
| `sel_victim_i` | `hpdcache_victim_sel` | Biet luc nao policy dang chon victim | B, C, D, E |
| `sel_victim_set_i` | `hpdcache_victim_sel` | Xac nhan miss cung set can ep conflict | B, C, D, E |
| `sel_victim_way_o` | `hpdcache_victim_sel` | Xac nhan way bi evict | B, C, D, E |
| `sel_dir_valid_i` | `hpdcache_victim_sel` | Biet co invalid way khong | B, C, D, E |
| `sel_dir_dirty_i` | `hpdcache_victim_sel` | Chung minh victim dirty/clean | D, E |
| `sel_dir_wback_i` | `hpdcache_victim_sel` | Phan biet write-back line voi policy khac | A-E |
| `sel_dir_fetch_i` | `hpdcache_victim_sel` | Kiem tra khong chon way dang fetch | D, E, F |
| `plru_q` | `hpdcache_victim_plru` | Giai thich vi sao PLRU chon way do | D, E |
| `unused_ways`, `plru_ways`, `clean_ways`, `dirty_ways` | `hpdcache_victim_plru` | Kiem tra thu tu uu tien invalid -> PLRU -> clean -> dirty | B, C, D, E |

## 3. Directory/tag/dirty metadata

| Signal can them | Module/scope du kien | Ly do can xem | Case lien quan |
|---|---|---|---|
| Victim valid | `hpdcache_memctrl` / ctrl st1 signal | Phan biet invalid/clean/dirty victim | B, C, D, E |
| Victim wback | `hpdcache_memctrl` / ctrl st1 signal | Kiem tra victim thuoc write-back policy | D, E |
| Victim dirty | `hpdcache_memctrl` / ctrl st1 signal | Dieu kien vao VBUF owner eviction | D, E |
| Victim tag | `hpdcache_memctrl` / ctrl st1 signal | Tinh old victim address write-back | D, E |
| Victim way | `hpdcache_memctrl` / ctrl st1 signal | Doi voi VBUF alloc way va data read way | D, E |
| Directory valid vector | `hpdcache_memctrl` | Giai thich vi sao khong chon invalid way | B, C, D, E |
| Directory dirty vector | `hpdcache_memctrl` | Chung minh line da dirty truoc eviction | A, D, E |
| Directory tag array read value | `hpdcache_memctrl` | Kiem tra old/new tag | D, E |
| Directory write enable/value | `hpdcache_memctrl` | Kiem tra dirty set/clear va fetch update | A, B, C, E |

## 4. VBUF alloc metadata and internal state

| Signal can them | Module/scope du kien | Ly do can xem | Case lien quan |
|---|---|---|---|
| `alloc_tag_i` / captured tag | `hpdcache_vbuf` | Kiem tra old victim tag | D, E |
| `alloc_set_i` / captured set | `hpdcache_vbuf` | Kiem tra same-set conflict | D, E |
| `alloc_way_i` / captured way | `hpdcache_vbuf` | Kiem tra VBUF doc dung way victim | D, E |
| `state_q` | `hpdcache_vbuf` | Thay ro IDLE/CAPTURE/READY/MEM_REQ/MEM_DATA/WAIT_RESP | D, E, F, G |
| `beat_count_q` | `hpdcache_vbuf` | Kiem tra capture du cac beat | D, E |
| `wb_beat_count_q` | `hpdcache_vbuf` | Kiem tra write-back du cac beat | D, E |
| `victim_line_q` | `hpdcache_vbuf` | So sanh data captured voi data write-back | D, E, G |
| `valid_q` | `hpdcache_vbuf` | Entry valid/free | D, E, F, G |
| `safe_valid_q` | `hpdcache_vbuf` | Phan biet safe pulse/status voi consume | D, E |

## 5. Flush path separation

| Signal can them | Module/scope du kien | Ly do can xem | Case lien quan |
|---|---|---|---|
| `flush_alloc_i` | `hpdcache_flush` / top | Dirty replacement owner mode khong nen alloc flush | D, E, H |
| `flush_alloc_nline_i` | `hpdcache_flush` | Phan biet explicit flush voi dirty replacement | H |
| `flush_alloc_way_i` | `hpdcache_flush` | Xem way flush neu CMO explicit | H |
| `flush_fsm_q` | `hpdcache_flush` | Biet flush co that su dang send khong | H |
| `flush_mem_req_wmeta.mem_req_addr` | `hpdcache_flush` | So sanh voi VBUF write-back address | D, E, H |

## 6. RTAB / replay / hazard

| Signal can them | Module/scope du kien | Ly do can xem | Case lien quan |
|---|---|---|---|
| `alloc_deps_i.vbuf_hit` | `hpdcache_rtab` | Kiem tra request hazard voi line trong VBUF duoc replay | F, G |
| `deps_q[*].vbuf_hit` | `hpdcache_rtab` | Xem dependency co duoc giu khong | F, G |
| `vbuf_ack_i` | `hpdcache_rtab` | Clear dependency khi VBUF write-back done | F, G |
| `vbuf_ack_nline_i` | `hpdcache_rtab` | Kiem tra clear dung line | F, G |
| `pop_try_valid_o` | `hpdcache_rtab` | Request replay lai khi dependency clear | F, G |
| `pop_commit_i`, `pop_rback_i` | `hpdcache_rtab` | Replay thanh cong hay rollback | F, G |

## 7. Memory arbiter / response demux

| Signal can them | Module/scope du kien | Ly do can xem | Case lien quan |
|---|---|---|---|
| Arbiter grant vector request | `hpdcache_mem_req_write_arbiter` | Xem VBUF co duoc grant khong | D, E |
| Arbiter grant vector data | `hpdcache_mem_req_write_arbiter` | Dam bao data beat tu dung source VBUF | D, E |
| Merged memory write address | top memory interface | Xem address that ra memory | D, E |
| Merged memory write data | top memory interface | Xem data that ra memory | D, E |
| Memory write response id | top memory interface | Xac dinh demux ve VBUF/flush/WBUF | D, E |
| VBUF response demux valid | top / VBUF response path | VBUF free dung luc | D, E |

## 8. De xuat cach them vao GTKWave

Nen them theo thu tu uu tien:

1. Victim metadata: valid/wback/dirty/tag/way.
2. VBUF internal state/counters/metadata.
3. PLRU/vector signals neu victim way khong dung mong doi.
4. Raw CPU request/response neu kho map case.
5. RTAB dependency neu case hazard/forwarding khong ro.
6. Memory arbiter grant/response id neu VBUF write request co nhung entry khong free.

Chua tao ban copy `.gtkw` de xuat trong buoc nay vi can mo dump/VCD thuc te de xac nhan cac path hierarchy chinh xac. Neu cac signal tren da co san trong VCD, chi can add tu GTKWave search/SST vao group tuong ung, khong sua RTL.

