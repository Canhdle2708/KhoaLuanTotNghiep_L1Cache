# TESTPLAN - CV32E40P D-Cache Integration with HPDCache WB + VBUF

Date: 2026-05-26

## Scope

This testplan covers the D-Cache integration phase:

```text
CV32E40P data port
  -> cv32_data_to_hpdcache_adapter
  -> HPDCache write-back + VBUF
  -> data memory model
```

The instruction path remains direct to instruction memory. I-Cache integration
is out of scope for this phase.

## Current Bring-Up Status

- Baseline original/no-cache simulation: PASS.
- Adapter basic test: PASS.
- CV32E40P + HPDCache basic integration: PASS.
- Random smoke seeds 1, 2, 3: PASS.
- Waveforms exist for basic and random tests.

## Check Items

### Basic Integration

#### ID: BI-01
Scenario: Reset clean
Goal: Verify all major blocks leave reset cleanly.
Stimulus/input: Assert reset for several clocks, then enable fetch.
Expected behavior: Core, adapter, HPDCache, VBUF, and memory model enter idle/ready states.
Signals/waveform: `clk`, `rst_n`, `fetch_enable`, adapter `state_q`, VBUF status, counters.
Pass/fail criteria: No persistent X/Z and no request before reset release.
Performance counter: `cycle_count`.

#### ID: BI-02
Scenario: Core fetch with D-Cache present
Goal: Confirm D-Cache integration does not block instruction fetch.
Stimulus/input: Run the basic program with instruction path direct to IMEM.
Expected behavior: `instr_req`/`instr_gnt`/`instr_rvalid` toggle and `instr_addr` advances.
Signals/waveform: `instr_req`, `instr_gnt`, `instr_rvalid`, `instr_addr`, `instr_rdata`.
Pass/fail criteria: Program reaches data accesses and final DONE store.
Performance counter: `cycle_count`.

#### ID: BI-03
Scenario: Data request reaches adapter
Goal: Verify CV32 data interface connects to the adapter.
Stimulus/input: Execute a load/store program.
Expected behavior: CV32 `data_req` is visible at adapter `cv32_data_req_i`.
Signals/waveform: `data_req`, `data_gnt`, adapter `cv32_data_req_i`, `cv32_data_gnt_o`.
Pass/fail criteria: Every CV32 request gets accepted or held until accepted.
Performance counter: `core_load_count`, `core_store_count`.

#### ID: BI-04
Scenario: Adapter request reaches HPDCache
Goal: Verify adapter drives HPDCache requester interface.
Stimulus/input: Execute at least one load and one store.
Expected behavior: Adapter asserts `hpdcache_req_valid_o`, HPDCache asserts ready.
Signals/waveform: `hpdcache_req_valid_o`, `hpdcache_req_ready_i`, `req_valid_i`, `req_ready_o`.
Pass/fail criteria: No dropped transaction; request fields remain stable until accept.
Performance counter: `core_load_count`, `core_store_count`.

#### ID: BI-05
Scenario: Response returns to core
Goal: Verify HPDCache response maps back to CV32.
Stimulus/input: Execute cacheable load.
Expected behavior: HPDCache response creates CV32 `data_rvalid`.
Signals/waveform: `rsp_valid_o`, adapter `hpdcache_rsp_valid_i`, `data_rvalid`, `data_rdata`.
Pass/fail criteria: Load instruction retires and program continues.
Performance counter: `core_load_count`.

#### ID: BI-06
Scenario: DONE store completion
Goal: Verify testbench can detect program completion.
Stimulus/input: Store to memory-mapped DONE address.
Expected behavior: Top asserts `done` and `pass`.
Signals/waveform: `data_we`, `data_addr`, `done`, `pass`.
Pass/fail criteria: Test prints PASS and exits without timeout.
Performance counter: `cycle_count`.

#### ID: BI-07
Scenario: No valid/ready deadlock
Goal: Check that the integrated path does not hang.
Stimulus/input: Basic and random programs.
Expected behavior: Every seed reaches DONE.
Signals/waveform: CV32 data valid/gnt/rvalid, adapter state, HPDCache req/rsp.
Pass/fail criteria: No timeout; adapter returns to idle after transactions.
Performance counter: `cycle_count`, `evt_stall`.

### Load Path

