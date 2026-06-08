# CVA6 I-Cache Bundle Integration Notes

Generated: Wed May 27 07:23:35 AM UTC 2026

## 1. Bundle content

Bundle root:

```text
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full
```

Real CVA6 I-Cache DUT:

```text
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/cva6_icache.sv
```

Original source path:

```text
/media/sf_source_env/cva6-master/core/cache_subsystem/cva6_icache.sv
```

Important generated files:

| File | Purpose |
|---|---|
| `rtl/cva6_icache.sv` | Real CVA6 I-Cache DUT, copied without replacing it with mock/stub |
| `rtl/cva6_icache_axi_wrapper.sv` | Optional CVA6 AXI wrapper copied for reference, not used by current core filelist |
| `rtl/packages/*.sv` | CVA6 config/type/cache packages required by I-Cache |
| `rtl/util/*.sv` | SRAM helper wrappers used by cache data/tag arrays |
| `rtl/vendor/common_cells/*.sv` | Common Cells modules used by I-Cache, especially `lzc` and `lfsr` |
| `rtl/vendor/tech_cells_generic/tc_sram.sv` | Real generic SRAM model used by copied SRAM wrapper stack |
| `rtl/cva6_icache_compile_harness.sv` | Compile-only harness that instantiates the real I-Cache; it is not an I-Cache replacement |
| `sim/cva6_icache_full.f` | Main real-source I-Cache filelist |
| `sim/cva6_icache_full_verilator_lint.f` | Verilator-only lint filelist using SRAM blackbox workaround |
| `sim/compile_icache_only.sh` | Smoke compile/lint script |
| `sim/lint_icache_only.sh` | Verilator lint script |
| `docs/00_cva6_icache_extract_report.md` | E0 scan/extraction report |
| `docs/01_cva6_icache_ports.md` | I-Cache port/interface report |
| `docs/02_cva6_icache_dependencies.md` | Dependency table |
| `logs/icache_extract_error.log` | Main append-only extraction log |
| `logs/compile_icache_only.log` | Compile/lint smoke log |

Full manifest was also written to:

```text
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/logs/e5_bundle_manifest.txt
```

## 2. Main filelist

Primary filelist:

```text
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/sim/cva6_icache_full.f
```

The filelist is bundle-local and does not point back to the CVA6 source tree for the copied RTL/package/util/vendor files.

Current intended order:

1. CVA6 package/config files
2. Common/vendor cells
3. SRAM helper/util files
4. Real `cva6_icache.sv`
5. Compile harness, when doing smoke compile/lint

The package order was corrected so that `cv32a6_imac_sv32_config_pkg.sv`, which defines `cva6_config_pkg`, appears before `riscv_pkg.sv`.

## 3. Compile/lint status

Smoke compile/lint did not pass on the available tool setup.

Observed tool status:

| Tool | Status |
|---|---|
| `xrun` | Not found in current Ubuntu environment |
| `verilator` | Found and executed |
| Main Verilator lint with real SRAM | Failed with Verilator internal fault, status 255 |
| Verilator lint with SRAM blackbox workaround | Also failed with Verilator internal fault, status 255 |

Important history:

1. Initial Verilator run failed with missing package error:
   `Package/class 'cva6_config_pkg' not found`.
2. That issue was addressed by reordering the filelist so the config package is compiled before `riscv_pkg.sv`.
3. After the reorder, the visible failure became:
   `%Error: Verilator internal fault, sorry. Suggest trying --debug --gdbbt`.
4. A Verilator-only SRAM blackbox was added as a compile-only workaround, but Verilator still ended with the same internal fault.

Conclusion:

The bundle has progressed past the obvious missing-package/filelist-order issue. The remaining smoke failure in the current environment is a Verilator internal fault, not a currently visible missing source/package dependency.

Compile/lint extract was written to:

```text
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/logs/e5_compile_status_extract.txt
```

## 4. Remaining issue

Current remaining issue:

```text
Verilator internal fault, status 255
```

This should be checked later with one of these options:

1. Run with Xcelium/Questa/VCS if available.
2. Retry with another Verilator version.
3. Split lint into smaller tops/modules to isolate the exact construct that triggers the internal fault.
4. Keep the real SRAM source for simulator flow, and use the blackbox only as a lint workaround when the lint tool supports it.

No RTL patch to the real CVA6 I-Cache has been made in this extraction step.

## 5. Modules needed for later CV32E40P integration

Do not create these in this phase. They are expected for a later integration phase:

| Future module | Purpose |
|---|---|
| `cv32_instr_to_cva6_icache_adapter.sv` | Convert CV32E40P instruction fetch handshake to CVA6 I-Cache dreq/drsp interface |
| `cva6_icache_identity_translation.sv` | Provide initial translation response where physical address equals virtual address |
| `cva6_icache_mem_adapter.sv` | Convert CVA6 I-Cache refill request/return interface to the target memory/bus interface |
| `l1_mem_arbiter.sv` | Later shared arbitration between I-Cache refill and existing D-Cache/HPDCache path |

## 6. Expected CV32E40P instruction-side mapping

Later integration should map CV32E40P instruction fetch signals approximately as follows:

| CV32E40P signal | Expected role with CVA6 I-Cache |
|---|---|
| `instr_req_o` | Drives I-Cache frontend request valid |
| `instr_gnt_i` | Comes from I-Cache request acceptance/ready behavior |
| `instr_rvalid_i` | Comes from I-Cache response valid |
| `instr_addr_o` | Maps to I-Cache dreq virtual address |
| `instr_rdata_i` | Comes from I-Cache response data |
| `instr_err_i` | Comes from I-Cache exception/error/refill error handling policy |

For early bring-up, translation can be identity mapping:

```text
fetch_paddr = fetch_vaddr
```

## 7. Main risks before integration

| Risk | Note |
|---|---|
| CVA6 package dependency | `ariane_pkg`, `riscv_pkg`, `wt_cache_pkg`, `build_config_pkg`, and config package order matter |
| Final `CVA6Cfg` | Current config is a compile candidate, not yet validated as the final CV32 integration config |
| Cache line width | Refill/data width must match or be adapted to the target memory fabric |
| Virtual index / physical tag | CVA6 I-Cache is not a simple PIPT-only block; frontend VA and translated PA both matter |
| Replacement policy | Uses random/LFSR-related logic, not the same as a PLRU D-cache policy |
| Refill interface mismatch | `mem_data_req_o` and `mem_rtrn_vld_i` path must be adapted to the current memory model |
| Tool smoke status | Current Verilator setup hits an internal fault; a commercial simulator or different Verilator version may be needed for stronger compile proof |

## 8. Current extraction conclusion

The CVA6 I-Cache bundle has been created with the real DUT, local dependencies, filelists, compile harness, and interface/dependency reports.

The bundle is not yet proven compile-clean in the current Ubuntu environment because available Verilator exits with an internal fault. However, after filelist reorder there is no remaining ordinary missing package/source error visible in the current logs.

This bundle is ready for review as an extracted source bundle, but not yet ready to claim simulator-clean integration.
