# 03 - CV32E40P + HPDCache D-Cache Basic Result

Date: 2026-05-26

## Scope

Phase nay tich hop CV32E40P that voi HPDCache write-back + VBUF tren data path.

```text
CV32E40P instruction port -> instruction memory model truc tiep

CV32E40P data port
  -> cv32_data_to_hpdcache_adapter
  -> hpdcache_cv32_wrapper
  -> HPDCache WB + VBUF
  -> simple line data memory model
```

Chua tich hop I-Cache trong phase nay.

## Files read

- `rtl/cv32e40p_top.sv`
- `rtl/l1_cache/work/rtl/cv32_data_to_hpdcache_adapter.sv`
- `rtl/l1_cache/work/rtl/hpdcache_cv32_wrapper.sv`
- `rtl/l1_cache/work/rtl/cv32e40p_l1_dcache_top.sv`
- `rtl/l1_cache/work/tb/tb_cv32e40p_dcache_basic.sv`
- `rtl/l1_cache/work/hpdcache_patched/src/hpdcache.sv`
- `rtl/l1_cache/work/hpdcache_patched/src/head_hpdcache_vbuf.sv`
- `rtl/l1_cache/work/hpdcache_patched/src/head_hpdcache_ctrl.sv`
- `rtl/l1_cache/logs/error.log`
- `rtl/l1_cache/logs/03_cv32_dcache_basic.log`

## Files created or modified

- Created/updated `rtl/l1_cache/work/rtl/cv32e40p_l1_dcache_top.sv`
- Created/updated `rtl/l1_cache/work/tb/tb_cv32e40p_dcache_basic.sv`
- Created/updated `rtl/l1_cache/work/sim/cv32e40p_dcache_basic.f`
- Created/updated `rtl/l1_cache/work/sim/run_cv32_dcache_basic.sh`
- Modified `rtl/l1_cache/work/hpdcache_patched/src/hpdcache.sv`
  - Removed invalid VBUF forward-port connections for current `head_hpdcache_vbuf.sv`.
  - Set `VBUF_CV32_DEBUG_TIEOFF = 1'b0` so the real VBUF instance is elaborated.

No original CV32E40P RTL file was modified. No file under `rtl/l1_cache/original`
was modified.

## Commands run

Ubuntu command flow:

```bash
bash rtl/l1_cache/work/sim/run_cv32_dcache_basic.sh
```

All stdout/stderr was appended to:

```text
rtl/l1_cache/logs/error.log
```

Phase-specific log:

```text
rtl/l1_cache/logs/03_cv32_dcache_basic.log
```

## Result

PASS.

Latest log marker:

```text
[PHASE3][PASS] CV32E40P + HPDCache basic done cycles=90 loads=3 stores=5 mem_reads=5 mem_writes=2 read_miss=5 write_miss=4
```

Waveform:

```text
rtl/l1_cache/work/waves/03_cv32_dcache_basic.vcd
```

Latest VCD size:

```text
830K
```

## Behavior observed

- Core fetch instruction duoc, vi chuong trinh da chay den DONE store.
- Core phat data load/store qua CV32 data interface.
- Adapter nhan request CV32 va tra `data_gnt`/`data_rvalid` du de core tiep tuc.
- HPDCache wrapper compile/elaborate voi patched HPDCache WB + VBUF.
- Data memory model nhan refill read va write-back write.
- Simulation ket thuc bang DONE flag, khong timeout.

## Important fix

Truoc khi pass, sim bi timeout:

```text
[PHASE3][FAIL] timeout cycles=2990 loads=2 stores=3 mem_reads=2 mem_writes=735 read_miss=2 write_miss=2
```

Nguyen nhan gan nhat: `VBUF_CV32_DEBUG_TIEOFF = 1'b1` lam VBUF bi tie-off,
nhung controller van phat `ctrl_vbuf_alloc`, dan den dirty victim/write-back
lap lien tuc. Doi sang instantiate VBUF that (`1'b0`) giup sim pass.

## GTKWave command

Trong Ubuntu:

```bash
ROOT_WORKSPACE=$(find /media -maxdepth 8 -type d -name "cv32e40p-master" 2>/dev/null | grep "/work/" | head -n 1)
gtkwave "$ROOT_WORKSPACE/rtl/l1_cache/work/waves/03_cv32_dcache_basic.vcd" &
```

## Remaining risk

- Day moi la basic bring-up, chua phai full verification.
- Hit/miss/event counters can duoc validate lai bang waveform.
- VBUF da duoc instantiate, nhung can checklist rieng de xem `vbuf_alloc`,
  `vbuf_entry_ready`, `vbuf_writeback_done`, dirty victim va memory write-back.
- Test hien tai nho; can random smoke va conflict/dirty eviction stress sau.

## Next step

Tao waveform checklist va GTKWave save file de debug cac nhom tin hieu:
CV32 instruction path, CV32 data path, adapter, HPDCache, VBUF va memory side.