#### ID: LD-01
Scenario: Load miss
Goal: Verify first access to a cache line causes refill.
Stimulus/input: Load from a cold address.
Expected behavior: HPDCache issues memory read and returns loaded word.
Signals/waveform: `data_req`, `data_we=0`, `evt_cache_read_miss`, `mem_req_read_valid`, `mem_resp_read_valid`.
Pass/fail criteria: Load completes with correct data.
Performance counter: `read_miss_count`, `mem_read_count`.

#### ID: LD-02
Scenario: Load hit
Goal: Verify repeated access hits after refill.
Stimulus/input: Load same word twice.
Expected behavior: Second load completes without new memory read.
Signals/waveform: `data_addr`, `data_rvalid`, `evt_cache_read_miss`, `mem_req_read_valid`.
Pass/fail criteria: Second access has no miss event.
Performance counter: hit count derived from loads minus read misses.

#### ID: LD-03
Scenario: Load same line different word
Goal: Verify line refill serves multiple words.
Stimulus/input: Load word 0 then word 1 in same cache line.
Expected behavior: First access refills, second should hit if line is valid.
Signals/waveform: `data_addr`, refill data, `data_rdata`.
Pass/fail criteria: No additional memory read for same line.
Performance counter: `mem_read_count`.

#### ID: LD-04
Scenario: Load different index
Goal: Verify independent cache indices operate correctly.
Stimulus/input: Load addresses mapping to different sets.
Expected behavior: Each cold line refills once and remains independently valid.
Signals/waveform: `data_addr`, refill set, refill way.
Pass/fail criteria: Returned data matches memory model.
Performance counter: `read_miss_count`.

#### ID: LD-05
Scenario: Load same index different tag
Goal: Exercise conflict access.
Stimulus/input: Load addresses with same index and different tags.
Expected behavior: Cache selects victim/refill path.
Signals/waveform: victim way, refill signals, `evt_cache_read_miss`.
Pass/fail criteria: No deadlock and data is correct after replacement.
Performance counter: `read_miss_count`, `mem_read_count`.

#### ID: LD-06
Scenario: Back-to-back loads
Goal: Verify consecutive load requests are handled.
Stimulus/input: Program emits multiple adjacent `lw` instructions.
Expected behavior: Adapter serializes one outstanding request and returns all responses.
Signals/waveform: adapter `state_q`, `outstanding_tid_q`, `data_rvalid`.
Pass/fail criteria: Load count equals expected program count.
Performance counter: `core_load_count`.

#### ID: LD-07
Scenario: Load with memory latency
Goal: Verify refill works with delayed memory response.
Stimulus/input: Increase memory read latency parameter.
Expected behavior: Core stalls until refill response arrives.
Signals/waveform: `rd_pending_q`, `mem_resp_read_valid`, `data_rvalid`, `evt_stall`.
Pass/fail criteria: No timeout and correct data.
Performance counter: `cycle_count`, `evt_stall`.

#### ID: LD-08
Scenario: Load after store same address
Goal: Verify store-to-load visibility.
Stimulus/input: Store a value, then load the same address.
Expected behavior: Load returns newly stored value.
Signals/waveform: `data_wdata`, `data_rdata`, dirty bit/update signals.
Pass/fail criteria: Loaded value equals stored value.
Performance counter: `core_load_count`, `core_store_count`.

### Store Path

#### ID: ST-01
Scenario: Store hit
Goal: Verify store updates an existing line.
Stimulus/input: Refill line, then store to same line.
Expected behavior: Store updates data array and dirty state.
Signals/waveform: `data_we`, `data_be`, data write signals, dirty update.
Pass/fail criteria: Later load returns stored value.
Performance counter: `core_store_count`.

#### ID: ST-02
Scenario: Store miss write-allocate
Goal: Verify store miss allocates/refills line when policy requires.
Stimulus/input: Store to a cold cacheable address.
Expected behavior: Miss/refill path runs and store data is merged.
Signals/waveform: `evt_cache_write_miss`, `mem_req_read_valid`, refill write data.
Pass/fail criteria: Later load returns stored value.
Performance counter: `write_miss_count`, `mem_read_count`.

#### ID: ST-03
Scenario: Store word
Goal: Verify full word write.
Stimulus/input: `sw` with `data_be=4'b1111`.
Expected behavior: All four bytes update.
Signals/waveform: `data_be`, `data_wdata`, cache write data.
Pass/fail criteria: Readback matches full word.
Performance counter: `core_store_count`.

