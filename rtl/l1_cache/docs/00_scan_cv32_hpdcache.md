# 00 - Scan CV32E40P + HPDCache

Date: Tue May 26 08:28:39 AM UTC 2026

## Ubuntu ROOT_WORKSPACE

```text
/media/sf_source_env/cv32/work/cv32e40p-master
```

## Phase 0 Status

Core/HPDCache scan has run. Raw output is in:

```text
rtl/l1_cache/logs/error.log
```

## Integration Target

```text
CV32E40P data interface
  -> cv32_data_to_hpdcache_adapter
  -> HPDCache write-back + VBUF
  -> data memory model
```

Instruction path remains direct to instruction memory. I-Cache is not integrated in this phase.

## Items To Extract From error.log

- CV32E40P top module file
- CV32E40P instruction interface signals
- CV32E40P data interface signals
- HPDCache folder and top module
- HPDCache package/dependency files
- Adapter risks
