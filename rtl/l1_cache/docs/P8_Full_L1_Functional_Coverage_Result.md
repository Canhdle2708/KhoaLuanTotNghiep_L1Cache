# P8 Full L1 Functional Coverage Result

## Scope

- Included groups: A, B, C, D, E, F, G, H from `TESTPLAN_WRITEBACK_VBUF.md`.
- Excluded groups: none in Full L1 coverage.

## Environment

- Tool: Verilator
- HPDCACHE_SRC_MODE: base
- I-side path: CV32E40P instruction port -> CVA6 I-Cache -> shared L1 arbiter/memory
- D-side path: CV32E40P data port -> HPDCache wrapper -> shared L1 arbiter/memory

## Coverage Sources

- Group B: `verilator_l1_icache_func_cov_suite`.
- Groups A/C/D/E/F/H: `verilator_full_l1_dcache_func_cov_suite` using Full L1 top, not D-Cache-only status copy.
- Group G: Full L1 smoke, I/D coverage evidence, and perf compare smoke.

## Paths

- Full log: `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/logs/full_l1_func_cov.log`
- CSV: `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/logs/full_l1_func_cov_results.csv`
- I-Cache log: `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/logs/l1_icache_func_cov.log`
- D-Cache Full L1 log: `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/logs/full_l1_dcache_func_cov.log`
- User tee log: `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/logs/P8_full_l1_func_cov_user_rerun4.log`

## Latest User Run

Command:

```bash
make verilator_full_l1_func_cov_suite MAX_CYCLES=100000
```

Result:

```text
[COV_SUMMARY] total=59 pass=59 fail=0 not_run=0 instrumentation_missing=0 excluded=0
```

## Coverage Matrix