#### ID: ST-04
Scenario: Store byte enable
Goal: Verify partial byte store handling.
Stimulus/input: Byte store sequence if generated by program/TB.
Expected behavior: Only selected byte changes.
Signals/waveform: `data_be`, write data merge signals.
Pass/fail criteria: Readback preserves untouched bytes.
Performance counter: `core_store_count`.

#### ID: ST-05
Scenario: Store halfword
Goal: Verify partial halfword store handling.
Stimulus/input: Halfword store sequence if generated by program/TB.
Expected behavior: Selected two bytes update.
Signals/waveform: `data_be`, write data merge signals.
Pass/fail criteria: Readback matches expected halfword merge.
Performance counter: `core_store_count`.

#### ID: ST-06
Scenario: Store multiple words same line
Goal: Verify several stores to one cache line.
Stimulus/input: Store to word offsets 0, 4, 8, 12 of one line.
Expected behavior: Cache line accumulates all updates and remains dirty.
Signals/waveform: `data_addr`, data array write, dirty status.
Pass/fail criteria: Readback of all words matches expected values.
Performance counter: `core_store_count`.

#### ID: ST-07
Scenario: Back-to-back stores
Goal: Verify consecutive stores are accepted without deadlock.
Stimulus/input: Program emits multiple adjacent `sw` instructions.
Expected behavior: Adapter/HPDCache accept all stores.
Signals/waveform: `data_req`, `data_gnt`, adapter state, `evt_cache_write_miss`.
Pass/fail criteria: Store count equals expected program count.
Performance counter: `core_store_count`.

#### ID: ST-08
Scenario: Store same index different tag
Goal: Exercise store conflict replacement.
Stimulus/input: Store to addresses mapping to same set and different tags.
Expected behavior: Dirty victim path can be triggered.
Signals/waveform: victim way, dirty victim, VBUF alloc, write-back.
Pass/fail criteria: No deadlock; later reloads return correct data.
Performance counter: `write_miss_count`, `mem_write_count`.

### Dirty / Write-Back

#### ID: DW-01
Scenario: Dirty bit set after store
Goal: Verify write-back policy marks line dirty.
Stimulus/input: Store to cacheable line.
Expected behavior: Dirty state is set for target line.
Signals/waveform: dirty update signals, directory update signals.
Pass/fail criteria: Later eviction treats line as dirty.
Performance counter: `core_store_count`.

#### ID: DW-02
Scenario: Clean eviction no write-back
Goal: Verify clean line eviction does not write memory.
Stimulus/input: Load-only conflict sequence.
Expected behavior: Victim is replaced without memory write.
Signals/waveform: victim valid/dirty, `mem_req_write_valid`.
Pass/fail criteria: `mem_write_count` does not increment for clean victim.
Performance counter: `mem_write_count`.

#### ID: DW-03
Scenario: Dirty eviction creates write-back
Goal: Verify dirty victim is written to memory side.
Stimulus/input: Store to line, then access conflicting line to evict.
Expected behavior: Write request and write data are emitted.
Signals/waveform: dirty victim, `mem_req_write_valid`, `mem_req_write_data_valid`, `mem_resp_write_valid`.
Pass/fail criteria: Exactly one write-back transaction per dirty line.
Performance counter: `mem_write_count`.

#### ID: DW-04
Scenario: Write-back address correct
Goal: Verify evicted line address is correct.
Stimulus/input: Dirty eviction from known address.
Expected behavior: Write-back address equals victim line base address.
Signals/waveform: `mem_req_write_addr`, victim nline/tag/set.
Pass/fail criteria: Address matches expected cache line base.
Performance counter: `mem_write_count`.

#### ID: DW-05
Scenario: Write-back data correct
Goal: Verify dirty data is preserved.
Stimulus/input: Store known pattern, evict, inspect memory write data.
Expected behavior: Write-back data contains stored pattern and untouched bytes.
Signals/waveform: `mem_req_write_data`, `mem_req_write_be`, stored data.
Pass/fail criteria: Memory model line matches expected final line.
Performance counter: `mem_write_count`.

#### ID: DW-06
Scenario: Dirty clear after replacement
Goal: Verify dirty metadata is not incorrectly carried into new line.
Stimulus/input: Dirty eviction followed by refill of different line.
Expected behavior: New line dirty state follows policy, not old victim.
Signals/waveform: directory update, refill dir entry, dirty bit.
Pass/fail criteria: Clean refill remains clean until store.
Performance counter: `read_miss_count`.

