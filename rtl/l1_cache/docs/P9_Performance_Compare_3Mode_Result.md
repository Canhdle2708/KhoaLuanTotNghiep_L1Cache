# P9 Performance Compare 3 Mode Result

## Status

Implementation is prepared in the Full L1 folder. A user-run smoke compare passed on May 28, 2026.

The compare flow runs:

- `NO_CACHE` using the D-Cache-only folder's Verilator P2 target.
- `DCACHE_ONLY` using the D-Cache-only folder's Verilator P3 target.
- `FULL_L1` using the new Full L1 Verilator performance target.

This keeps all three modes on Verilator. HPDCache source mode is forced to `base`.

## Benchmarks

Common 3-mode benchmark set:

| BENCH_NAME | Intended evidence |
|---|---|
| `basic_load_store` | Smoke correctness and counter sanity. |
| `repeated_load` | D-cache reuse should reduce D-memory traffic. |
| `load_reuse_loop` | Tight loop with repeated loads from one hot cache line, intended to show D-Cache cycle benefit against No-Cache. |
| `store_load_reuse_loop` | Tight loop with repeated stores and loads to one hot cache line, intended to show write-back/reuse benefit. |
| `array_sum` | Sequential data locality and cache-line reuse. |
| `store_then_load_many` | Store/load reuse and write-back traffic behavior. |
| `stride_access_s1` | Locality sensitivity with `STRIDE_WORDS=1`. |
| `stride_access_s2` | Locality sensitivity with `STRIDE_WORDS=2`. |
| `stride_access_s4` | Locality sensitivity with `STRIDE_WORDS=4`. |
| `stride_access_s8` | Locality sensitivity with `STRIDE_WORDS=8`. |
| `stride_access_s16` | Locality sensitivity with `STRIDE_WORDS=16`. |

Full-L1 additional benchmark set:

| BENCH_NAME | Intended evidence |
|---|---|
| `tight_loop_fetch` | I-Cache benefit on repeated instruction fetch. |
| `mixed_i_d_locality` | Combined I-Cache and D-Cache locality. |

The two Full-L1 additional benchmarks are emitted as Full L1 rows only. They are not claimed as 3-mode comparisons until the other folders implement the same benchmark names.

## Outputs

Full log:

```text
rtl/l1_cache/logs/perf_compare_3mode.log
```

CSV:

```text
rtl/l1_cache/logs/perf_compare_3mode.csv
```

Terminal format:

```text
[PERF_COMPARE_TABLE]
Bench=repeated_load
DMEM latency Mode               Cycles   DMEM reads  DMEM writes  Total mem req   Result
20           No-Cache             5699          128            2            389     PASS
20           D-Cache only         5704            1            2            262     PASS
20           Full L1              1999            2            0             67     PASS

[PERF_COMPARE_ANALYSIS]
Bench                    Compare                     CycleReduce   Speedup   IMEMReadReduce    DMEMReadReduce    DMEMWriteReduce     TotalReqReduce
repeated_load            NoCache_vs_DCache                   ...       ...              ...               ...                ...                ...
repeated_load            DCache_vs_FullL1                    ...       ...              ...               ...                ...                ...
repeated_load            NoCache_vs_FullL1                   ...       ...              ...               ...                ...                ...

[PERF_COMPARE_SUMMARY]
total=... pass=... fail=...
[LOG] ...
[CSV] ...
```

## Commands for User Run

Syntax check only:

```bash
cd /media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim
bash -n run_full_l1_perf_verilator.sh
bash -n run_compare_3mode_perf.sh
```

Single Full L1 benchmark:

```bash
cd /media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim
make verilator_full_l1_perf BENCH_NAME=repeated_load IMEM_LATENCY=20 DMEM_LATENCY=20 MAX_CYCLES=100000
```

Full 3-mode compare:

```bash
cd /media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim
make verilator_perf_compare_3mode IMEM_LATENCY=20 DMEM_LATENCY=20 L1_MEM_LATENCY=20 MAX_CYCLES=150000 \
  COMMON_BENCHES="basic_load_store repeated_load load_reuse_loop store_load_reuse_loop array_sum store_then_load_many" \
  STRIDE_SWEEP_WORDS="1 2 4 8 16" FULL_L1_EXTRA_BENCHES="tight_loop_fetch mixed_i_d_locality" \
  2>&1 | tee ../../logs/P9_perf_compare_3mode_user.log
```

Data-locality stress compare, intended to make D-Cache-only vs No-Cache cycle separation more visible:

```bash
cd /media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim
make verilator_perf_compare_3mode IMEM_LATENCY=20 DMEM_LATENCY=20 L1_MEM_LATENCY=20 MAX_CYCLES=200000 \
  COMMON_BENCHES="load_reuse_loop store_load_reuse_loop repeated_load store_then_load_many" \
  STRIDE_SWEEP_WORDS="1 2" FULL_L1_EXTRA_BENCHES="mixed_i_d_locality" \
  2>&1 | tee ../../logs/P9_perf_compare_3mode_stress_user.log
```

Direct script form:

```bash
cd /media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim
bash run_compare_3mode_perf.sh 2>&1 | tee ../../logs/P9_perf_compare_3mode_user.log
```

## Analysis Rules After User Log

- Do not claim Full L1 is always faster.
- Report cycle reduction and speedup per benchmark.
- Report I-memory read reduction for Full L1 where I-Cache counters are available.
- Report D-memory read/write traffic reduction for D-Cache and Full L1.
- If a benchmark is too small or locality is weak, cache overhead may make it slower; keep that result as measured.

## Smoke Compare Result

User command:

```bash
make verilator_perf_compare_3mode IMEM_LATENCY=20 DMEM_LATENCY=20 MAX_CYCLES=100000 \
  COMMON_BENCHES="basic_load_store repeated_load" STRIDE_SWEEP_WORDS="4" FULL_L1_EXTRA_BENCHES=""
```

Terminal summary:

```text
[PERF_COMPARE_SUMMARY]
total=11 pass=11 fail=0
```

Observed table:

| Bench | Mode | Cycles | IMEM reads | DMEM reads | DMEM writes | Total mem req | IC miss/refill | DCache miss | Result |
|---|---|---:|---:|---:|---:|---:|---|---:|---|
| `basic_load_store` | NO_CACHE | 331 | 15 | 3 | 5 | 23 | NA | NA | PASS |
| `basic_load_store` | DCACHE_ONLY | 336 | 15 | 1 | 2 | 18 | NA | 2 | PASS |
| `basic_load_store` | FULL_L1 | 166 | 4 | 2 | 0 | 6 | 4/4 | 4 | PASS |
| `repeated_load` | NO_CACHE | 5699 | 259 | 128 | 2 | 389 | NA | NA | PASS |
| `repeated_load` | DCACHE_ONLY | 5704 | 259 | 1 | 2 | 262 | NA | 1 | PASS |
| `repeated_load` | FULL_L1 | 1999 | 65 | 2 | 0 | 67 | 65/65 | 3 | PASS |
| `stride_access_s4` | NO_CACHE | 771 | 35 | 16 | 2 | 53 | NA | NA | PASS |
| `stride_access_s4` | DCACHE_ONLY | 776 | 35 | 16 | 2 | 53 | NA | 16 | PASS |
| `stride_access_s4` | FULL_L1 | 703 | 9 | 17 | 0 | 26 | 9/9 | 18 | PASS |
| `tight_loop_fetch` | FULL_L1 | 589 | 2 | 1 | 0 | 3 | 2/2 | 2 | PASS |
| `mixed_i_d_locality` | FULL_L1 | 969 | 3 | 2 | 0 | 5 | 3/4 | 3 | PASS |

Interpretation:

- `repeated_load`: D-Cache-only reduces D-memory reads from 128 to 1, but cycles stay about the same because I-fetch traffic still dominates without I-Cache. Full L1 reduces IMEM reads from 259 to 65 and total memory requests from 389 to 67, giving about 2.85x speedup versus No-Cache.
- `basic_load_store`: D-Cache-only is slightly slower than No-Cache because the benchmark is small and cache overhead dominates. Full L1 is faster because I-side traffic drops from 15 to 4 reads.
- `stride_access_s4`: D-Cache does not help data locality at this stride, but Full L1 still reduces instruction traffic and total memory requests.

## Current Expected Limitation

The compare script depends on the existing D-Cache-only folder at:

```text
/media/sf_SOURCE_ENV/cv32e40p-master
```

If that path differs in Ubuntu, set:

```bash
DCACHE_ONLY_ROOT=/path/to/cv32e40p-master make verilator_perf_compare_3mode
```

## First User Run Debug Notes

The first user run showed two infrastructure issues, both fixed in the Full L1 folder:

- `tb_cv32e40p_full_l1_perf.sv` printed `[PERF_RESULT] ... result=PASS`, then fell through to `$fatal` after `$finish`. The PASS/FAIL terminal control-flow is now mutually exclusive.
- `run_compare_3mode_perf.sh` exported Full L1 `ROOT_WORKSPACE/SIM_DIR/L1_CACHE_DIR/...` variables into the D-Cache-only subprocess, causing the D-Cache-only target to look for its filelist in the Full L1 folder. The compare script now unsets those path variables before invoking the D-Cache-only make targets.
