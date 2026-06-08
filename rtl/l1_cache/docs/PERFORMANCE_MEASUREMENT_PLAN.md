# Performance Measurement Plan - CV32E40P + HPDCache WB/VBUF

Date: 2026-05-26

## 1. Designs To Compare

Baseline design:

- Original/no-cache CV32E40P data path.
- Data access goes directly from the CV32E40P data interface to the simple memory model.
- Instruction path remains direct to instruction memory.

Cached design:

- CV32E40P data path with `cv32_data_to_hpdcache_adapter`.
- HPDCache write-back + VBUF handles data load/store traffic.
- HPDCache memory side connects to the same style of data memory model.
- Instruction path still bypasses cache in this phase.

For a fair comparison, both designs must use the same program image, same reset
sequence, same memory contents, same memory latency model, and same DONE marker.

## 2. Measurement Start Point

Preferred start markers, in order:

1. After reset is deasserted and `fetch_enable` is active.
2. When the core starts executing the benchmark body.
3. When instruction address or PC reaches the benchmark start address, if this
   signal is exposed clearly.
4. A dedicated `start_perf` signal in the testbench/top, if added later.

Do not include reset cycles, instruction/data memory preload time, build time, or
testbench initialization time in performance numbers.

Current practical start point:

- Use the first cycle after reset release and fetch enable.
- For more accurate benchmark-only measurement, add a `start_perf` flag later.

## 3. Measurement End Point

Preferred end markers, in order:

1. Program writes to the memory-mapped DONE address.
2. Testbench sees the top-level `done` flag.
3. PC reaches an `ebreak` or fixed end-loop address, if exposed.

Current practical end point:

- The existing basic/random tests finish when the program stores to the DONE
  address and the testbench prints `[PASS]`.

## 4. Counters To Measure

Required counters:

- `total_cycles`
- `instr_fetch_count`
- `data_load_count`
- `data_store_count`
- `dcache_hit_count`
- `dcache_miss_count`
- `refill_count`
- `dirty_eviction_count`
- `writeback_count`
- `vbuf_alloc_count`
- `vbuf_full_stall_cycles`
- `memory_read_count`
- `memory_write_count`
- `total_data_stall_cycles`
- `total_core_stall_cycles`

Counters already available or partially available in the current integration:

- `cycle_count`
- `core_load_count`
- `core_store_count`
- `mem_read_count`
- `mem_write_count`
- `read_miss_count`
- `write_miss_count`

Counters recommended to add next:

- `dcache_hit_count`
- `refill_count`
- `dirty_eviction_count`
- `writeback_count`
- `vbuf_alloc_count`
- `vbuf_full_stall_cycles`
- `data_stall_cycles`

## 5. Formulas

```text
total_cache_access = data_load_count + data_store_count
hit_rate = dcache_hit_count / total_cache_access
miss_rate = dcache_miss_count / total_cache_access
speedup = baseline_cycles / cached_cycles
cycle_reduction_percent =
  (baseline_cycles - cached_cycles) / baseline_cycles * 100%
memory_read_reduction = baseline_memory_reads - cached_memory_reads
memory_write_reduction = baseline_memory_writes - cached_memory_writes
writeback_overhead = writeback_count or writeback_cycles
vbuf_full_stall_ratio = vbuf_full_stall_cycles / total_cycles
```

Guard conditions:

- If `total_cache_access == 0`, do not compute hit/miss rate.
- If `cached_cycles == 0`, do not compute speedup.
- Report negative cycle reduction as overhead, not improvement.

## 6. Workloads

Minimum workload set:

1. Repeated load same address
2. Sequential load
3. Array sum
4. Store then load
5. Write-heavy same-line pattern
6. Same-index conflict pattern
7. Mixed load/store
8. Random small working set
9. Random large working set
10. Dirty eviction stress
11. VBUF full stress

Expected behavior by workload:

- Repeated load same address should show high hit rate and lower cycles.
- Sequential load should benefit if multiple words share a cache line.
- Store then load should verify dirty data forwarding/visibility.
- Write-heavy same-line pattern should reduce memory writes compared with
  direct memory or write-through behavior.
