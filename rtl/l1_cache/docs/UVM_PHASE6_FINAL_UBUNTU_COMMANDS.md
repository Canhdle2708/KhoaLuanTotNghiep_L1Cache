# UVM Phase 6 Final Ubuntu Commands

Use these commands from Ubuntu. Codex edits Windows files only and reads the
generated logs/CSVs after each run.

## 0. Normalize Shared-Folder Timestamps

Run this after Codex edits files from Windows if `make` reports clock skew.
It updates only file timestamps under the work/doc areas and does not change
file contents or log evidence.

```sh
PROJ=/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master
if [ ! -d "$PROJ" ]; then PROJ=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master; fi
cd "$PROJ/rtl/l1_cache/work/sim"
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
bash ./normalize_shared_folder_timestamps.sh 2>&1 | tee ../../logs/QUESTA_p6e_normalize_clock_skew.log
```

## 1. Syntax Check

```sh
PROJ=/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master
if [ ! -d "$PROJ" ]; then PROJ=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master; fi
cd "$PROJ/rtl/l1_cache/work/sim"
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
bash -n run_uvm_questa.sh 2>&1 | tee ../../logs/QUESTA_p6e_runner_syntax_check.log
bash -n run_p6_multiseed.sh 2>&1 | tee -a ../../logs/QUESTA_p6e_runner_syntax_check.log
bash -n run_p6_mode_compare.sh 2>&1 | tee -a ../../logs/QUESTA_p6e_runner_syntax_check.log
bash -n run_p6_closure.sh 2>&1 | tee -a ../../logs/QUESTA_p6e_runner_syntax_check.log
bash -n collect_p6_final_review_bundle.sh 2>&1 | tee -a ../../logs/QUESTA_p6e_runner_syntax_check.log
make -n HPDCACHE_SRC_MODE=base run_uvm_p6_perf_mode_compare_no_cache_full MAX_CYCLES=1000000 2>&1 | tee -a ../../logs/QUESTA_p6e_runner_syntax_check.log
make -n HPDCACHE_SRC_MODE=base run_uvm_p6_perf_mode_compare_dcache_only_full MAX_CYCLES=1000000 2>&1 | tee -a ../../logs/QUESTA_p6e_runner_syntax_check.log
make -n HPDCACHE_SRC_MODE=base run_uvm_p6_perf_mode_compare_full_l1_full MAX_CYCLES=1000000 2>&1 | tee -a ../../logs/QUESTA_p6e_runner_syntax_check.log
make -n HPDCACHE_SRC_MODE=base run_uvm_p6_perf_mode_compare_full MAX_CYCLES=1000000 2>&1 | tee -a ../../logs/QUESTA_p6e_runner_syntax_check.log
make -n HPDCACHE_SRC_MODE=base run_uvm_p6_perf_closure_full MAX_CYCLES=1000000 2>&1 | tee -a ../../logs/QUESTA_p6e_runner_syntax_check.log
```

## 2. P15 Random Wait Full

```sh
PROJ=/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master
if [ ! -d "$PROJ" ]; then PROJ=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master; fi
cd "$PROJ/rtl/l1_cache/work/sim"
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
make HPDCACHE_SRC_MODE=base run_uvm_p6_perf_p15_random_wait_full MAX_CYCLES=500000 2>&1 | tee ../../logs/QUESTA_p6_perf_p15_random_wait_full.log
```

## 3. P26 Multi-Seed Full

```sh
PROJ=/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master
if [ ! -d "$PROJ" ]; then PROJ=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master; fi
cd "$PROJ/rtl/l1_cache/work/sim"
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
make HPDCACHE_SRC_MODE=base run_uvm_p6_perf_p26_multiseed_full MAX_CYCLES=500000 2>&1 | tee ../../logs/QUESTA_p6_perf_p26_multiseed_full.log
```

## 4. P27-P29 NO_CACHE Full

Runs the true `NO_CACHE` UVM DUT.

```sh
PROJ=/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master
if [ ! -d "$PROJ" ]; then PROJ=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master; fi
cd "$PROJ/rtl/l1_cache/work/sim"
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
make HPDCACHE_SRC_MODE=base run_uvm_p6_perf_mode_compare_no_cache_full MAX_CYCLES=1000000 2>&1 | tee ../../logs/QUESTA_p6_perf_mode_compare_no_cache_full.log
```

## 5. P27-P29 DCACHE_ONLY Full

Runs the true `DCACHE_ONLY` UVM DUT.

```sh
PROJ=/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master
if [ ! -d "$PROJ" ]; then PROJ=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master; fi
cd "$PROJ/rtl/l1_cache/work/sim"
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
make HPDCACHE_SRC_MODE=base run_uvm_p6_perf_mode_compare_dcache_only_full MAX_CYCLES=1000000 2>&1 | tee ../../logs/QUESTA_p6_perf_mode_compare_dcache_only_full.log
```

## 6. P27-P29 FULL_L1 Full

Runs the existing true `FULL_L1` UVM DUT fresh for mode comparison.