#### ID: DW-07
Scenario: Multiple dirty evictions
Goal: Verify repeated dirty write-back sequence.
Stimulus/input: Write-heavy same-index conflict pattern.
Expected behavior: Multiple write-backs complete without lost response.
Signals/waveform: `mem_req_write_valid`, `mem_resp_write_valid`, VBUF status.
Pass/fail criteria: Number of write-backs matches expected evictions.
Performance counter: `mem_write_count`.

### VBUF

#### ID: VB-01
Scenario: Dirty victim allocated to VBUF
Goal: Verify VBUF capture is triggered.
Stimulus/input: Dirty line conflict replacement.
Expected behavior: `ctrl_vbuf_alloc` pulses and VBUF captures victim metadata.
Signals/waveform: `ctrl_vbuf_alloc`, `ctrl_vbuf_alloc_nline`, `vbuf_alloc_ready`.
Pass/fail criteria: Allocation happens once per dirty victim capture.
Performance counter: VBUF alloc count if added.

#### ID: VB-02
Scenario: VBUF ready normal
Goal: Verify VBUF is ready when empty.
Stimulus/input: Observe reset/idle state.
Expected behavior: VBUF empty and allocation-ready before first dirty victim.
Signals/waveform: `vbuf_empty`, `vbuf_full`, `vbuf_alloc_ready`.
Pass/fail criteria: `vbuf_alloc_ready=1` when empty.
Performance counter: None.

#### ID: VB-03
Scenario: VBUF full stalls new dirty eviction
Goal: Verify full VBUF backpressures replacement.
Stimulus/input: Force dirty evictions faster than drain.
Expected behavior: New dirty eviction waits until VBUF can accept.
Signals/waveform: `vbuf_full`, `vbuf_busy`, `evt_stall`, request ready.
Pass/fail criteria: No data loss and no overwrite while full.
Performance counter: `vbuf_full_stall_cycles` if added.

#### ID: VB-04
Scenario: VBUF drains when memory bus free
Goal: Verify captured victim eventually drains.
Stimulus/input: Dirty victim capture with memory side available.
Expected behavior: VBUF drain/write-back completes.
Signals/waveform: `vbuf_drain`, `vbuf_writeback_done`, memory write side.
Pass/fail criteria: VBUF returns empty.
Performance counter: VBUF writeback count if added.

#### ID: VB-05
Scenario: VBUF lower priority than read miss
Goal: Verify read miss can be prioritized over background write-back.
Stimulus/input: Create VBUF entry and a read miss.
Expected behavior: Read miss service is not blocked too long by VBUF.
Signals/waveform: read arbiter, write arbiter, VBUF write request.
Pass/fail criteria: Read miss completes and VBUF drains later.
Performance counter: `cycle_count`, refill count.

#### ID: VB-06
Scenario: VBUF preserves address/data
Goal: Verify captured victim metadata/data remain stable.
Stimulus/input: Dirty victim capture and delayed drain.
Expected behavior: VBUF write-back address/data match victim.
Signals/waveform: VBUF nline/set/way, `mem_req_write_addr`, `mem_req_write_data`.
Pass/fail criteria: Memory write-back matches original victim line.
Performance counter: VBUF alloc/writeback count.

#### ID: VB-07
Scenario: VBUF pending/inflight behavior
Goal: Verify busy/pending state transitions.
Stimulus/input: Capture victim, delay memory write response.
Expected behavior: Busy/inflight remain asserted until response.
Signals/waveform: `vbuf_busy`, `vbuf_capture_pending`, `mem_resp_write_valid`.
Pass/fail criteria: State returns idle only after completed write-back.
Performance counter: write-back cycles.

#### ID: VB-08
Scenario: VBUF hit/reload if supported
Goal: Verify lookup hits a line still held by VBUF.
Stimulus/input: Reload a recently evicted dirty line while VBUF still holds it.
Expected behavior: If implemented, VBUF hit forwards/reloads correct data.
Signals/waveform: `vbuf_check_hit`, `vbuf_fwd_hit`, `vbuf_fwd_data`.
Pass/fail criteria: Load returns latest dirty data.
Performance counter: VBUF hit count if added.

### Replacement / Refill