- Same-index conflict should force eviction and expose write-back/VBUF behavior.
- Random large working set may show limited speedup or overhead.
- VBUF full stress should expose stall cycles when dirty victims cannot drain.

## 7. What Improvement Must Be Explained

D-Cache improvement:

- Repeated load/store traffic with locality should avoid repeated RAM access.
- Load hit latency should be lower than load miss latency.
- Memory read traffic should drop when working set fits in cache.

Write-back improvement:

- Multiple stores to the same line should not immediately generate many memory
  writes.
- Dirty data should write back only on eviction, flush, or a selected policy
  event.

VBUF improvement:

- Dirty victim write-back can be decoupled from the refill path.
- When memory arbitration allows, VBUF can reduce core stalls caused by dirty
  eviction.
- If VBUF is full often, the benefit is reduced and stall cycles should show it.

When improvement may be small:

- Random workload much larger than cache.
- Heavy conflict pattern with very low locality.
- Memory model with unrealistically low latency.
- VBUF full or memory write side constantly blocked.

## 8. Suggested Measurement Flow

Step 1: Run baseline no-cache.

```bash
cd "$ROOT_WORKSPACE/rtl/l1_cache/work/sim"
./run_baseline_original.sh
```

Step 2: Run cached basic design.

```bash
cd "$ROOT_WORKSPACE/rtl/l1_cache/work/sim"
./run_cv32_dcache_basic.sh
```

Step 3: Run random smoke or benchmark seeds.

```bash
cd "$ROOT_WORKSPACE/rtl/l1_cache/work/sim"
./run_cv32_dcache_random.sh 1 2 3
```

Step 4: Extract counters from logs.

- Baseline log: `rtl/l1_cache/logs/01_baseline_original.log`
- Cached basic log: `rtl/l1_cache/logs/03_cv32_dcache_basic.log`
- Random logs:
  - `rtl/l1_cache/logs/04_random_seed_1.log`
  - `rtl/l1_cache/logs/04_random_seed_2.log`
  - `rtl/l1_cache/logs/04_random_seed_3.log`

Step 5: Compare cycles and memory traffic using the formulas above.

## 9. Current Known Data Points

Baseline basic:

- PASS marker exists in `01_baseline_original.log`.
- Used as a functional no-cache reference.

Cached basic:

- PASS marker:
  `cycles=90 loads=3 stores=5 mem_reads=5 mem_writes=2 read_miss=5 write_miss=4`
- Waveform:
  `rtl/l1_cache/work/waves/03_cv32_dcache_basic.vcd`

Random smoke:

- Seed 1:
  `cycles=298 generated_loads=18 generated_stores=22 core_loads=18 core_stores=23 mem_reads=13 mem_writes=2 read_miss=13 write_miss=7`
- Seed 2:
  `cycles=278 generated_loads=23 generated_stores=17 core_loads=23 core_stores=18 mem_reads=11 mem_writes=2 read_miss=11 write_miss=5`
- Seed 3:
  `cycles=277 generated_loads=24 generated_stores=16 core_loads=24 core_stores=17 mem_reads=11 mem_writes=2 read_miss=11 write_miss=5`

These are smoke-test numbers only. They prove the flow can collect useful
counters, but they are not yet final performance results.

## 10. Validity Criteria Before Reporting Numbers

Use a number in the thesis report only when all conditions are met:

- Baseline and cached design both pass functional checks.
- Same program semantics are used for both designs.
- Same memory latency is used for both designs.
- DONE marker is identical.
- No timeout or valid/ready deadlock occurs.
- No known X/Z issue appears after reset.
- Counter start/end points are documented.
- Logs are preserved under `rtl/l1_cache/logs`.
- Representative waveforms are preserved under `rtl/l1_cache/work/waves`.

## 11. Next Instrumentation Tasks

Recommended next RTL/testbench instrumentation:

1. Add a clear `start_perf` and `end_perf` region in the testbench.
2. Add automatic post-reset X/Z checks on key interfaces.
3. Expose or derive `hit_count` and `miss_count` separately.
4. Count refill transactions from HPDCache memory read side.
5. Count dirty victim events and VBUF allocations.
6. Count VBUF full stall cycles.
7. Count core data stall cycles from accepted data request to response.
8. Generate one CSV summary per run for easy plotting later.
