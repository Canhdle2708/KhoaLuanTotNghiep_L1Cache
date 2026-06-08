# P7 I-Cache Functional Coverage Result

## Scope

- Included: Group B I-Cache checks `ICACHE_CK_01..ICACHE_CK_07` from `TESTPLAN_WRITEBACK_VBUF.md`.
- Excluded: none for Phase 2 Group B. Full A/C/D/E/F/G/H coverage is Phase 3.

## Environment

- Tool: Verilator
- HPDCACHE_SRC_MODE: base
- I-Cache source: CVA6 I-Cache full source from `rtl/l1_cache/cva6_icache_full`
- D-Cache source: HPDCache base/reference path selected by `hpdcache_src_mode.sh`

## Terminal Output Policy

The suite terminal output is intentionally short: `[COV_TABLE]`, `CheckID,Group,Status`, one summary line, and log/CSV paths. Verilator/g++ output and detailed `[COV_RESULT]` lines are redirected to the full log.

## Paths

- Full log: `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/logs/l1_icache_func_cov.log`
- CSV: `/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/logs/l1_icache_func_cov_results.csv`

## Benchmarks

- `icache_basic`: directed sequential fetch program with RESULT marker `0x00000154`, DONE marker, cold I-Cache miss/refill, refill return, instruction response checking, and identity translation monitor.

## Methodology Correction

The first Phase 2 implementation emitted only four rows (`FL1_IC_001..FL1_IC_004`), which came from the local Full L1 draft and did not match the user full testplan. The current runner emits the seven exact Group B CheckID rows from `TESTPLAN_WRITEBACK_VBUF.md`:

| CheckID | Required evidence |
|---|---|
| `ICACHE_CK_01` | First fetch cold miss and no wrong instruction |
| `ICACHE_CK_02` | I-Cache memory read/refill and correct instruction response |
| `ICACHE_CK_03` | Fetch same address again after refill hits, proven by repeated-address response and hit proxy |
| `ICACHE_CK_04` | Hit response does not issue duplicate memory read for the hit line |
| `ICACHE_CK_05` | Sequential same-line and next-line fetch with correct instruction data |
| `ICACHE_CK_06` | Branch/redirect does not commit old-path response and target path completes correctly |
| `ICACHE_CK_07` | Fetch-only miss/hit sequence does not create D-Cache/VBUF write activity |

## Coverage Matrix

| CheckID | Group | BENCH_NAME | Status | Evidence |
|---|---|---|---|---|
| ICACHE_CK_01 | B | icache_basic | PASS | required=first_fetch_cold_miss;no_wrong_instruction; observed=done=1;checksum=1;miss=8;instr_mismatch=0; reason=NONE |
| ICACHE_CK_02 | B | icache_basic | PASS | required=memory_read;refill;correct_instruction_response; observed=done=1;checksum=1;l1_read_req=8;l1_read_rsp=8;refill_req=8;refill_done=8;instr_rsp=35;instr_mismatch=0; reason=NONE |
| ICACHE_CK_03 | B | icache_basic | PASS | required=fetch_same_address_again_hits;correct_response; observed=done=1;checksum=1;repeated_fetch_addr=6;hit_proxy=27;instr_mismatch=0; reason=NONE |
| ICACHE_CK_04 | B | icache_basic | PASS | required=hit_response;no_new_memory_read_for_hit_line; observed=done=1;checksum=1;repeated_fetch_addr=6;duplicate_l1_read_line=0;l1_read_req=8; reason=NONE |
| ICACHE_CK_05 | B | icache_basic | PASS | required=sequential_same_line;sequential_next_line;correct_offset_data; observed=done=1;checksum=1;same_line_seq=25;next_line_seq=6;instr_mismatch=0; reason=NONE |
| ICACHE_CK_06 | B | icache_basic | PASS | required=branch_redirect_no_old_path_commit;target_response_correct; observed=done=1;checksum=1;bad_path_store=0;repeated_fetch_addr=6;instr_mismatch=0; reason=NONE |
| ICACHE_CK_07 | B | icache_basic | PASS | required=fetch_only_miss_hit;no_dcache_dirty_or_vbuf_activity; observed=done=1;checksum=1;fetch_only_dcache_activity=0;fetch_only_vbuf_or_write=0;miss=8;hit_proxy=27; reason=NONE |

## Summary

[COV_SUMMARY] total=7 pass=7 fail=0 not_run=0 instrumentation_missing=0 excluded=0

## Known Limitations

- Direct CVA6 I-Cache hit signal is not exposed. `ICACHE_CK_03` and `ICACHE_CK_04` use a repeated-address response plus no-duplicate-line-read proxy.
- Redirect is checked with a taken-branch program that would write an early bad DONE marker if the old path commits. A dedicated redirect signal is not exposed.

## Next Step

- If strict direct-hit evidence is required, expose a debug-only I-Cache hit/refill event from the wrapper or add a stable hierarchical monitor point.
- Add a directed flush/fence.i benchmark after the Full L1 top provides a testbench-controlled flush input or supported stimulus path.
