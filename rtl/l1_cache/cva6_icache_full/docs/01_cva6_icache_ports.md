# CVA6 I-Cache Port Report - PHASE E3

Generated: Wed May 27 03:29:19 AM UTC 2026

## Scope

This report describes the real DUT copied from CVA6:

- DUT: `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/cva6_icache.sv`
- Filelist: `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/sim/cva6_icache_full.f`

No CV32E40P integration is done in this phase.

## Module

`cva6_icache` is parameterized by:

- `config_pkg::cva6_cfg_t CVA6Cfg`
- `icache_areq_t`
- `icache_arsp_t`
- `icache_dreq_t`
- `icache_drsp_t`
- `icache_req_t`
- `icache_rtrn_t`
- `RdTxId`

The interface structs are type parameters. They are not defined inside `cva6_icache.sv`; the future integration wrapper or compile harness must provide concrete typedefs.

## Clock And Reset

| Port | Direction | Meaning |
|---|---:|---|
| `clk_i` | input | Main clock. |
| `rst_ni` | input | Active-low asynchronous reset. |

## Enable, Flush, Miss

| Port | Direction | Meaning |
|---|---:|---|
| `flush_i` | input | Flush/invalidate I-Cache valid bits. Source comment says flush and kill have to be asserted together at system level. |
| `en_i` | input | Enable cache. Disabling is immediate; enabling goes through flush/clear state. |
| `miss_o` | output | One-cycle performance event when a cacheable miss request is accepted by refill path. Not asserted for non-cacheable bypass. |

## Frontend Data Request: dreq

`dreq_i` is the frontend request path. It sends the virtual fetch address into I-Cache.

Observed fields used by DUT:

| Field | Direction | Meaning inferred from source |
|---|---:|---|
| `dreq_i.req` | input | Frontend has a fetch request. |
| `dreq_i.vaddr` | input | Virtual fetch address. Used for cache index and offset. |
| `dreq_i.spec` | input | Speculative request marker. Used with non-idempotent region filtering. |
| `dreq_i.kill_s1` | input | Kill stage 1 request. |
| `dreq_i.kill_s2` | input | Kill stage 2 request/result. |
| `dreq_o.ready` | output | I-Cache can accept a frontend request. |
| `dreq_o.valid` | output | Returned instruction data is valid. |
| `dreq_o.data` | output | Fetched instruction data, width `CVA6Cfg.FETCH_WIDTH`. |
| `dreq_o.user` | output | Optional fetch user bits, active only if `CVA6Cfg.FETCH_USER_EN`. |
| `dreq_o.ex` | output | Exception information passed from translation response. |
| `dreq_o.vaddr` | output | Latched virtual address corresponding to the response. |

Important integration note: cache array index `cl_index` is derived from `dreq_i.vaddr` / latched `vaddr_d`.

## Address Translation Request: areq

`areq` is the I-Cache to translation path. I-Cache sends a virtual address and waits for translated physical address / exception.

Observed fields used by DUT:

| Field | Direction | Meaning inferred from source |
|---|---:|---|
| `areq_o.fetch_req` | output | Request translation for current fetch. |
| `areq_o.fetch_vaddr` | output | Aligned virtual fetch address sent to translation. |
| `areq_i.fetch_valid` | input | Translation response is valid. |
| `areq_i.fetch_paddr` | input | Physical address returned by translation. Used for tag and refill physical address. |
| `areq_i.fetch_exception` | input | Translation/fetch exception, passed to `dreq_o.ex`. |

For early CV32E40P bring-up, an identity translation block can be used:

- `fetch_paddr = fetch_vaddr`
- `fetch_valid` follows `fetch_req`
- `fetch_exception.valid = 0`

This is only a first-stage integration simplification, not a full MMU/TLB replacement.

## Refill Request To Memory

| Port | Direction | Meaning |
|---|---:|---|
| `mem_data_req_o` | output | I-Cache requests a refill or non-cacheable fetch from memory. |
| `mem_data_ack_i` | input | Memory/refill adapter accepted the request. |
| `mem_data_o` | output | Refill request payload of type `icache_req_t`. |

Observed `mem_data_o` fields:

| Field | Meaning inferred from source |
|---|---|
| `paddr` | Physical refill address. Cacheable accesses align to cache line; non-cacheable accesses align to word/bus beat. |
| `tid` | Transaction ID, assigned from `RdTxId`. |
| `nc` | Non-cacheable marker. Set when cache disabled or address outside cacheable regions. |
| `way` | Replacement way selected for refill. |

## Refill / Invalidation Response From Memory

| Port | Direction | Meaning |
|---|---:|---|
| `mem_rtrn_vld_i` | input | Refill/invalidation response is valid. |
| `mem_rtrn_i` | input | Response payload of type `icache_rtrn_t`. |

Observed `mem_rtrn_i` fields:

| Field | Meaning inferred from source |
|---|---|
| `rtype` | Response kind. DUT checks `ICACHE_IFILL_ACK` and `ICACHE_INV_REQ`. |
| `data` | Returned cache line or bypass data. Used for output and SRAM write. |
| `user` | Optional returned user bits. |
| `inv.all` | Invalidate all ways at index / all valid bits depending command. |
| `inv.vld` | Invalidate one selected way. |
| `inv.idx` | Invalidation index. |
| `inv.way` | Invalidation way. |

## Addressing Model

This I-Cache is not a simple pure PIPT block in integration terms:

- Index and offset are derived from virtual address `dreq_i.vaddr`.
- Tag is derived from translated physical address `areq_i.fetch_paddr`.
- Refill request address `mem_data_o.paddr` is built from physical tag plus virtual index/offset bits.

So the practical model is VIPT-like: virtual index, physical tag. Identity mapping can make first bring-up easier, but the integration still needs to respect the timing between dreq, areq, and refill response.

## CV32E40P Integration Preview Only

This phase does not integrate CV32E40P. Later adapters likely need to map:

| CV32E40P instruction side | CVA6 I-Cache side |
|---|---|
| `instr_req_o` | `dreq_i.req` through adapter |
| `instr_addr_o` | `dreq_i.vaddr`; also identity `areq_i.fetch_paddr` initially |
| `instr_gnt_i` | derived from `dreq_o.ready` |
| `instr_rvalid_i` | derived from `dreq_o.valid` |
| `instr_rdata_i` | from `dreq_o.data` |
| `instr_err_i` | from `dreq_o.ex` / exception mapping |

## Raw Scan Files

- Module header scan: `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/logs/e3_module_header.txt`
- Field usage scan: `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/logs/e3_field_usage.txt`
- Combined port scan: `/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/logs/e3_port_scan.txt`