```sh
PROJ=/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master
if [ ! -d "$PROJ" ]; then PROJ=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master; fi
cd "$PROJ/rtl/l1_cache/work/sim"
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
make HPDCACHE_SRC_MODE=base run_uvm_p6_perf_mode_compare_full_l1_full MAX_CYCLES=1000000 2>&1 | tee ../../logs/QUESTA_p6_perf_mode_compare_full_l1_full.log
```

## 7. Combined P27-P29 Mode Compare Full

Runs all three modes and aggregates `uvm_p6_mode_compare_summary.csv`.

```sh
PROJ=/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master
if [ ! -d "$PROJ" ]; then PROJ=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master; fi
cd "$PROJ/rtl/l1_cache/work/sim"
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
make HPDCACHE_SRC_MODE=base run_uvm_p6_perf_mode_compare_full MAX_CYCLES=1000000 2>&1 | tee ../../logs/QUESTA_p6_perf_mode_compare_full.log
```

## 8. Phase 6 Closure Full

```sh
PROJ=/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master
if [ ! -d "$PROJ" ]; then PROJ=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master; fi
cd "$PROJ/rtl/l1_cache/work/sim"
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
make HPDCACHE_SRC_MODE=base run_uvm_p6_perf_closure_full MAX_CYCLES=1000000 2>&1 | tee ../../logs/QUESTA_p6_perf_closure_full.log
```

## 9. Grep Closure Check

```sh
PROJ=/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master
if [ ! -d "$PROJ" ]; then PROJ=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master; fi
cd "$PROJ/rtl/l1_cache/work/sim"
grep -E "\[UVM\]\[P6_MODE_COMPARE\]|\[UVM\]\[P6_TEST\]\[P27\]|\[UVM\]\[P6_TEST\]\[P28\]|\[UVM\]\[P6_TEST\]\[P29\]|\[UVM\]\[P6_CLOSURE\]|NO_CACHE|DCACHE_ONLY|FULL_L1|UVM_ERROR|UVM_FATAL|strict_errors|timeout|PASS|FAIL|BLOCKED|DEFERRED|MISSING|CSV|speedup|traffic" ../../logs/QUESTA_p6_perf_mode_compare_no_cache_full.log ../../logs/QUESTA_p6_perf_mode_compare_dcache_only_full.log ../../logs/QUESTA_p6_perf_mode_compare_full_l1_full.log ../../logs/QUESTA_p6_perf_mode_compare_full.log ../../logs/QUESTA_p6_perf_closure_full.log 2>&1 | tee ../../logs/QUESTA_p6e_mode_compare_check.log || true
```

## 10. CSV Quick Check

```sh
PROJ=/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master
if [ ! -d "$PROJ" ]; then PROJ=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master; fi
cd "$PROJ/rtl/l1_cache/work/sim"
echo "=== MODE COMPARE CSV ===" 2>&1 | tee ../../logs/QUESTA_p6e_mode_compare_csv_check.log
cat ../../logs/uvm_p6_mode_compare_summary.csv 2>&1 | tee -a ../../logs/QUESTA_p6e_mode_compare_csv_check.log || true
echo "=== MODE COMPARE RAW CSV ===" 2>&1 | tee -a ../../logs/QUESTA_p6e_mode_compare_csv_check.log
cat ../../logs/uvm_p6_mode_compare_raw.csv 2>&1 | tee -a ../../logs/QUESTA_p6e_mode_compare_csv_check.log || true
echo "=== P6 MATRIX ===" 2>&1 | tee -a ../../logs/QUESTA_p6e_mode_compare_csv_check.log
cat ../../logs/uvm_p6_perf_test_matrix.csv 2>&1 | tee -a ../../logs/QUESTA_p6e_mode_compare_csv_check.log || true
```

## 11. Collect Final Review Bundle

```sh
PROJ=/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master
if [ ! -d "$PROJ" ]; then PROJ=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master; fi
cd "$PROJ/rtl/l1_cache/work/sim"
chmod +x collect_p6_final_review_bundle.sh
./collect_p6_final_review_bundle.sh 2>&1 | tee ../../logs/QUESTA_p6e_collect_final_review_bundle.log
```

## 12. Optional Phase 4 Guard

```sh
PROJ=/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master
if [ ! -d "$PROJ" ]; then PROJ=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master; fi
cd "$PROJ/rtl/l1_cache/work/sim"
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
make HPDCACHE_SRC_MODE=base run_uvm_p4_functional_coverage MAX_CYCLES=100000 2>&1 | tee ../../logs/QUESTA_p6_closure_guard_phase4.log
```

## 13. Optional Phase 5 Guard

```sh
PROJ=/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master
if [ ! -d "$PROJ" ]; then PROJ=/media/sf_SOURCE_ENV/cv32_full_l1_cache/cv32e40p-master; fi
cd "$PROJ/rtl/l1_cache/work/sim"
export LM_LICENSE_FILE=/media/sf_source_env/LR-166346_License.dat
source /home/vboxuser/altera/25.1std/questa_fse/questasim.sh 2>/dev/null || true
make HPDCACHE_SRC_MODE=base run_uvm_p5_perf_collector_smoke MAX_CYCLES=100000 2>&1 | tee ../../logs/QUESTA_p6_closure_guard_phase5.log
```