#### ID: RR-01
Scenario: Victim way selected
Goal: Verify a valid victim way is selected.
Stimulus/input: Fill a set and access different tag.
Expected behavior: Victim way is one-hot and legal.
Signals/waveform: victim way, PLRU state if visible.
Pass/fail criteria: No invalid one-hot or zero victim when replacement needed.
Performance counter: miss count.

#### ID: RR-02
Scenario: PLRU update after hit
Goal: Verify replacement state updates on hit.
Stimulus/input: Repeated hits to known ways.
Expected behavior: PLRU state changes according to policy.
Signals/waveform: PLRU signals if visible, hit signals.
Pass/fail criteria: Later victim selection follows expected PLRU.
Performance counter: hit count.

#### ID: RR-03
Scenario: PLRU update after refill
Goal: Verify refill updates replacement state.
Stimulus/input: Cold miss/refill.
Expected behavior: Refilled way becomes most recently used according to policy.
Signals/waveform: refill way, PLRU update.
Pass/fail criteria: Next conflict does not immediately evict the just-refilled way unless policy says so.
Performance counter: refill count.

#### ID: RR-04
Scenario: Refill writes data array
Goal: Verify memory line is written to cache data RAM.
Stimulus/input: Load miss.
Expected behavior: Refill data stored in target way/set.
Signals/waveform: `refill_write_data`, `refill_data`, set/way.
Pass/fail criteria: Subsequent load hits and returns same data.
Performance counter: `mem_read_count`.

#### ID: RR-05
Scenario: Refill writes tag/valid/dirty correctly
Goal: Verify directory metadata after refill.
Stimulus/input: Load miss and store miss.
Expected behavior: Tag/valid updated; dirty follows load/store policy.
Signals/waveform: `refill_write_dir`, directory entry, dirty bit.
Pass/fail criteria: Hit lookup succeeds after refill.
Performance counter: `read_miss_count`, `write_miss_count`.

#### ID: RR-06
Scenario: Invalid way preferred before dirty victim
Goal: Avoid unnecessary dirty eviction when invalid way exists.
Stimulus/input: Fill partially empty set then access new tag.
Expected behavior: Invalid way is used first.
Signals/waveform: valid bits, victim way, dirty victim.
Pass/fail criteria: No write-back if invalid way is available.
Performance counter: `mem_write_count`.

### Arbiter / Memory Contention

#### ID: AM-01
Scenario: Load miss vs VBUF write-back
Goal: Verify arbitration under read/write contention.
Stimulus/input: Dirty VBUF entry plus load miss.
Expected behavior: Both read refill and VBUF write-back complete.
Signals/waveform: memory read/write valid/ready, arbiter signals.
Pass/fail criteria: No lost request or duplicate response.
Performance counter: `mem_read_count`, `mem_write_count`.

#### ID: AM-02
Scenario: Store miss vs VBUF write-back
Goal: Verify store miss does not deadlock with VBUF drain.
Stimulus/input: VBUF entry then store miss.
Expected behavior: Store miss eventually refills/updates.
Signals/waveform: `evt_cache_write_miss`, VBUF status, memory write side.
Pass/fail criteria: Store readback passes.
Performance counter: `write_miss_count`.

#### ID: AM-03
Scenario: Back-to-back refill
Goal: Verify multiple refill requests complete.
Stimulus/input: Consecutive misses to different lines.
Expected behavior: Each read request gets one response.
Signals/waveform: `mem_req_read_valid`, `mem_resp_read_valid`, request IDs.
Pass/fail criteria: No missing/duplicated response.
Performance counter: `mem_read_count`.

#### ID: AM-04
Scenario: Memory ready deassert
Goal: Verify backpressure handling.
Stimulus/input: Memory model deasserts ready for read/write.
Expected behavior: HPDCache holds request stable until accepted.
Signals/waveform: ready/valid, address/data stability.
Pass/fail criteria: No protocol violation and program completes.
Performance counter: stall cycles.

#### ID: AM-05
Scenario: Memory latency variation
Goal: Verify behavior across latency values.
Stimulus/input: Run same test with different memory latency.
Expected behavior: Functional result unchanged, cycles scale with latency.
Signals/waveform: memory response delay, `cycle_count`.
Pass/fail criteria: PASS for all tested latencies.
Performance counter: `cycle_count`, miss penalty.

### Corner Cases

