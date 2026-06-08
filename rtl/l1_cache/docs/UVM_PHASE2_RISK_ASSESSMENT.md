# UVM Phase 2 Risk Assessment

This document is a proposal-only risk assessment for Phase 2.

## Technical Risks

### Store completion semantics

Risk:
- CV32 core data stores are accepted with `data_req && data_gnt && data_we`, but completion/response semantics are not fully proven from current UVM observations.

Impact:
- A strict scoreboard may falsely report missing store responses.

Mitigation:
- In Phase 2, count store accepts first.
- Do not require `data_rvalid` for stores until confirmed.
- Treat store response checks as WARN-only initially.

### Counter definition mismatch

Risk:
- DUT counters may not map one-to-one to UVM-observed txns. Example: `instr_access_count` counts `instr_adapter_req_accept`, not necessarily every raw `instr_req && instr_gnt` if timing differs.

Impact:
- Counter consistency checks can false fail.

Mitigation:
- Compare only counters with confirmed definitions.
- Start with tolerances or WARN-only checks.
- Document every counter mapping in the Phase 2 result doc.

### Split memory write protocol

Risk:
- D-cache memory write has separate address/control, data, and response phases:
  - `mem_req_write_valid/ready/addr`
  - `mem_req_write_data_valid/ready/data/be/last`
  - `mem_resp_write_valid/ready`

Impact:
- Treating a write as one event can lose ordering and produce false pending counts.

Mitigation:
- Model write address, write data, and write response as separate `cv32_l1_mem_txn` event kinds.
- Keep separate pending counters.
- Promote checks only after the basic program is stable.

### Incomplete current memory interface

Risk:
- `cv32_l1_mem_if` currently exposes simplified fields and some unused older names.

Impact:
- Phase 2 mem monitor may miss `ready`, `last`, ID, len, size, and response details unless the interface is extended.

Mitigation:
- Extend `cv32_l1_mem_if` explicitly.
- Connect new fields in `tb_cv32_l1_uvm_top.sv`.
- Keep old fields until all consumers migrate.

## Risk of Breaking Phase 1

Risk:
- Adding transaction classes and ports can introduce compile errors or UVM connection errors.
- Changing test top signal mappings can affect the already passing basic run.

Mitigation:
- Add files in compile-only step first.
- Use explicit filelist order.
- Rerun `run_uvm_full_l1_basic` after every small change.
- Keep Phase 1 final checks intact until the new scoreboard is proven.

## Questa/Coverage Risks

Risk:
- Questa Starter previously rejected `svverification` when SV covergroups/UCDB were enabled.

Impact:
- Enabling covergroups or `-coverage` can break the run before simulation begins.

Mitigation:
- Keep `QUESTA_ENABLE_COVERAGE=0` as default.
- Keep `UVM_USE_SV_COVERGROUPS` undefined by default.
- Use counter/CSV reporting instead of SV functional coverage in Phase 2.
- Do not add `covergroup`, `randomize`, `randcase`, or `randsequence` in Phase 2 unless license is revalidated.

## Signal Path Risks

Risk:
- Top-level visible signals are stable now, but internal HPDCache hierarchy paths can change.

Impact:
- Deep monitors for PLRU/VBUF/MSHR/RTAB can become brittle.

Mitigation:
- Use only HIGH confidence paths in Phase 2.
- Defer LOW confidence deep paths.
- Prefer UVM top mirrored interfaces over direct deep hierarchy when possible.

## Scoreboard False-Fail Risks

Risk:
- Pending request tracking can false fail due to valid/ready timing, store response semantics, or combined I-cache/D-cache memory streams.

Impact:
- Good RTL may fail UVM Phase 2.

Mitigation:
- Implement pending counters per channel.
- Make ambiguous memory write checks warnings first.
- Only fail on clear conditions:
  - response without any pending request on a confirmed channel
  - negative pending count
  - done/pass failure
  - timeout
  - critical X/Z

## Patched HPDCache Risk

Risk:
- Accidentally selecting patched HPDCache could invalidate the baseline and compare against the wrong design.

Impact:
- Phase 2 results would not represent the requested base implementation.

Mitigation:
- Keep `HPDCACHE_SRC_MODE=base`.
- Keep runner guard that rejects patched filelist content.
- Do not touch patched filelists in Phase 2.

## Recommended Risk Controls

Use this control checklist for implementation:

1. Confirm `HPDCACHE_SRC_MODE=base` in every run log.
2. Confirm `Patched HPDCache selected: no`.
3. Confirm `QUESTA_ENABLE_COVERAGE=0`.
4. Confirm compile errors are 0.
5. Confirm UVM_ERROR is 0.
6. Confirm UVM_FATAL is 0.
7. Confirm `[UVM][FULL_L1_BASIC][PASS]`.
8. Confirm `run_uvm_full_l1_basic exit=0`.
9. Confirm `uvm_perf_raw.csv` still contains PASS.
10. Confirm new `uvm_phase2_transaction_counts.csv` is generated only after Phase 2 implementation.

