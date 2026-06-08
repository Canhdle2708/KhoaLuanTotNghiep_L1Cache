# CVA6 I-Cache Dependencies - PHASE E1

Generated: Wed May 27 03:21:25 AM UTC 2026

## Scope

- Chỉ copy source vào bundle: `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full`.
- Không sửa source gốc trong `/media/sf_source_env/cva6-master`.
- Không sửa HPDCache/D-Cache/flow hiện tại.
- Chưa patch nội dung source đã copy.

## Important Note About Config Package

`ariane_pkg.sv` references `cva6_config_pkg::CVA6ConfigDataUserWidth` and `cva6_config_pkg::CVA6ConfigRvfiTrace`.
Vì có nhiều biến thể `cva6_config_pkg` trong CVA6, bước này copy `core/include/cv32a6_imac_sv32_config_pkg.sv` làm candidate CV32 cho smoke compile.
Đây là compile/config candidate, chưa phải quyết định final cho tích hợp CV32E40P.

## Copied Files

| File | Source path gốc trong CVA6 | Destination path trong bundle | Vì sao cần file này | Module/type được cung cấp |
|---|---|---|---|---|
| `cva6_icache.sv` | `/media/sf_source_env/cva6-master/core/cache_subsystem/cva6_icache.sv` | `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/cva6_icache.sv` | DUT thật bắt buộc của bundle I-Cache CVA6 | module cva6_icache |
| `cva6_icache_axi_wrapper.sv` | `/media/sf_source_env/cva6-master/core/cache_subsystem/cva6_icache_axi_wrapper.sv` | `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv` | Optional wrapper CVA6 cho refill AXI; không phải DUT thay thế | module cva6_icache_axi_wrapper |
| `config_pkg.sv` | `/media/sf_source_env/cva6-master/core/include/config_pkg.sv` | `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/config_pkg.sv` | Cung cấp config_pkg::cva6_cfg_t, cva6_cfg_empty, cacheable-region helper | package config_pkg; type cva6_cfg_t; function is_inside_cacheable_regions |
| `riscv_pkg.sv` | `/media/sf_source_env/cva6-master/core/include/riscv_pkg.sv` | `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/riscv_pkg.sv` | ariane_pkg tham chiếu nhiều hằng/type trong package riscv | package riscv |
| `cv32a6_imac_sv32_config_pkg.sv` | `/media/sf_source_env/cva6-master/core/include/cv32a6_imac_sv32_config_pkg.sv` | `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/cv32a6_imac_sv32_config_pkg.sv` | Cung cấp package cva6_config_pkg cho ariane_pkg; chọn bản CV32 IMAC SV32 để phục vụ compile smoke, chưa khẳng định là final integration config | package cva6_config_pkg |
| `build_config_pkg.sv` | `/media/sf_source_env/cva6-master/core/include/build_config_pkg.sv` | `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/build_config_pkg.sv` | Helper build_config(config_pkg::cva6_user_cfg_t), hữu ích cho harness/config smoke sau này | package build_config_pkg |
| `ariane_pkg.sv` | `/media/sf_source_env/cva6-master/core/include/ariane_pkg.sv` | `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/ariane_pkg.sv` | DUT import ariane_pkg::* trực tiếp | package ariane_pkg |
| `wt_cache_pkg.sv` | `/media/sf_source_env/cva6-master/core/include/wt_cache_pkg.sv` | `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/wt_cache_pkg.sv` | DUT import wt_cache_pkg::* trực tiếp; định nghĩa icache_in_t dùng trong refill/invalidation path | package wt_cache_pkg; type icache_in_t |
| `sram_cache.sv` | `/media/sf_source_env/cva6-master/common/local/util/sram_cache.sv` | `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/util/sram_cache.sv` | DUT instantiate sram_cache cho tag/data RAM | module sram_cache |
| `sram.sv` | `/media/sf_source_env/cva6-master/common/local/util/sram.sv` | `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/util/sram.sv` | sram_cache instantiate sram khi TECHNO_CUT=0 | module sram |
| `tc_sram_wrapper.sv` | `/media/sf_source_env/cva6-master/common/local/util/tc_sram_wrapper.sv` | `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/util/tc_sram_wrapper.sv` | sram instantiate tc_sram_wrapper | module tc_sram_wrapper |
| `tc_sram_wrapper_cache_techno.sv` | `/media/sf_source_env/cva6-master/common/local/util/tc_sram_wrapper_cache_techno.sv` | `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/util/tc_sram_wrapper_cache_techno.sv` | sram_cache instantiate tc_sram_wrapper_cache_techno khi TECHNO_CUT=1 | module tc_sram_wrapper_cache_techno |
| `cf_math_pkg.sv` | `/media/sf_source_env/cva6-master/vendor/pulp-platform/common_cells/src/cf_math_pkg.sv` | `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/vendor/common_cells/cf_math_pkg.sv` | lzc dùng cf_math_pkg::idx_width | package cf_math_pkg |
| `lzc.sv` | `/media/sf_source_env/cva6-master/vendor/pulp-platform/common_cells/src/lzc.sv` | `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/vendor/common_cells/lzc.sv` | DUT instantiate lzc để chọn invalid/hit way | module lzc |
| `lfsr.sv` | `/media/sf_source_env/cva6-master/vendor/pulp-platform/common_cells/src/lfsr.sv` | `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/vendor/common_cells/lfsr.sv` | DUT instantiate lfsr cho random replacement | module lfsr |
| `tc_sram.sv` | `/media/sf_source_env/cva6-master/vendor/pulp-platform/tech_cells_generic/src/rtl/tc_sram.sv` | `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/vendor/tech_cells_generic/tc_sram.sv` | tc_sram_wrapper và tc_sram_wrapper_cache_techno instantiate tc_sram trong simulation translate_off | module tc_sram |

## Dependency Chắc Chắn Cần

- `cva6_icache.sv`: DUT thật.
- `ariane_pkg.sv`, `wt_cache_pkg.sv`: import trực tiếp trong DUT.
- `config_pkg.sv`: cung cấp `config_pkg::cva6_cfg_t` và helper cacheable region dùng trong DUT.
- `riscv_pkg.sv` và `cv32a6_imac_sv32_config_pkg.sv`: cần để `ariane_pkg.sv` elaborate/compile.
- `lzc.sv`, `lfsr.sv`, `sram_cache.sv`: module con instantiate trực tiếp trong DUT.
- `cf_math_pkg.sv`: dependency của `lzc.sv`.
- `sram.sv`, `tc_sram_wrapper*.sv`, `tc_sram.sv`: dependency phía dưới của `sram_cache.sv`.

## Dependency Chưa Chắc Chắn / Chưa Đưa Vào Filelist

- `cva6_icache_axi_wrapper.sv` đã copy nếu tồn tại, nhưng là wrapper optional, không phải DUT thay thế.
- Các adapter AXI/L15/cache subsystem khác chưa copy vì không phải dependency trực tiếp của `cva6_icache.sv`.
- Config package final cho CV32E40P cần quyết định lại ở bước tích hợp, sau khi chốt tham số line width, associativity, PLEN/VLEN/XLEN.