| CheckID | Group | BENCH_NAME | Status | Evidence |
|---|---|---|---|---|
| `ICACHE_CK_01` | B | `icache_basic` | PASS | required=first_fetch_cold_miss;no_wrong_instruction; observed=done=1;checksum=1;miss=8;instr_mismatch=0; reason=NONE |
| `ICACHE_CK_02` | B | `icache_basic` | PASS | required=memory_read;refill;correct_instruction_response; observed=done=1;checksum=1;l1_read_req=8;l1_read_rsp=8;refill_req=8;refill_done=8;instr_rsp=35;instr_mismatch=0; reason=NONE |
| `ICACHE_CK_03` | B | `icache_basic` | PASS | required=fetch_same_address_again_hits;correct_response; observed=done=1;checksum=1;repeated_fetch_addr=6;hit_proxy=27;instr_mismatch=0; reason=NONE |
| `ICACHE_CK_04` | B | `icache_basic` | PASS | required=hit_response;no_new_memory_read_for_hit_line; observed=done=1;checksum=1;repeated_fetch_addr=6;duplicate_l1_read_line=0;l1_read_req=8; reason=NONE |
| `ICACHE_CK_05` | B | `icache_basic` | PASS | required=sequential_same_line;sequential_next_line;correct_offset_data; observed=done=1;checksum=1;same_line_seq=25;next_line_seq=6;instr_mismatch=0; reason=NONE |
| `ICACHE_CK_06` | B | `icache_basic` | PASS | required=branch_redirect_no_old_path_commit;target_response_correct; observed=done=1;checksum=1;bad_path_store=0;repeated_fetch_addr=6;instr_mismatch=0; reason=NONE |
| `ICACHE_CK_07` | B | `icache_basic` | PASS | required=fetch_only_miss_hit;no_dcache_dirty_or_vbuf_activity; observed=done=1;checksum=1;fetch_only_dcache_activity=0;fetch_only_vbuf_or_write=0;miss=8;hit_proxy=27; reason=NONE |
| `BASIC_CK_01` | A | `reset_idle` | PASS | required=reset_sequence;all_l1_blocks_idle; observed=reset_idle_violation=0;vbuf_empty_observed=1; reason=NONE |
| `BASIC_CK_02` | A | `reset_idle` | PASS | required=no_icache_response_before_valid_fetch; observed=pre_fetch_resp_violation=0;icache_refill=2; reason=NONE |
| `BASIC_CK_03` | A | `reset_idle` | PASS | required=no_dcache_response_before_valid_request; observed=pre_data_resp_violation=0; reason=NONE |
| `BASIC_CK_04` | A | `reset_idle` | PASS | required=vbuf_empty_not_busy_not_full_after_reset; observed=vbuf_empty_observed=1;vbuf_busy=0;vbuf_full=0; reason=NONE |
| `BASIC_CK_05` | A | `basic_load_store` | PASS | required=first_ifetch_and_first_dload_after_reset; observed=icache_access=17;icache_refill=5;loads=3; reason=NONE |
| `DCACHE_CK_01` | C | `repeated_load` | PASS | required=load_hit_correct_data_after_refill; observed=loads=128;read_miss=1;checksum=1; reason=NONE |
| `DCACHE_CK_02` | C | `repeated_load` | PASS | required=load_hit_no_mshr_alloc_proxy; observed=loads=128;read_miss=1; reason=NONE |
| `DCACHE_CK_03` | C | `repeated_load` | PASS | required=load_hit_no_new_memory_read; observed=mem_read=1;loads=128; reason=NONE |
| `DCACHE_CK_04` | C | `load_miss_variants` | PASS | required=load_miss_allocates_mshr_reads_memory_refills_responds; observed=mem_read=5;refill_done=5;loads=5; reason=NONE |
| `DCACHE_CK_05` | C | `store_hit_dirty` | PASS | required=store_hit_updates_cache_data_array_readback; observed=stores=1;loads=2;mem_write=2; reason=NONE |
| `DCACHE_CK_06` | C | `store_miss_clean_victim` | PASS | required=store_miss_clean_refill_merge_store; observed=write_miss=1;mem_read=1;mem_write=2; reason=NONE |
| `DCACHE_CK_07` | C | `no_deadlock_smoke` | PASS | required=no_double_response_per_dcache_request; observed=double_response=0;loads=3;stores=1; reason=NONE |
| `PLRU_CK_01` | D | `plru_invalid_way` | PASS | required=miss_uses_invalid_way_before_replacement; observed=victim_invalid=4;vbuf_alloc=0; reason=NONE |
| `PLRU_CK_02` | D | `plru_clean_replacement` | PASS | required=full_set_clean_victim_refill_no_vbuf; observed=victim_clean=2;vbuf_alloc=0;mem_write=2; reason=NONE |
| `PLRU_CK_03` | D | `dirty_eviction_vbuf` | PASS | required=dirty_victim_triggers_vbuf_blocks_overwrite_until_safe; observed=victim_dirty=4;vbuf_alloc=1;safe=3; reason=NONE |
| `PLRU_CK_04` | D | `plru_update_after_hit` | PASS | required=plru_state_updates_after_hit; observed=plru_update=4;loads=5; reason=NONE |
| `PLRU_CK_05` | D | `repeated_load` | PASS | required=plru_state_updates_after_refill; observed=refill_dir_write=1;plru_update=1; reason=NONE |
| `PLRU_CK_06` | D | `plru_update_after_hit` | PASS | required=repeated_access_expected_replacement_order; observed=victim_way_onehot=8;victim_select=8; reason=NONE |
| `WB_CK_01` | E | `store_hit_dirty` | PASS | required=cacheable_store_hit_writeback_no_immediate_ram_write; observed=stores=1;vbuf_writeback_done=0;victim_dirty=0;mem_write=2; reason=NONE |
| `WB_CK_02` | E | `dirty_eviction_vbuf` | PASS | required=store_sets_dirty_bit_later_seen_as_dirty_victim; observed=victim_dirty=4;mem_write=3;checksum=1; reason=NONE |
| `WB_CK_03` | E | `store_byte_half_corner` | PASS | required=store_hit_byte_enable_updates_cache_data; observed=byte_store=1;half_store=1;checksum=1; reason=NONE |
| `WB_CK_04` | E | `vbuf_ordering` | PASS | required=store_miss_refill_merge_later_seen_as_dirty_victim; observed=write_miss=1;victim_dirty=5;refill_done=4;checksum=1; reason=NONE |
| `WB_CK_05` | E | `dirty_eviction_vbuf` | PASS | required=dirty_victim_detected_not_overwritten_before_safe; observed=victim_dirty=4;safe=3;vbuf_alloc=1; reason=NONE |
| `WB_CK_06` | E | `vbuf_forward_load` | PASS | required=dirty_eviction_writes_latest_data_no_loss; observed=vbuf_writeback_done=1;checksum=1;loads=4;mem_read=3; reason=NONE |
| `VBUF_CK_01` | F | `dirty_eviction_vbuf` | PASS | required=vbuf_alloc_capture_victim_metadata; observed=vbuf_alloc=1;victim_dirty=4; reason=NONE |
| `VBUF_CK_02` | F | `dirty_eviction_vbuf` | PASS | required=vbuf_requests_data_ram_to_capture_victim; observed=vbuf_capture_start=1; reason=NONE |
| `VBUF_CK_03` | F | `dirty_eviction_vbuf` | PASS | required=vbuf_capture_advances_on_data_ram_read_accept; observed=vbuf_capture_start=1;vbuf_capture_done=00000002; reason=NONE |
| `VBUF_CK_04` | F | `dirty_eviction_vbuf` | PASS | required=vbuf_captures_full_dirty_line_safe_to_overwrite; observed=capture_done=00000002;safe=3; reason=NONE |
| `VBUF_CK_05` | F | `dirty_eviction_vbuf` | PASS | required=mshr_refill_continues_after_safe_to_overwrite; observed=safe=3;refill_done=3; reason=NONE |
| `VBUF_CK_06` | F | `dirty_eviction_vbuf` | PASS | required=vbuf_busy_full_state_after_alloc; observed=vbuf_busy=168;vbuf_full=169; reason=NONE |
| `VBUF_CK_07` | F | `dirty_eviction_vbuf` | PASS | required=vbuf_drain_writeback_done_correct_addr_data; observed=vbuf_writeback_done=1;mem_write=3;first_wb_addr=10000000; reason=NONE |
| `VBUF_CK_08` | F | `multi_dirty_eviction` | PASS | required=no_double_writeback_owner_mode_proxy; observed=vbuf_alloc=2;vbuf_writeback_done=2;mem_write=4;double_response=0; reason=NONE |
| `VBUF_CK_09` | F | `vbuf_forward_load` | PASS | required=load_miss_vbuf_hit_forwards_latest_data; observed=vbuf_forward_hit=1;fwd_req=6;entry_valid=2;nline_match=1;checksum=1; reason=NONE |
| `VBUF_CK_10` | F | `vbuf_forward_load` | PASS | required=load_miss_vbuf_hit_no_extra_mshr_proxy; observed=vbuf_forward_hit=1;fwd_req=6;entry_valid=2;nline_match=1;mem_read=3; reason=NONE |
| `VBUF_CK_11` | F | `vbuf_ordering` | PASS | required=store_miss_vbuf_hit_replay_proxy; observed=write_miss=1;vbuf_alloc=1;stores=2; reason=NONE |
| `VBUF_CK_12` | F | `vbuf_full_backpressure` | PASS | required=vbuf_full_backpressure_blocks_new_dirty_victim_resumes; observed=vbuf_full=338;vbuf_writeback_done=2; reason=NONE |
| `CORNER_CK_01` | H | `load_after_store_same_line` | PASS | required=load_after_store_same_line_latest_data; observed=stores=1;loads=1;checksum=1; reason=NONE |
| `CORNER_CK_02` | H | `vbuf_forward_load` | PASS | required=load_during_vbuf_writeback_same_line_uses_vbuf; observed=vbuf_forward_hit=1;fwd_req=6;entry_valid=2;nline_match=1;checksum=1; reason=NONE |
| `CORNER_CK_03` | H | `vbuf_ordering` | PASS | required=store_during_vbuf_writeback_same_line_replay_proxy; observed=write_miss=1;stores=2;checksum=1; reason=NONE |
| `CORNER_CK_04` | H | `repeated_load` | PASS | required=same_line_repeated_loads_do_not_duplicate_memory_reads; observed=loads=128;mem_read=1; reason=NONE |
| `CORNER_CK_05` | H | `vbuf_ordering` | PASS | required=mshr_hit_request_dependency_proxy; observed=mem_read=4;vbuf_alloc=1;write_miss=1; reason=NONE |
| `CORNER_CK_06` | H | `vbuf_ordering` | PASS | required=after_refill_dependency_clears_replay_correct; observed=refill_done=4;double_response=0; reason=NONE |
| `CORNER_CK_07` | H | `no_deadlock_smoke` | PASS | required=icache_fetch_miss_and_dcache_miss_near_each_other_no_wrong_response; observed=icache_miss=3;dcache_read_miss=2;double_response=0; reason=NONE |
| `CORNER_CK_08` | H | `vbuf_full_backpressure` | PASS | required=back_to_back_dirty_eviction_no_data_loss_deadlock; observed=vbuf_full=338;timeout=0; reason=NONE |
| `CORNER_CK_09` | H | `no_deadlock_smoke` | PASS | required=response_correct_tid_sid_request_id_proxy; observed=double_response=0;mem_read=2;mem_read_rsp=2; reason=NONE |
| `CORNER_CK_10` | H | `no_deadlock_smoke` | PASS | required=no_double_response_or_missing_response; observed=double_response=0;mem_read=2;mem_read_rsp=2; reason=NONE |
| `RISCV_CK_01` | G | `full_l1_basic` | PASS | required=core_instruction_fetch_goes_through_icache; observed=full_l1_basic_pass;icache_path_active; reason=NONE |
| `RISCV_CK_02` | G | `full_l1_basic` | PASS | required=core_load_store_goes_through_hpdcache; observed=full_l1_basic_pass;dcache_path_active; reason=NONE |
| `RISCV_CK_03` | G | `full_l1_random+dcache_cov` | PASS | required=core_to_cache_handshake_no_lost_request_response; observed=full_l1_random_pass;DCACHE_CK_07_PASS;double_response=0;loads=3;stores=1; reason=NONE |
| `RISCV_CK_04` | G | `icache_basic` | PASS | required=small_program_icache_miss_then_hit; observed=ICACHE_CK_03_PASS; reason=NONE |
| `RISCV_CK_05` | G | `full_l1_dcache_cov` | PASS | required=small_program_dcache_hit_miss_writeback_behavior; observed=WB_CK_06_PASS;vbuf_writeback_done=1;checksum=1;loads=4;mem_read=3; reason=NONE |
| `RISCV_CK_06` | G | `perf_compare_3mode` | PASS | required=compare_no_cache_vs_with_cache_memory_traffic_cycles; observed=perf_compare_pass_rows=3; reason=NONE |

## Summary

[COV_SUMMARY] total=59 pass=59 fail=0 not_run=0 instrumentation_missing=0 excluded=0

## Notes

- This suite does not mark PASS from static placeholders. Every non-B/G row is generated from a Full L1 run or from the Full L1 perf compare.
- Several VBUF/RTAB-related checks use the available hierarchical event proxies; if any proxy is insufficient in a run, the row remains FAIL with evidence in CSV/log.
