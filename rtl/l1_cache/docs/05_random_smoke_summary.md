# 05 - Random Smoke Summary

Date: 2026-05-26

| Seed | Result | Log | Waveform |
| --- | --- | --- | --- |
| 1 | PASS | `rtl/l1_cache/logs/04_random_seed_1.log` | `rtl/l1_cache/work/waves/04_random_seed_1.vcd` |
| 2 | PASS | `rtl/l1_cache/logs/04_random_seed_2.log` | `rtl/l1_cache/work/waves/04_random_seed_2.vcd` |
| 3 | PASS | `rtl/l1_cache/logs/04_random_seed_3.log` | `rtl/l1_cache/work/waves/04_random_seed_3.vcd` |

## Notes

- Testbench: `rtl/l1_cache/work/tb/tb_cv32e40p_dcache_random.sv`
- Uses real CV32E40P core, adapter, HPDCache WB + VBUF, and simple memory model.
- Each seed generates a small RV32I program with randomized word loads/stores.
- Timeout/deadlock is reported by the testbench if DONE is not reached.