#### ID: CC-01
Scenario: Reset during outstanding miss
Goal: Verify clean recovery if reset occurs mid-miss.
Stimulus/input: Assert reset after read miss request before response.
Expected behavior: Core/cache return to reset state and can restart.
Signals/waveform: reset, MSHR state, memory request/response.
Pass/fail criteria: No stuck valid/ready after reset.
Performance counter: None.

#### ID: CC-02
Scenario: Reset during VBUF write-back
Goal: Verify VBUF reset behavior.
Stimulus/input: Assert reset while VBUF is busy/inflight.
Expected behavior: VBUF clears or reaches defined reset state.
Signals/waveform: `vbuf_busy`, `vbuf_empty`, memory write side.
Pass/fail criteria: No stale write after reset unless explicitly allowed.
Performance counter: None.

#### ID: CC-03
Scenario: Uncacheable access if supported
Goal: Verify PMA uncacheable path.
Stimulus/input: Mark a request uncacheable through adapter/wrapper extension.
Expected behavior: Request bypasses normal cache allocation.
Signals/waveform: PMA uncacheable, uncached handler signals.
Pass/fail criteria: Correct data and no cache line allocation.
Performance counter: uncached request count if added.

#### ID: CC-04
Scenario: Unaligned access behavior
Goal: Verify system behavior for unaligned load/store from core.
Stimulus/input: Generate unaligned memory instruction if core allows/traps.
Expected behavior: Either legal split behavior or defined core exception.
Signals/waveform: `data_addr`, exception/debug signals.
Pass/fail criteria: Matches CV32E40P expected behavior.
Performance counter: exception count if visible.

#### ID: CC-05
Scenario: X/Z and timeout check
Goal: Catch unknown propagation and deadlock.
Stimulus/input: Run all directed and random tests with timeout and X/Z monitor.
Expected behavior: No post-reset X/Z on key handshake/data signals; no timeout.
Signals/waveform: all valid/ready/data/error signals.
Pass/fail criteria: No X/Z assertion and DONE reached.
Performance counter: `cycle_count`.

### Performance Measurement

#### ID: PF-01
Scenario: Baseline no-cache cycle count
Goal: Establish original CV32E40P reference.
Stimulus/input: Run baseline no-cache program.
Expected behavior: Log baseline cycles and memory traffic.
Signals/waveform: baseline counters, DONE.
Pass/fail criteria: Baseline PASS and stable cycle count.
Performance counter: baseline `cycle_count`.

#### ID: PF-02
Scenario: Cached cycle count
Goal: Measure CV32E40P + HPDCache cycle count.
Stimulus/input: Run same workload through D-Cache path.
Expected behavior: Cached run reaches DONE and reports cycles.
Signals/waveform: `cycle_count`, DONE, cache counters.
Pass/fail criteria: PASS and comparable workload.
Performance counter: cached `cycle_count`.

#### ID: PF-03
Scenario: Load hit latency
Goal: Measure cycles from request to response for hit.
Stimulus/input: Repeated load to same address after refill.
Expected behavior: Hit latency lower than miss latency.
Signals/waveform: `data_req`, `data_gnt`, `data_rvalid`, miss event.
Pass/fail criteria: Hit has no memory read.
Performance counter: hit latency counter if added.

#### ID: PF-04
Scenario: Load miss penalty
Goal: Measure refill penalty.
Stimulus/input: Load cold line with known memory latency.
Expected behavior: Miss penalty includes memory read/refill latency.
Signals/waveform: miss event, memory read request/response, `data_rvalid`.
Pass/fail criteria: Penalty matches expected latency range.
Performance counter: miss latency counter if added.

#### ID: PF-05
Scenario: Dirty eviction penalty
Goal: Measure cost of dirty replacement.
Stimulus/input: Dirty line conflict eviction.
Expected behavior: Additional write-back traffic is counted.
Signals/waveform: dirty victim, VBUF alloc, memory write side.
Pass/fail criteria: Write-back count and cycles recorded.
Performance counter: `mem_write_count`, dirty eviction count.

#### ID: PF-06
Scenario: Hit rate and speedup
Goal: Compute high-level performance improvement.
Stimulus/input: Run baseline and cached versions of same workload.
Expected behavior: Workloads with locality show lower cached cycles.
Signals/waveform: load/store counts, miss counts, cycle counts.
Pass/fail criteria: Metrics computed consistently.
Performance counter: hit rate, miss rate, speedup.

