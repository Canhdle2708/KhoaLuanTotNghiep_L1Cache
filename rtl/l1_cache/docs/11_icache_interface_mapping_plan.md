# PHASE I1 - I-Cache Interface Mapping Plan

- Time: Wed May 27 08:30:54 AM UTC 2026
- CV32_ROOT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master`
- ICACHE_ROOT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full`
- HPDCACHE_ROOT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/hpdcache/cv-hpdcache`
- WORK_ROOT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work`
- CV32 core/top candidate: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/cv32e40p_core.sv`
- I-Cache DUT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv`
- Existing D-Cache-only top: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/rtl/cv32e40p_l1_dcache_top.sv`

## A. CV32E40P Instruction Interface

Required signals to confirm:

- `instr_req_o`
- `instr_gnt_i`
- `instr_rvalid_i`
- `instr_addr_o`
- `instr_rdata_i`
- `instr_err_i`
- Other related signals if present: `fetch_enable_i`, `boot_addr_i`

Evidence from CV32 source:

```text
50:    input logic [31:0] boot_addr_i,
57:    output logic        instr_req_o,
58:    input  logic        instr_gnt_i,
59:    input  logic        instr_rvalid_i,
60:    output logic [31:0] instr_addr_o,
61:    input  logic [31:0] instr_rdata_i,
99:    input  logic fetch_enable_i,
114:  // will re-introduce combinatorial paths from instr_rvalid_i to instr_req_o and from from data_rvalid_i
131:  logic [31:0] instr_rdata_id;  // Instruction sampled inside IF stage
288:  logic               instr_req_int;  // Id stage asserts a req to instruction core interface
355:  logic                           instr_req_pmp;
356:  logic                           instr_gnt_pmp;
357:  logic [             31:0]       instr_addr_pmp;
358:  logic                           instr_err_pmp;
380:  logic fetch_enable;
395:      .fetch_enable_i(fetch_enable_i),
396:      .fetch_enable_o(fetch_enable),
434:      .boot_addr_i        (boot_addr_i[31:0]),
446:      .req_i(instr_req_int),
449:      .instr_req_o    (instr_req_pmp),
450:      .instr_addr_o   (instr_addr_pmp),
451:      .instr_gnt_i    (instr_gnt_pmp),
452:      .instr_rvalid_i (instr_rvalid_i),
453:      .instr_rdata_i  (instr_rdata_i),
454:      .instr_err_i    (1'b0),  // Bus error (not used yet)
455:      .instr_err_pmp_i(instr_err_pmp),  // PMP error
459:      .instr_rdata_id_o (instr_rdata_id),
537:      .fetch_enable_i               ( fetch_enable         ),     // Delayed version so that clock can remain gated until fetch enabled
543:      .instr_rdata_i(instr_rdata_id),
544:      .instr_req_o  (instr_req_int),
1098:          .instr_req_i (instr_req_pmp),
1099:          .instr_addr_i(instr_addr_pmp),
1100:          .instr_gnt_o (instr_gnt_pmp),
1102:          .instr_req_o (instr_req_o),
1103:          .instr_gnt_i (instr_gnt_i),
1104:          .instr_addr_o(instr_addr_o),
1105:          .instr_err_o (instr_err_pmp)
1108:      assign instr_req_o   = instr_req_pmp;
1109:      assign instr_addr_o  = instr_addr_pmp;
1110:      assign instr_gnt_pmp = instr_gnt_i;
1111:      assign instr_err_pmp = 1'b0;
1132:                                                                            (instr_rvalid_i == 1'b0) && (instr_gnt_i == 1'b0) &&
```

Evidence from current D-Cache-only top:

```text
1:module cv32e40p_l1_dcache_top;
12:  logic fetch_enable = 1'b0;
16:  logic instr_req;
17:  logic instr_gnt;
18:  logic instr_rvalid;
19:  logic [31:0] instr_addr;
20:  logic [31:0] instr_rdata;
21:  logic [31:0] instr_rdata_q;
22:  logic instr_rvalid_q;
140:  cv32e40p_top #(
153:      .boot_addr_i(32'h0000_0000),
158:      .instr_req_o(instr_req),
159:      .instr_gnt_i(instr_gnt),
160:      .instr_rvalid_i(instr_rvalid),
161:      .instr_addr_o(instr_addr),
162:      .instr_rdata_i(instr_rdata),
178:      .fetch_enable_i(fetch_enable),
253:  assign instr_gnt = instr_req;
254:  assign instr_rvalid = instr_rvalid_q;
255:  assign instr_rdata = instr_rdata_q;
259:      instr_rvalid_q <= 1'b0;
260:      instr_rdata_q <= 32'h0000_0013;
262:      instr_rvalid_q <= instr_req;
263:      instr_rdata_q <= imem[instr_addr[31:2] % IMEM_WORDS];
```

## B. CVA6 I-Cache Interface

Required groups to confirm:

- Clock/reset
- Enable/flush
- `dreq` request interface
- `drsp` response interface
- `areq/arsp` translation interface
- `mem_data_req_o`
- `mem_data_ack_i`
- `mem_rtrn_vld_i`
- `mem_rtrn_i`
- `miss_o`
- Performance/debug signals if present

Module header evidence:

```systemverilog
28:module cva6_icache
29:  import ariane_pkg::*;
30:  import wt_cache_pkg::*;
31:#(
32:    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
33:    parameter type icache_areq_t = logic,
34:    parameter type icache_arsp_t = logic,
35:    parameter type icache_dreq_t = logic,
36:    parameter type icache_drsp_t = logic,
37:    parameter type icache_req_t = logic,
38:    parameter type icache_rtrn_t = logic,
39:    /// ID to be used for read transactions
40:    parameter logic [CVA6Cfg.MEM_TID_WIDTH-1:0] RdTxId = 0
41:) (
42:    input logic clk_i,
43:    input logic rst_ni,
44:
45:    /// flush the icache, flush and kill have to be asserted together
46:    input  logic         flush_i,
47:    /// enable icache
48:    input  logic         en_i,
49:    /// to performance counter
50:    output logic         miss_o,
51:    // address translation requests
52:    input  icache_areq_t areq_i,
53:    output icache_arsp_t areq_o,
54:    // data requests
55:    input  icache_dreq_t dreq_i,
56:    output icache_drsp_t dreq_o,
57:    // refill port
58:    input  logic         mem_rtrn_vld_i,
59:    input  icache_rtrn_t mem_rtrn_i,
60:    output logic         mem_data_req_o,
61:    input  logic         mem_data_ack_i,
62:    output icache_req_t  mem_data_o
63:);
```

Important signal evidence:

```text
32:    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
33:    parameter type icache_areq_t = logic,
34:    parameter type icache_arsp_t = logic,
35:    parameter type icache_dreq_t = logic,
36:    parameter type icache_drsp_t = logic,
40:    parameter logic [CVA6Cfg.MEM_TID_WIDTH-1:0] RdTxId = 0
42:    input logic clk_i,
43:    input logic rst_ni,
45:    /// flush the icache, flush and kill have to be asserted together
46:    input  logic         flush_i,
47:    /// enable icache
49:    /// to performance counter
50:    output logic         miss_o,
52:    input  icache_areq_t areq_i,
53:    output icache_arsp_t areq_o,
55:    input  icache_dreq_t dreq_i,
56:    output icache_drsp_t dreq_o,
58:    input  logic         mem_rtrn_vld_i,
59:    input  icache_rtrn_t mem_rtrn_i,
60:    output logic         mem_data_req_o,
61:    input  logic         mem_data_ack_i,
65:  localparam ICACHE_OFFSET_WIDTH = $clog2(CVA6Cfg.ICACHE_LINE_WIDTH / 8);
66:  localparam ICACHE_NUM_WORDS = 2 ** (CVA6Cfg.ICACHE_INDEX_WIDTH - ICACHE_OFFSET_WIDTH);
70:  function automatic logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] icache_way_bin2oh(
71:      input logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] in);
72:    logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] out;
79:  logic cache_en_d, cache_en_q;  // cache is enabled
80:  logic [CVA6Cfg.VLEN-1:0] vaddr_d, vaddr_q;
82:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] cl_hit;  // hit from tag compare
87:      cmp_en_q;  // enable tag comparison in next cycle. used to cut long path due to NC signal.
88:  logic flush_d, flush_q;  // used to register and signal pending flushes
92:  logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] inv_way;  // first non-valid encountered
93:  logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] rnd_way;  // random index for replacement
94:  logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] repl_way;  // way to replace
95:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] repl_way_oh_d, repl_way_oh_q;  // way to replace (onehot)
98:  // invalidations / flushing
101:  logic flush_en, flush_done;  // used to flush cache entries
102:  logic [ICACHE_CL_IDX_WIDTH-1:0] flush_cnt_d, flush_cnt_q;  // used to flush cache entries
105:  logic                                cl_we;  // write enable to memory array
106:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] cl_req;  // request to memory array
109:  logic [CVA6Cfg.ICACHE_TAG_WIDTH-1:0] cl_tag_d, cl_tag_q;  // this is the cache tag
110:  logic [CVA6Cfg.ICACHE_TAG_WIDTH-1:0]          cl_tag_rdata [CVA6Cfg.ICACHE_SET_ASSOC-1:0]; // these are the tags coming from the tagmem
111:  logic [CVA6Cfg.ICACHE_LINE_WIDTH-1:0]         cl_rdata     [CVA6Cfg.ICACHE_SET_ASSOC-1:0]; // these are the cachelines coming from the cache
112:  logic [CVA6Cfg.ICACHE_USER_LINE_WIDTH-1:0]    cl_ruser[CVA6Cfg.ICACHE_SET_ASSOC-1:0]; // these are the cachelines coming from the user cache
113:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0][CVA6Cfg.FETCH_WIDTH-1:0] cl_sel;  // selected word from each cacheline
114:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0][CVA6Cfg.FETCH_USER_WIDTH-1:0] cl_user;  // selected word from each cacheline
115:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] vld_req;  // bit enable for valid regs
116:  logic vld_we;  // valid bits write enable
117:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] vld_wdata;  // valid bits to write
118:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] vld_rdata;  // valid bits coming from valid regs
137:  assign cl_tag_d  = (areq_i.fetch_valid) ? areq_i.fetch_paddr[CVA6Cfg.ICACHE_TAG_WIDTH+CVA6Cfg.ICACHE_INDEX_WIDTH-1:CVA6Cfg.ICACHE_INDEX_WIDTH] : cl_tag_q;
141:      CVA6Cfg, {{64 - CVA6Cfg.PLEN{1'b0}}, cl_tag_d, {CVA6Cfg.ICACHE_INDEX_WIDTH{1'b0}}}
145:  assign dreq_o.ex = areq_i.fetch_exception;
149:  assign vaddr_d = (dreq_o.ready & dreq_i.req) ? dreq_i.vaddr : vaddr_q;
150:  assign areq_o.fetch_vaddr = (vaddr_q >> CVA6Cfg.FETCH_ALIGN_BITS) << CVA6Cfg.FETCH_ALIGN_BITS;
153:  assign cl_index = vaddr_d[CVA6Cfg.ICACHE_INDEX_WIDTH-1:ICACHE_OFFSET_WIDTH];
156:  if (CVA6Cfg.NOCType == config_pkg::NOC_TYPE_AXI4_ATOP) begin : gen_axi_offset
158:    assign cl_offset_d = ( dreq_o.ready & dreq_i.req)      ? (dreq_i.vaddr >> CVA6Cfg.FETCH_ALIGN_BITS) << CVA6Cfg.FETCH_ALIGN_BITS :
159:                         ( paddr_is_nc  & mem_data_req_o ) ? {{ICACHE_OFFSET_WIDTH-1{1'b0}}, cl_offset_q[2]}<<2 : // needed since we transfer 32bit over a 64bit AXI bus in this case
162:    assign mem_data_o.paddr = (paddr_is_nc) ? {cl_tag_d, vaddr_q[CVA6Cfg.ICACHE_INDEX_WIDTH-1:3], 3'b0} :                                         // align to 64bit
163:        {cl_tag_d, vaddr_q[CVA6Cfg.ICACHE_INDEX_WIDTH-1:ICACHE_OFFSET_WIDTH], {ICACHE_OFFSET_WIDTH{1'b0}}}; // align to cl
167:    assign cl_offset_d = (dreq_o.ready & dreq_i.req) ? {dreq_i.vaddr >> 2, 2'b0} : cl_offset_q;
170:    assign mem_data_o.paddr = (paddr_is_nc) ? {cl_tag_d, vaddr_q[CVA6Cfg.ICACHE_INDEX_WIDTH-1:2], 2'b0} :                                         // align to 32bit
171:        {cl_tag_d, vaddr_q[CVA6Cfg.ICACHE_INDEX_WIDTH-1:ICACHE_OFFSET_WIDTH], {ICACHE_OFFSET_WIDTH{1'b0}}}; // align to cl
180:  assign dreq_o.vaddr   = vaddr_q;
190:      CVA6Cfg, {{64 - CVA6Cfg.PLEN{1'b0}}, areq_i.fetch_paddr}
195:    cache_en_d   = cache_en_q & en_i;// disabling the cache is always possible, enable needs to go via flush
196:    flush_en = 1'b0;
201:    flush_d = flush_q | flush_i;  // register incoming flush
204:    dreq_o.ready = 1'b0;
205:    areq_o.fetch_req = 1'b0;
206:    dreq_o.valid = 1'b0;
207:    mem_data_req_o = 1'b0;
208:    // performance counter
209:    miss_o = 1'b0;
216:    if (mem_rtrn_vld_i && mem_rtrn_i.rtype == ICACHE_INV_REQ) begin
224:        flush_en = 1'b1;
225:        if (flush_done) begin
227:          flush_d = 1'b0;
228:          // if the cache was not enabled set this
235:        // only enable tag comparison if cache is enabled
238:        // handle pending flushes, or perform cache clear upon enable
239:        if (flush_d || (en_i && !cache_en_q)) begin
244:          if (!mem_rtrn_vld_i) begin
245:            dreq_o.ready = 1'b1;
247:            if (dreq_i.req) begin
252:          if (dreq_i.kill_s1) begin
264:        areq_o.fetch_req = '1;
265:        // only enable tag comparison if cache is enabled
270:        if (areq_i.fetch_valid && (!dreq_i.spec || ((CVA6Cfg.NonIdemPotenceEn && !addr_ni) || (!CVA6Cfg.NonIdemPotenceEn)))) begin
271:          // check if we have to flush
272:          if (flush_d) begin
275:          end else if (((|cl_hit && cache_en_q) || areq_i.fetch_exception.valid) && !inv_q) begin
276:            dreq_o.valid = ~dreq_i.kill_s2;  // just don't output in this case
282:            if (!mem_rtrn_vld_i) begin
283:              dreq_o.ready = 1'b1;
284:              if (dreq_i.req) begin
290:            if (dreq_i.kill_s1) begin
294:          end else if (dreq_i.kill_s2) begin
298:            // only count this as a miss if the cache is enabled, and
301:            mem_data_req_o = 1'b1;
302:            if (mem_data_ack_i) begin
303:              miss_o  = ~paddr_is_nc;
308:        end else if (dreq_i.kill_s2 || flush_d) begin
319:        if (mem_rtrn_vld_i && mem_rtrn_i.rtype == ICACHE_IFILL_ACK) begin
322:          if (!(dreq_i.kill_s2 || flush_d)) begin
323:            dreq_o.valid = 1'b1;
328:        end else if (dreq_i.kill_s2 || flush_d) begin
337:        areq_o.fetch_req = '1;
338:        if (areq_i.fetch_valid) begin
347:        if (mem_rtrn_vld_i && mem_rtrn_i.rtype == ICACHE_IFILL_ACK) begin
364:  // flushes take precedence over invalidations (it is ok if we ignore
367:  assign flush_cnt_d = (flush_done) ? '0 : (flush_en) ? flush_cnt_q + 1 : flush_cnt_q;
369:  assign flush_done = (flush_cnt_q == (ICACHE_NUM_WORDS - 1));
372:  // flushing takes precedence over invals
373:  assign vld_addr = (flush_en)       ? flush_cnt_q        :
374:                    (inv_en)         ? mem_rtrn_i.inv.idx[CVA6Cfg.ICACHE_INDEX_WIDTH-1:ICACHE_OFFSET_WIDTH] :
377:  assign vld_req  = (flush_en || cache_rden)        ? '1                                    :
378:                    (mem_rtrn_i.inv.all && inv_en)  ? '1                                    :
379:                    (mem_rtrn_i.inv.vld && inv_en)  ? icache_way_bin2oh(
380:      mem_rtrn_i.inv.way
385:  assign vld_we = (cache_wren | inv_en | flush_en);
394:  // enable signals for memory arrays
401:      .WIDTH(CVA6Cfg.ICACHE_SET_ASSOC)
411:      .OutWidth (CVA6Cfg.ICACHE_SET_ASSOC_WIDTH)
413:      .clk_i (clk_i),
414:      .rst_ni(rst_ni),
424:  logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] hit_idx;
426:  for (genvar i = 0; i < CVA6Cfg.ICACHE_SET_ASSOC; i++) begin : gen_tag_cmpsel
428:    assign cl_sel[i] = cl_rdata[i][{cl_offset_q, 3'b0}+:CVA6Cfg.FETCH_WIDTH];
429:    assign cl_user[i] = CVA6Cfg.FETCH_USER_EN ? cl_ruser[i][{cl_offset_q, 3'b0}+:CVA6Cfg.FETCH_USER_WIDTH] : '0;
434:      .WIDTH(CVA6Cfg.ICACHE_SET_ASSOC)
443:      dreq_o.data = cl_sel[hit_idx];
444:      dreq_o.user = CVA6Cfg.FETCH_USER_EN ? cl_user[hit_idx] : '0;
446:      dreq_o.data = mem_rtrn_i.data[{cl_offset_q, 3'b0}+:CVA6Cfg.FETCH_WIDTH];
447:      dreq_o.user = CVA6Cfg.FETCH_USER_EN ? mem_rtrn_i.user[{cl_offset_q, 3'b0}+:CVA6Cfg.FETCH_USER_WIDTH] : '0;
456:  logic [CVA6Cfg.ICACHE_TAG_WIDTH:0] cl_tag_valid_rdata[CVA6Cfg.ICACHE_SET_ASSOC-1:0];
458:  for (genvar i = 0; i < CVA6Cfg.ICACHE_SET_ASSOC; i++) begin : gen_sram
462:        .DATA_WIDTH (CVA6Cfg.ICACHE_TAG_WIDTH + 1),
464:        .TECHNO_CUT (CVA6Cfg.TechnoCut),
467:        .clk_i  (clk_i),
468:        .rst_ni (rst_ni),
481:    assign cl_tag_rdata[i] = cl_tag_valid_rdata[i][CVA6Cfg.ICACHE_TAG_WIDTH-1:0];
482:    assign vld_rdata[i]    = cl_tag_valid_rdata[i][CVA6Cfg.ICACHE_TAG_WIDTH];
486:        .USER_WIDTH (CVA6Cfg.ICACHE_USER_LINE_WIDTH),
487:        .DATA_WIDTH (CVA6Cfg.ICACHE_LINE_WIDTH),
488:        .USER_EN    (CVA6Cfg.FETCH_USER_EN),
490:        .TECHNO_CUT (CVA6Cfg.TechnoCut),
493:        .clk_i  (clk_i),
494:        .rst_ni (rst_ni),
498:        .wuser_i(mem_rtrn_i.user),
499:        .wdata_i(mem_rtrn_i.data),
507:  always_ff @(posedge clk_i or negedge rst_ni) begin : p_regs
508:    if (!rst_ni) begin
510:      flush_cnt_q   <= '0;
514:      flush_q       <= '0;
521:      flush_cnt_q   <= flush_cnt_d;
525:      flush_q       <= flush_d;
541:    @(posedge clk_i) disable iff (!rst_ni) cache_wren |-> !(mem_rtrn_i.inv.all | mem_rtrn_i.inv.vld))
546:    @(posedge clk_i) disable iff (!rst_ni) (mem_rtrn_i.inv.all | mem_rtrn_i.inv.vld) |-> !cache_wren)
551:    @(posedge clk_i) disable iff (!rst_ni) (state_q inside {FLUSH, IDLE, READ, MISS, KILL_ATRANS, KILL_MISS}))
556:    @(posedge clk_i) disable iff (!rst_ni) (!inv_en) |-> cache_rden |=> cmp_en_q |-> $onehot0(
562:  logic vld_mirror[ICACHE_NUM_WORDS-1:0][CVA6Cfg.ICACHE_SET_ASSOC-1:0];
563:  logic [CVA6Cfg.ICACHE_TAG_WIDTH-1:0] tag_mirror[ICACHE_NUM_WORDS-1:0][CVA6Cfg.ICACHE_SET_ASSOC-1:0];
564:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] tag_write_duplicate_test;
566:  always_ff @(posedge clk_i or negedge rst_ni) begin : p_mirror
567:    if (!rst_ni) begin
571:      for (int i = 0; i < CVA6Cfg.ICACHE_SET_ASSOC; i++) begin
580:  for (genvar i = 0; i < CVA6Cfg.ICACHE_SET_ASSOC; i++) begin : gen_tag_dupl
586:    @(posedge clk_i) disable iff (!rst_ni) |vld_req |-> vld_we |-> !(|tag_write_duplicate_test))
592:    assert (CVA6Cfg.ICACHE_INDEX_WIDTH <= 12)
```

## C. Proposed Mapping Draft

- CV32 `instr_req_o` -> adapter request valid toward CVA6 I-Cache `dreq`.
- CV32 `instr_addr_o` -> I-Cache fetch virtual address field in `dreq`.
- I-Cache `drsp` valid -> CV32 `instr_rvalid_i`.
- I-Cache `drsp` instruction/data field -> CV32 `instr_rdata_i`.
- I-Cache exception/error field -> CV32 `instr_err_i`; if no exception, tie to 0.
- CV32 `instr_gnt_i` must come from adapter accept/ready semantics, not from memory directly.

Status: this is only a draft. Exact struct field names must be confirmed from the typedef evidence below before RTL is written.

## D. Identity Translation Plan

- `fetch_paddr = fetch_vaddr`.
- Exception/page fault/access fault = 0.
- No TLB and no page table walk.
- Translation handshake must follow the exact `areq/arsp` valid/ready protocol used by `cva6_icache.sv`.

## E. Risks / Open Items

- CVA6 struct typedef names and fields must be matched exactly.
- `CVA6Cfg` parameter/config source must be included by the full L1 filelist.
- Cache line width and memory return payload width must be confirmed before memory adapter.
- Virtual-index/physical-tag behavior depends on correct identity translation timing.
- CV32 instruction handshake differs from CVA6 fetch/I-Cache protocol; adapter likely needs one outstanding request.
- If any required port/field remains unknown after this report, stop and ask before PHASE I2.

## F. I-Cache Filelist

```text
+incdir+/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages
+incdir+/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/vendor/common_cells
+incdir+/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/vendor/tech_cells_generic
+incdir+/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/util
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/config_pkg.sv
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/cv32a6_imac_sv32_config_pkg.sv
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/riscv_pkg.sv
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/build_config_pkg.sv
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/ariane_pkg.sv
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/wt_cache_pkg.sv
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/vendor/common_cells/cf_math_pkg.sv
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/vendor/common_cells/lzc.sv
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/vendor/common_cells/lfsr.sv
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/vendor/tech_cells_generic/tc_sram.sv
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/util/tc_sram_wrapper.sv
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/util/tc_sram_wrapper_cache_techno.sv
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/util/sram.sv
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/util/sram_cache.sv
/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/cva6_icache.sv
```

## G. Typedef / Package Evidence

```text
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:32:    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:33:    parameter type icache_areq_t = logic,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:34:    parameter type icache_arsp_t = logic,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:35:    parameter type icache_dreq_t = logic,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:36:    parameter type icache_drsp_t = logic,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:40:    parameter logic [CVA6Cfg.MEM_TID_WIDTH-1:0] RdTxId = 0
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:52:    input  icache_areq_t areq_i,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:53:    output icache_arsp_t areq_o,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:55:    input  icache_dreq_t dreq_i,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:56:    output icache_drsp_t dreq_o,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:65:  localparam ICACHE_OFFSET_WIDTH = $clog2(CVA6Cfg.ICACHE_LINE_WIDTH / 8);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:66:  localparam ICACHE_NUM_WORDS = 2 ** (CVA6Cfg.ICACHE_INDEX_WIDTH - ICACHE_OFFSET_WIDTH);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:70:  function automatic logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] icache_way_bin2oh(
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:71:      input logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] in);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:72:    logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] out;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:80:  logic [CVA6Cfg.VLEN-1:0] vaddr_d, vaddr_q;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:82:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] cl_hit;  // hit from tag compare
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:92:  logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] inv_way;  // first non-valid encountered
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:93:  logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] rnd_way;  // random index for replacement
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:94:  logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] repl_way;  // way to replace
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:95:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] repl_way_oh_d, repl_way_oh_q;  // way to replace (onehot)
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:106:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] cl_req;  // request to memory array
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:109:  logic [CVA6Cfg.ICACHE_TAG_WIDTH-1:0] cl_tag_d, cl_tag_q;  // this is the cache tag
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:110:  logic [CVA6Cfg.ICACHE_TAG_WIDTH-1:0]          cl_tag_rdata [CVA6Cfg.ICACHE_SET_ASSOC-1:0]; // these are the tags coming from the tagmem
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:111:  logic [CVA6Cfg.ICACHE_LINE_WIDTH-1:0]         cl_rdata     [CVA6Cfg.ICACHE_SET_ASSOC-1:0]; // these are the cachelines coming from the cache
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:112:  logic [CVA6Cfg.ICACHE_USER_LINE_WIDTH-1:0]    cl_ruser[CVA6Cfg.ICACHE_SET_ASSOC-1:0]; // these are the cachelines coming from the user cache
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:113:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0][CVA6Cfg.FETCH_WIDTH-1:0] cl_sel;  // selected word from each cacheline
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:114:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0][CVA6Cfg.FETCH_USER_WIDTH-1:0] cl_user;  // selected word from each cacheline
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:115:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] vld_req;  // bit enable for valid regs
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:117:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] vld_wdata;  // valid bits to write
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:118:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] vld_rdata;  // valid bits coming from valid regs
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:137:  assign cl_tag_d  = (areq_i.fetch_valid) ? areq_i.fetch_paddr[CVA6Cfg.ICACHE_TAG_WIDTH+CVA6Cfg.ICACHE_INDEX_WIDTH-1:CVA6Cfg.ICACHE_INDEX_WIDTH] : cl_tag_q;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:141:      CVA6Cfg, {{64 - CVA6Cfg.PLEN{1'b0}}, cl_tag_d, {CVA6Cfg.ICACHE_INDEX_WIDTH{1'b0}}}
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:150:  assign areq_o.fetch_vaddr = (vaddr_q >> CVA6Cfg.FETCH_ALIGN_BITS) << CVA6Cfg.FETCH_ALIGN_BITS;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:153:  assign cl_index = vaddr_d[CVA6Cfg.ICACHE_INDEX_WIDTH-1:ICACHE_OFFSET_WIDTH];
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:156:  if (CVA6Cfg.NOCType == config_pkg::NOC_TYPE_AXI4_ATOP) begin : gen_axi_offset
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:158:    assign cl_offset_d = ( dreq_o.ready & dreq_i.req)      ? (dreq_i.vaddr >> CVA6Cfg.FETCH_ALIGN_BITS) << CVA6Cfg.FETCH_ALIGN_BITS :
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:162:    assign mem_data_o.paddr = (paddr_is_nc) ? {cl_tag_d, vaddr_q[CVA6Cfg.ICACHE_INDEX_WIDTH-1:3], 3'b0} :                                         // align to 64bit
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:163:        {cl_tag_d, vaddr_q[CVA6Cfg.ICACHE_INDEX_WIDTH-1:ICACHE_OFFSET_WIDTH], {ICACHE_OFFSET_WIDTH{1'b0}}}; // align to cl
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:170:    assign mem_data_o.paddr = (paddr_is_nc) ? {cl_tag_d, vaddr_q[CVA6Cfg.ICACHE_INDEX_WIDTH-1:2], 2'b0} :                                         // align to 32bit
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:171:        {cl_tag_d, vaddr_q[CVA6Cfg.ICACHE_INDEX_WIDTH-1:ICACHE_OFFSET_WIDTH], {ICACHE_OFFSET_WIDTH{1'b0}}}; // align to cl
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:190:      CVA6Cfg, {{64 - CVA6Cfg.PLEN{1'b0}}, areq_i.fetch_paddr}
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:205:    areq_o.fetch_req = 1'b0;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:264:        areq_o.fetch_req = '1;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:270:        if (areq_i.fetch_valid && (!dreq_i.spec || ((CVA6Cfg.NonIdemPotenceEn && !addr_ni) || (!CVA6Cfg.NonIdemPotenceEn)))) begin
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:337:        areq_o.fetch_req = '1;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:374:                    (inv_en)         ? mem_rtrn_i.inv.idx[CVA6Cfg.ICACHE_INDEX_WIDTH-1:ICACHE_OFFSET_WIDTH] :
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:401:      .WIDTH(CVA6Cfg.ICACHE_SET_ASSOC)
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:411:      .OutWidth (CVA6Cfg.ICACHE_SET_ASSOC_WIDTH)
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:424:  logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] hit_idx;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:426:  for (genvar i = 0; i < CVA6Cfg.ICACHE_SET_ASSOC; i++) begin : gen_tag_cmpsel
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:428:    assign cl_sel[i] = cl_rdata[i][{cl_offset_q, 3'b0}+:CVA6Cfg.FETCH_WIDTH];
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:429:    assign cl_user[i] = CVA6Cfg.FETCH_USER_EN ? cl_ruser[i][{cl_offset_q, 3'b0}+:CVA6Cfg.FETCH_USER_WIDTH] : '0;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:434:      .WIDTH(CVA6Cfg.ICACHE_SET_ASSOC)
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:444:      dreq_o.user = CVA6Cfg.FETCH_USER_EN ? cl_user[hit_idx] : '0;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:446:      dreq_o.data = mem_rtrn_i.data[{cl_offset_q, 3'b0}+:CVA6Cfg.FETCH_WIDTH];
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:447:      dreq_o.user = CVA6Cfg.FETCH_USER_EN ? mem_rtrn_i.user[{cl_offset_q, 3'b0}+:CVA6Cfg.FETCH_USER_WIDTH] : '0;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:456:  logic [CVA6Cfg.ICACHE_TAG_WIDTH:0] cl_tag_valid_rdata[CVA6Cfg.ICACHE_SET_ASSOC-1:0];
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:458:  for (genvar i = 0; i < CVA6Cfg.ICACHE_SET_ASSOC; i++) begin : gen_sram
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:462:        .DATA_WIDTH (CVA6Cfg.ICACHE_TAG_WIDTH + 1),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:464:        .TECHNO_CUT (CVA6Cfg.TechnoCut),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:481:    assign cl_tag_rdata[i] = cl_tag_valid_rdata[i][CVA6Cfg.ICACHE_TAG_WIDTH-1:0];
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:482:    assign vld_rdata[i]    = cl_tag_valid_rdata[i][CVA6Cfg.ICACHE_TAG_WIDTH];
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:486:        .USER_WIDTH (CVA6Cfg.ICACHE_USER_LINE_WIDTH),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:487:        .DATA_WIDTH (CVA6Cfg.ICACHE_LINE_WIDTH),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:488:        .USER_EN    (CVA6Cfg.FETCH_USER_EN),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:490:        .TECHNO_CUT (CVA6Cfg.TechnoCut),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:562:  logic vld_mirror[ICACHE_NUM_WORDS-1:0][CVA6Cfg.ICACHE_SET_ASSOC-1:0];
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:563:  logic [CVA6Cfg.ICACHE_TAG_WIDTH-1:0] tag_mirror[ICACHE_NUM_WORDS-1:0][CVA6Cfg.ICACHE_SET_ASSOC-1:0];
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:564:  logic [CVA6Cfg.ICACHE_SET_ASSOC-1:0] tag_write_duplicate_test;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:571:      for (int i = 0; i < CVA6Cfg.ICACHE_SET_ASSOC; i++) begin
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:580:  for (genvar i = 0; i < CVA6Cfg.ICACHE_SET_ASSOC; i++) begin : gen_tag_dupl
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv:592:    assert (CVA6Cfg.ICACHE_INDEX_WIDTH <= 12)
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:20:    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:21:    parameter type icache_areq_t = logic,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:22:    parameter type icache_arsp_t = logic,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:23:    parameter type icache_dreq_t = logic,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:24:    parameter type icache_drsp_t = logic,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:38:    input icache_areq_t areq_i,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:39:    output icache_arsp_t areq_o,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:41:    input icache_dreq_t dreq_i,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:42:    output icache_drsp_t dreq_o,
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:48:  localparam AxiNumWords = (CVA6Cfg.ICACHE_LINE_WIDTH/CVA6Cfg.AxiDataWidth) * (CVA6Cfg.ICACHE_LINE_WIDTH  > CVA6Cfg.DCACHE_LINE_WIDTH)  +
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:49:                           (CVA6Cfg.DCACHE_LINE_WIDTH/CVA6Cfg.AxiDataWidth) * (CVA6Cfg.ICACHE_LINE_WIDTH <= CVA6Cfg.DCACHE_LINE_WIDTH) ;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:59:  logic         [CVA6Cfg.AxiAddrWidth-1:0] axi_rd_addr;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:62:  logic         [  CVA6Cfg.AxiIdWidth-1:0] axi_rd_id_in;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:67:  logic         [CVA6Cfg.AxiDataWidth-1:0] axi_rd_data;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:68:  logic         [  CVA6Cfg.AxiIdWidth-1:0] axi_rd_id_out;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:74:  logic [CVA6Cfg.ICACHE_LINE_WIDTH/CVA6Cfg.AxiDataWidth-1:0][CVA6Cfg.AxiDataWidth-1:0]
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:86:  assign axi_rd_addr           = CVA6Cfg.AxiAddrWidth'(req_data_d.paddr);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:89:  assign axi_rd_blen           = (req_data_d.nc) ? '0 : CVA6Cfg.ICACHE_LINE_WIDTH / 64 - 1;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:90:  assign axi_rd_size           = $clog2(CVA6Cfg.AxiDataWidth / 8);  // Maximum
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:110:      .CVA6Cfg(CVA6Cfg),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:111:      .icache_areq_t(icache_areq_t),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:112:      .icache_arsp_t(icache_arsp_t),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:113:      .icache_dreq_t(icache_dreq_t),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:114:      .icache_drsp_t(icache_drsp_t),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:139:      .CVA6Cfg    (CVA6Cfg),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:186:      if (CVA6Cfg.ICACHE_LINE_WIDTH == CVA6Cfg.AxiDataWidth) begin
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_axi_wrapper.sv:189:        rd_shift_d = {axi_rd_data, rd_shift_q[CVA6Cfg.ICACHE_LINE_WIDTH/CVA6Cfg.AxiDataWidth-1:1]};
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:8:    parameter config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:13:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:14:    logic [CVA6Cfg.XLEN-1:0]  cause;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:15:    logic [CVA6Cfg.XLEN-1:0]  tval;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:16:    logic [CVA6Cfg.GPLEN-1:0] tval2;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:22:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:24:    logic [CVA6Cfg.PLEN-1:0] fetch_paddr;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:26:  } icache_areq_t;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:28:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:29:    logic                    fetch_req;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:30:    logic [CVA6Cfg.VLEN-1:0] fetch_vaddr;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:31:  } icache_arsp_t;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:33:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:38:    logic [CVA6Cfg.VLEN-1:0] vaddr;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:39:  } icache_dreq_t;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:41:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:44:    logic [CVA6Cfg.FETCH_WIDTH-1:0]      data;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:45:    logic [CVA6Cfg.FETCH_USER_WIDTH-1:0] user;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:46:    logic [CVA6Cfg.VLEN-1:0]             vaddr;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:48:  } icache_drsp_t;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:50:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:51:    logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] way;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:52:    logic [CVA6Cfg.PLEN-1:0]                   paddr;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:54:    logic [CVA6Cfg.MEM_TID_WIDTH-1:0]          tid;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:57:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:59:    logic [CVA6Cfg.ICACHE_LINE_WIDTH-1:0]      data;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:60:    logic [CVA6Cfg.ICACHE_USER_LINE_WIDTH-1:0] user;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:61:    struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:64:      logic [CVA6Cfg.ICACHE_INDEX_WIDTH-1:0]     idx;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:65:      logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] way;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:67:    logic [CVA6Cfg.MEM_TID_WIDTH-1:0]          tid;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:76:  icache_areq_t areq_i;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:77:  icache_arsp_t areq_o;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:78:  icache_dreq_t dreq_i;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:79:  icache_drsp_t dreq_o;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:100:      .CVA6Cfg       (CVA6Cfg),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:101:      .icache_areq_t (icache_areq_t),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:102:      .icache_arsp_t (icache_arsp_t),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:103:      .icache_dreq_t (icache_dreq_t),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache_compile_harness.sv:104:      .icache_drsp_t (icache_drsp_t),
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/ariane_pkg.sv:37:  // if CVA6Cfg.DCacheType = cva6_config_pkg::WT
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/ariane_pkg.sv:41:  // if CVA6Cfg.DCacheType = cva6_config_pkg::WB
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/ariane_pkg.sv:77:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/ariane_pkg.sv:180:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/ariane_pkg.sv:185:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/ariane_pkg.sv:543:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/ariane_pkg.sv:672:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/ariane_pkg.sv:691:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/ariane_pkg.sv:700:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:3:  function automatic config_pkg::cva6_cfg_t build_config(config_pkg::cva6_user_cfg_t CVA6Cfg);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:4:    bit IS_XLEN32 = (CVA6Cfg.XLEN == 32) ? 1'b1 : 1'b0;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:5:    bit IS_XLEN64 = (CVA6Cfg.XLEN == 32) ? 1'b0 : 1'b1;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:6:    bit FpPresent = CVA6Cfg.RVF | CVA6Cfg.RVD | CVA6Cfg.XF16 | CVA6Cfg.XF16ALT | CVA6Cfg.XF8;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:7:    bit NSX = CVA6Cfg.XF16 | CVA6Cfg.XF16ALT | CVA6Cfg.XF8 | CVA6Cfg.XFVec;  // Are non-standard extensions present?
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:8:    int unsigned FLen = CVA6Cfg.RVD ? 64 :  // D ext.
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:9:    CVA6Cfg.RVF ? 32 :  // F ext.
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:10:    CVA6Cfg.XF16 ? 16 :  // Xf16 ext.
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:11:    CVA6Cfg.XF16ALT ? 16 :  // Xf16alt ext.
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:12:    CVA6Cfg.XF8 ? 8 :  // Xf8 ext.
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:16:    bit RVFVec     = CVA6Cfg.RVF     & CVA6Cfg.XFVec & FLen>32; // FP32 vectors available if vectors and larger fmt enabled
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:17:    bit XF16Vec    = CVA6Cfg.XF16    & CVA6Cfg.XFVec & FLen>16; // FP16 vectors available if vectors and larger fmt enabled
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:18:    bit XF16ALTVec = CVA6Cfg.XF16ALT & CVA6Cfg.XFVec & FLen>16; // FP16ALT vectors available if vectors and larger fmt enabled
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:19:    bit XF8Vec     = CVA6Cfg.XF8     & CVA6Cfg.XFVec & FLen>8;  // FP8 vectors available if vectors and larger fmt enabled
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:21:    bit EnableAccelerator = CVA6Cfg.RVV;  // Currently only used by V extension (Ara)
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:22:    int unsigned NrWbPorts = (CVA6Cfg.CvxifEn || EnableAccelerator) ? 5 : 4;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:24:    int unsigned ICACHE_INDEX_WIDTH = $clog2(CVA6Cfg.IcacheByteSize / CVA6Cfg.IcacheSetAssoc);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:25:    int unsigned DCACHE_INDEX_WIDTH = $clog2(CVA6Cfg.DcacheByteSize / CVA6Cfg.DcacheSetAssoc);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:26:    int unsigned DCACHE_OFFSET_WIDTH = $clog2(CVA6Cfg.DcacheLineWidth / 8);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:29:    int unsigned VpnLen = (CVA6Cfg.XLEN == 64) ? (CVA6Cfg.RVH ? 29 : 27) : 20;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:30:    int unsigned PtLevels = (CVA6Cfg.XLEN == 64) ? 3 : 2;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:34:    cfg.XLEN = CVA6Cfg.XLEN;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:35:    cfg.VLEN = CVA6Cfg.VLEN;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:36:    cfg.PLEN = (CVA6Cfg.XLEN == 32) ? 34 : 56;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:37:    cfg.GPLEN = (CVA6Cfg.XLEN == 32) ? 34 : 41;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:40:    cfg.XLEN_ALIGN_BYTES = $clog2(CVA6Cfg.XLEN / 8);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:41:    cfg.ASID_WIDTH = (CVA6Cfg.XLEN == 64) ? 16 : 1;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:42:    cfg.VMID_WIDTH = (CVA6Cfg.XLEN == 64) ? 14 : 1;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:44:    cfg.FpgaEn = CVA6Cfg.FpgaEn;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:45:    cfg.FpgaAlteraEn = CVA6Cfg.FpgaAlteraEn;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:46:    cfg.TechnoCut = CVA6Cfg.TechnoCut;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:48:    cfg.SuperscalarEn = CVA6Cfg.SuperscalarEn;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:49:    cfg.NrCommitPorts = CVA6Cfg.SuperscalarEn ? unsigned'(2) : CVA6Cfg.NrCommitPorts;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:50:    cfg.NrIssuePorts = unsigned'(CVA6Cfg.SuperscalarEn ? 2 : 1);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:51:    cfg.SpeculativeSb = CVA6Cfg.SuperscalarEn;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:53:    cfg.NrALUs = CVA6Cfg.SuperscalarEn ? unsigned'(2) : unsigned'(1);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:54:    cfg.ALUBypass = CVA6Cfg.SuperscalarEn ? bit'(CVA6Cfg.ALUBypass) : bit'(0);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:56:    cfg.NrLoadPipeRegs = CVA6Cfg.NrLoadPipeRegs;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:57:    cfg.NrStorePipeRegs = CVA6Cfg.NrStorePipeRegs;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:58:    cfg.AxiAddrWidth = CVA6Cfg.AxiAddrWidth;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:59:    cfg.AxiDataWidth = CVA6Cfg.AxiDataWidth;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:60:    cfg.AxiIdWidth = CVA6Cfg.AxiIdWidth;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:61:    cfg.AxiUserWidth = CVA6Cfg.AxiUserWidth;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:62:    cfg.MEM_TID_WIDTH = CVA6Cfg.MemTidWidth;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:63:    cfg.NrLoadBufEntries = CVA6Cfg.NrLoadBufEntries;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:64:    cfg.RVF = CVA6Cfg.RVF;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:65:    cfg.RVD = CVA6Cfg.RVD;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:66:    cfg.XF16 = CVA6Cfg.XF16;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:67:    cfg.XF16ALT = CVA6Cfg.XF16ALT;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:68:    cfg.XF8 = CVA6Cfg.XF8;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:69:    cfg.RVA = CVA6Cfg.RVA;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:70:    cfg.RVB = CVA6Cfg.RVB;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:71:    cfg.ZKN = CVA6Cfg.ZKN;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:72:    cfg.RVV = CVA6Cfg.RVV;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:73:    cfg.RVC = CVA6Cfg.RVC;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:74:    cfg.RVH = CVA6Cfg.RVH;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:75:    cfg.RVZCB = CVA6Cfg.RVZCB;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:76:    cfg.RVZCMT = CVA6Cfg.RVZCMT;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:77:    cfg.RVZCMP = CVA6Cfg.RVZCMP;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:78:    cfg.XFVec = CVA6Cfg.XFVec;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:79:    cfg.CvxifEn = CVA6Cfg.CvxifEn;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:80:    cfg.CoproType = CVA6Cfg.CoproType;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:81:    cfg.RVZiCond = CVA6Cfg.RVZiCond;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:82:    cfg.RVZiCbom = CVA6Cfg.RVZiCbom;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:83:    cfg.RVZicntr = CVA6Cfg.RVZicntr;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:84:    cfg.RVZihpm = CVA6Cfg.RVZihpm;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:85:    cfg.NR_SB_ENTRIES = CVA6Cfg.NrScoreboardEntries;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:86:    cfg.TRANS_ID_BITS = $clog2(CVA6Cfg.NrScoreboardEntries);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:96:    cfg.NrRgprPorts = unsigned'(CVA6Cfg.SuperscalarEn ? 4 : 2);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:97:    // cfg.NrRgprPorts = unsigned'(CVA6Cfg.SuperscalarEn ? 6 : 3);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:100:    cfg.PerfCounterEn = CVA6Cfg.PerfCounterEn;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:101:    cfg.MmuPresent = CVA6Cfg.MmuPresent;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:102:    cfg.RVS = CVA6Cfg.RVS;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:103:    cfg.RVU = CVA6Cfg.RVU;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:104:    cfg.SoftwareInterruptEn = CVA6Cfg.SoftwareInterruptEn;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:106:    cfg.HaltAddress = CVA6Cfg.HaltAddress;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:107:    cfg.ExceptionAddress = CVA6Cfg.ExceptionAddress;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:108:    cfg.RASDepth = CVA6Cfg.RASDepth;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:109:    cfg.BTBEntries = CVA6Cfg.BTBEntries;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:110:    cfg.BPType = CVA6Cfg.BPType;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:111:    cfg.BHTEntries = CVA6Cfg.BHTEntries;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:112:    cfg.BHTHist = CVA6Cfg.BHTHist;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:113:    cfg.DmBaseAddress = CVA6Cfg.DmBaseAddress;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:114:    cfg.TvalEn = CVA6Cfg.TvalEn;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:115:    cfg.DirectVecOnly = CVA6Cfg.DirectVecOnly;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:116:    cfg.NrPMPEntries = CVA6Cfg.NrPMPEntries;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:117:    cfg.PMPCfgRstVal = CVA6Cfg.PMPCfgRstVal;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:118:    cfg.PMPAddrRstVal = CVA6Cfg.PMPAddrRstVal;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:119:    cfg.PMPEntryReadOnly = CVA6Cfg.PMPEntryReadOnly;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:120:    cfg.PMPNapotEn = CVA6Cfg.PMPNapotEn;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:121:    cfg.NOCType = CVA6Cfg.NOCType;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:122:    cfg.NrNonIdempotentRules = CVA6Cfg.NrNonIdempotentRules;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:123:    cfg.NonIdempotentAddrBase = CVA6Cfg.NonIdempotentAddrBase;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:124:    cfg.NonIdempotentLength = CVA6Cfg.NonIdempotentLength;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:125:    cfg.NrExecuteRegionRules = CVA6Cfg.NrExecuteRegionRules;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:126:    cfg.ExecuteRegionAddrBase = CVA6Cfg.ExecuteRegionAddrBase;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:127:    cfg.ExecuteRegionLength = CVA6Cfg.ExecuteRegionLength;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:128:    cfg.NrCachedRegionRules = CVA6Cfg.NrCachedRegionRules;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:129:    cfg.CachedRegionAddrBase = CVA6Cfg.CachedRegionAddrBase;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:130:    cfg.CachedRegionLength = CVA6Cfg.CachedRegionLength;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:131:    cfg.MaxOutstandingStores = CVA6Cfg.MaxOutstandingStores;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:132:    cfg.DebugEn = CVA6Cfg.DebugEn;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:133:    cfg.SDTRIG = CVA6Cfg.SDTRIG;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:134:    cfg.Mcontrol6 = CVA6Cfg.Mcontrol6;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:135:    cfg.Icount = CVA6Cfg.Icount;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:136:    cfg.Etrigger = CVA6Cfg.Etrigger;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:137:    cfg.Itrigger = CVA6Cfg.Itrigger;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:138:    cfg.NonIdemPotenceEn = (CVA6Cfg.NrNonIdempotentRules > 0) && (CVA6Cfg.NonIdempotentLength > 0);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:139:    cfg.AxiBurstWriteEn = CVA6Cfg.AxiBurstWriteEn;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:141:    cfg.ICACHE_SET_ASSOC = CVA6Cfg.IcacheSetAssoc;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:142:    cfg.ICACHE_SET_ASSOC_WIDTH = CVA6Cfg.IcacheSetAssoc > 1 ? $clog2(CVA6Cfg.IcacheSetAssoc) :
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:143:        CVA6Cfg.IcacheSetAssoc;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:146:    cfg.ICACHE_LINE_WIDTH = CVA6Cfg.IcacheLineWidth;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:147:    cfg.ICACHE_USER_LINE_WIDTH = (CVA6Cfg.AxiUserWidth == 1) ? 4 : CVA6Cfg.IcacheLineWidth;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:148:    cfg.DCacheType = CVA6Cfg.DCacheType;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:149:    cfg.DcacheIdWidth = CVA6Cfg.DcacheIdWidth;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:150:    cfg.DCACHE_SET_ASSOC = CVA6Cfg.DcacheSetAssoc;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:151:    cfg.DCACHE_SET_ASSOC_WIDTH = CVA6Cfg.DcacheSetAssoc > 1 ? $clog2(CVA6Cfg.DcacheSetAssoc) :
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:152:        CVA6Cfg.DcacheSetAssoc;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:155:    cfg.DCACHE_LINE_WIDTH = CVA6Cfg.DcacheLineWidth;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:156:    cfg.DCACHE_USER_LINE_WIDTH = (CVA6Cfg.AxiUserWidth == 1) ? 4 : CVA6Cfg.DcacheLineWidth;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:157:    cfg.DCACHE_USER_WIDTH = CVA6Cfg.AxiUserWidth;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:161:    cfg.DCACHE_MAX_TX = unsigned'(2 ** CVA6Cfg.MemTidWidth);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:163:    cfg.DcacheFlushOnFence = CVA6Cfg.DcacheFlushOnFence;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:164:    cfg.DcacheFlushOnFenceI = CVA6Cfg.DcacheFlushOnFenceI;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:165:    cfg.DcacheInvalidateOnFlush = CVA6Cfg.DcacheInvalidateOnFlush;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:167:    cfg.DATA_USER_EN = CVA6Cfg.DataUserEn;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:168:    cfg.WtDcacheWbufDepth = CVA6Cfg.WtDcacheWbufDepth;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:169:    cfg.FETCH_USER_WIDTH = CVA6Cfg.FetchUserWidth;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:170:    cfg.FETCH_USER_EN = CVA6Cfg.FetchUserEn;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:171:    cfg.AXI_USER_EN = CVA6Cfg.DataUserEn | CVA6Cfg.FetchUserEn;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:173:    cfg.FETCH_WIDTH = unsigned'(CVA6Cfg.SuperscalarEn ? 64 : 32);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:175:    cfg.INSTR_PER_FETCH = cfg.FETCH_WIDTH / (CVA6Cfg.RVC ? 16 : 32);
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:178:    cfg.ModeW = (CVA6Cfg.XLEN == 32) ? 1 : 4;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:179:    cfg.ASIDW = (CVA6Cfg.XLEN == 32) ? 9 : 16;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:180:    cfg.VMIDW = (CVA6Cfg.XLEN == 32) ? 7 : 14;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:181:    cfg.PPNW = (CVA6Cfg.XLEN == 32) ? 22 : 44;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:182:    cfg.GPPNW = (CVA6Cfg.XLEN == 32) ? 22 : 29;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:183:    cfg.MODE_SV = (CVA6Cfg.XLEN == 32) ? config_pkg::ModeSv32 : config_pkg::ModeSv39;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:186:    cfg.InstrTlbEntries = CVA6Cfg.InstrTlbEntries;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:187:    cfg.DataTlbEntries = CVA6Cfg.DataTlbEntries;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:188:    cfg.UseSharedTlb = CVA6Cfg.UseSharedTlb;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:189:    cfg.SvnapotEn = CVA6Cfg.SvnapotEn;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/build_config_pkg.sv:190:    cfg.SharedTlbDepth = CVA6Cfg.SharedTlbDepth;
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/config_pkg.sv:62:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/config_pkg.sv:268:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:60:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:82:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:100:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:131:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:145:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:154:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:164:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:174:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:185:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:193:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:202:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:209:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:306:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:321:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:810:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:822:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:845:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:852:  typedef struct packed {
/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/packages/riscv_pkg.sv:862:  typedef struct packed {
```

## H. Files Modified

- Created/updated this report only: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/docs/11_icache_interface_mapping_plan.md`
- No RTL source was modified.

## I1b. Exact Interface Findings

- Time: Wed May 27 08:34:08 AM UTC 2026

### CV32E40P Top Port Reality

```text
26:module cv32e40p_top #(
27:    parameter COREV_PULP = 0, // PULP ISA Extension (incl. custom CSRs and hardware loop, excl. cv.elw)
28:    parameter COREV_CLUSTER = 0,  // PULP Cluster interface (incl. cv.elw)
29:    parameter FPU = 0,  // Floating Point Unit (interfaced via APU interface)
30:    parameter FPU_ADDMUL_LAT = 0,  // Floating-Point ADDition/MULtiplication computing lane pipeline registers number
31:    parameter FPU_OTHERS_LAT = 0,  // Floating-Point COMParison/CONVersion computing lanes pipeline registers number
32:    parameter ZFINX = 0,  // Float-in-General Purpose registers
33:    parameter NUM_MHPMCOUNTERS = 1
34:) (
35:    // Clock and Reset
36:    input logic clk_i,
37:    input logic rst_ni,
38:
39:    input logic pulp_clock_en_i,  // PULP clock enable (only used if COREV_CLUSTER = 1)
40:    input logic scan_cg_en_i,  // Enable all clock gates for testing
41:
42:    // Core ID, Cluster ID, debug mode halt address and boot address are considered more or less static
43:    input logic [31:0] boot_addr_i,
44:    input logic [31:0] mtvec_addr_i,
45:    input logic [31:0] dm_halt_addr_i,
46:    input logic [31:0] hart_id_i,
47:    input logic [31:0] dm_exception_addr_i,
48:
49:    // Instruction memory interface
50:    output logic        instr_req_o,
51:    input  logic        instr_gnt_i,
52:    input  logic        instr_rvalid_i,
53:    output logic [31:0] instr_addr_o,
54:    input  logic [31:0] instr_rdata_i,
55:
56:    // Data memory interface
57:    output logic        data_req_o,
58:    input  logic        data_gnt_i,
59:    input  logic        data_rvalid_i,
60:    output logic        data_we_o,
61:    output logic [ 3:0] data_be_o,
62:    output logic [31:0] data_addr_o,
63:    output logic [31:0] data_wdata_o,
64:    input  logic [31:0] data_rdata_i,
65:
66:    // Interrupt inputs
67:    input  logic [31:0] irq_i,  // CLINT interrupts + CLINT extension interrupts
68:    output logic        irq_ack_o,
69:    output logic [ 4:0] irq_id_o,
70:
71:    // Debug Interface
72:    input  logic debug_req_i,
73:    output logic debug_havereset_o,
74:    output logic debug_running_o,
75:    output logic debug_halted_o,
76:
77:    // CPU Control Signals
78:    input  logic fetch_enable_i,
79:    output logic core_sleep_o
80:);
```

Note: if `cv32e40p_top.sv` does not expose `instr_err_i`, the first full-L1 top cannot connect an instruction bus error directly into the top-level core wrapper. The core currently ties bus instruction error internally where applicable.

### CVA6 I-Cache Typedefs

```systemverilog
     1	// Compile-only harness for the real CVA6 I-Cache DUT.
     2	// This file is not an I-Cache replacement and must not be used as functional logic.
     3	
     4	module cva6_icache_compile_harness
     5	  import ariane_pkg::*;
     6	  import wt_cache_pkg::*;
     7	#(
     8	    parameter config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(
     9	        cva6_config_pkg::cva6_cfg
    10	    )
    11	) ();
    12	
    13	  typedef struct packed {
    14	    logic [CVA6Cfg.XLEN-1:0]  cause;
    15	    logic [CVA6Cfg.XLEN-1:0]  tval;
    16	    logic [CVA6Cfg.GPLEN-1:0] tval2;
    17	    logic [31:0]              tinst;
    18	    logic                     gva;
    19	    logic                     valid;
    20	  } exception_t;
    21	
    22	  typedef struct packed {
    23	    logic                    fetch_valid;
    24	    logic [CVA6Cfg.PLEN-1:0] fetch_paddr;
    25	    exception_t              fetch_exception;
    26	  } icache_areq_t;
    27	
    28	  typedef struct packed {
    29	    logic                    fetch_req;
    30	    logic [CVA6Cfg.VLEN-1:0] fetch_vaddr;
    31	  } icache_arsp_t;
    32	
    33	  typedef struct packed {
    34	    logic                    req;
    35	    logic                    kill_s1;
    36	    logic                    kill_s2;
    37	    logic                    spec;
    38	    logic [CVA6Cfg.VLEN-1:0] vaddr;
    39	  } icache_dreq_t;
    40	
    41	  typedef struct packed {
    42	    logic                                ready;
    43	    logic                                valid;
    44	    logic [CVA6Cfg.FETCH_WIDTH-1:0]      data;
    45	    logic [CVA6Cfg.FETCH_USER_WIDTH-1:0] user;
    46	    logic [CVA6Cfg.VLEN-1:0]             vaddr;
    47	    exception_t                          ex;
    48	  } icache_drsp_t;
    49	
    50	  typedef struct packed {
    51	    logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] way;
    52	    logic [CVA6Cfg.PLEN-1:0]                   paddr;
    53	    logic                                      nc;
    54	    logic [CVA6Cfg.MEM_TID_WIDTH-1:0]          tid;
    55	  } icache_req_t;
    56	
    57	  typedef struct packed {
    58	    wt_cache_pkg::icache_in_t                  rtype;
    59	    logic [CVA6Cfg.ICACHE_LINE_WIDTH-1:0]      data;
    60	    logic [CVA6Cfg.ICACHE_USER_LINE_WIDTH-1:0] user;
    61	    struct packed {
    62	      logic                                      vld;
    63	      logic                                      all;
    64	      logic [CVA6Cfg.ICACHE_INDEX_WIDTH-1:0]     idx;
    65	      logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] way;
    66	    } inv;
    67	    logic [CVA6Cfg.MEM_TID_WIDTH-1:0]          tid;
    68	  } icache_rtrn_t;
    69	
    70	  logic clk_i;
    71	  logic rst_ni;
    72	  logic flush_i;
    73	  logic en_i;
    74	  logic miss_o;
    75	
    76	  icache_areq_t areq_i;
    77	  icache_arsp_t areq_o;
    78	  icache_dreq_t dreq_i;
    79	  icache_drsp_t dreq_o;
    80	
    81	  logic         mem_rtrn_vld_i;
    82	  icache_rtrn_t mem_rtrn_i;
    83	  logic         mem_data_req_o;
    84	  logic         mem_data_ack_i;
    85	  icache_req_t  mem_data_o;
    86	
    87	  always_comb begin
    88	    clk_i          = 1'b0;
    89	    rst_ni         = 1'b1;
    90	    flush_i        = 1'b0;
    91	    en_i           = 1'b1;
    92	    areq_i         = '0;
    93	    dreq_i         = '0;
    94	    mem_rtrn_vld_i = 1'b0;
    95	    mem_rtrn_i     = '0;
    96	    mem_data_ack_i = 1'b0;
    97	  end
    98	
    99	  cva6_icache #(
   100	      .CVA6Cfg       (CVA6Cfg),
   101	      .icache_areq_t (icache_areq_t),
   102	      .icache_arsp_t (icache_arsp_t),
   103	      .icache_dreq_t (icache_dreq_t),
   104	      .icache_drsp_t (icache_drsp_t),
   105	      .icache_req_t  (icache_req_t),
   106	      .icache_rtrn_t (icache_rtrn_t),
   107	      .RdTxId        ('0)
   108	  ) i_cva6_icache (
   109	      .clk_i          (clk_i),
   110	      .rst_ni         (rst_ni),
   111	      .flush_i        (flush_i),
   112	      .en_i           (en_i),
   113	      .miss_o         (miss_o),
   114	      .areq_i         (areq_i),
   115	      .areq_o         (areq_o),
   116	      .dreq_i         (dreq_i),
   117	      .dreq_o         (dreq_o),
   118	      .mem_rtrn_vld_i (mem_rtrn_vld_i),
   119	      .mem_rtrn_i     (mem_rtrn_i),
   120	      .mem_data_req_o (mem_data_req_o),
   121	      .mem_data_ack_i (mem_data_ack_i),
   122	      .mem_data_o     (mem_data_o)
   123	  );
   124	
   125	endmodule
```

### Handshake / Refill Excerpt

```systemverilog
   130	  state_e state_d, state_q;
   131	
   132	  ///////////////////////////////////////////////////////
   133	  // address -> cl_index mapping, interface plumbing
   134	  ///////////////////////////////////////////////////////
   135	
   136	  // extract tag from physical address, check if NC
   137	  assign cl_tag_d  = (areq_i.fetch_valid) ? areq_i.fetch_paddr[CVA6Cfg.ICACHE_TAG_WIDTH+CVA6Cfg.ICACHE_INDEX_WIDTH-1:CVA6Cfg.ICACHE_INDEX_WIDTH] : cl_tag_q;
   138	
   139	  // noncacheable if request goes to I/O space, or if cache is disabled
   140	  assign paddr_is_nc = (~cache_en_q) | (~config_pkg::is_inside_cacheable_regions(
   141	      CVA6Cfg, {{64 - CVA6Cfg.PLEN{1'b0}}, cl_tag_d, {CVA6Cfg.ICACHE_INDEX_WIDTH{1'b0}}}
   142	  ));
   143	
   144	  // pass exception through
   145	  assign dreq_o.ex = areq_i.fetch_exception;
   146	
   147	  // latch this in case we have to stall later on
   148	  // make sure this is 32bit aligned
   149	  assign vaddr_d = (dreq_o.ready & dreq_i.req) ? dreq_i.vaddr : vaddr_q;
   150	  assign areq_o.fetch_vaddr = (vaddr_q >> CVA6Cfg.FETCH_ALIGN_BITS) << CVA6Cfg.FETCH_ALIGN_BITS;
   151	
   152	  // split virtual address into index and offset to address cache arrays
   153	  assign cl_index = vaddr_d[CVA6Cfg.ICACHE_INDEX_WIDTH-1:ICACHE_OFFSET_WIDTH];
   154	
   155	
   156	  if (CVA6Cfg.NOCType == config_pkg::NOC_TYPE_AXI4_ATOP) begin : gen_axi_offset
   157	    // if we generate a noncacheable access, the word will be at offset 0 or 4 in the cl coming from memory
   158	    assign cl_offset_d = ( dreq_o.ready & dreq_i.req)      ? (dreq_i.vaddr >> CVA6Cfg.FETCH_ALIGN_BITS) << CVA6Cfg.FETCH_ALIGN_BITS :
   159	                         ( paddr_is_nc  & mem_data_req_o ) ? {{ICACHE_OFFSET_WIDTH-1{1'b0}}, cl_offset_q[2]}<<2 : // needed since we transfer 32bit over a 64bit AXI bus in this case
   160	        cl_offset_q;
   161	    // request word address instead of cl address in case of NC access
   162	    assign mem_data_o.paddr = (paddr_is_nc) ? {cl_tag_d, vaddr_q[CVA6Cfg.ICACHE_INDEX_WIDTH-1:3], 3'b0} :                                         // align to 64bit
   163	        {cl_tag_d, vaddr_q[CVA6Cfg.ICACHE_INDEX_WIDTH-1:ICACHE_OFFSET_WIDTH], {ICACHE_OFFSET_WIDTH{1'b0}}}; // align to cl
   164	  end else begin : gen_piton_offset
   165	    // icache fills are either cachelines or 4byte fills, depending on whether they go to the Piton I/O space or not.
   166	    // since the piton cache system replicates the data, we can always index the full CL
   167	    assign cl_offset_d = (dreq_o.ready & dreq_i.req) ? {dreq_i.vaddr >> 2, 2'b0} : cl_offset_q;
   168	
   169	    // request word address instead of cl address in case of NC access
   170	    assign mem_data_o.paddr = (paddr_is_nc) ? {cl_tag_d, vaddr_q[CVA6Cfg.ICACHE_INDEX_WIDTH-1:2], 2'b0} :                                         // align to 32bit
   171	        {cl_tag_d, vaddr_q[CVA6Cfg.ICACHE_INDEX_WIDTH-1:ICACHE_OFFSET_WIDTH], {ICACHE_OFFSET_WIDTH{1'b0}}}; // align to cl
   172	  end
   173	
   174	
   175	  assign mem_data_o.tid = RdTxId;
   176	
   177	  assign mem_data_o.nc  = paddr_is_nc;
   178	  // way that is being replaced
   179	  assign mem_data_o.way = repl_way;
   180	  assign dreq_o.vaddr   = vaddr_q;
   181	
   182	  // invalidations take two cycles
   183	  assign inv_d          = inv_en;
   184	
   185	  ///////////////////////////////////////////////////////
   186	  // main control logic
   187	  ///////////////////////////////////////////////////////
   188	  logic addr_ni;
   189	  assign addr_ni = config_pkg::is_inside_nonidempotent_regions(
   190	      CVA6Cfg, {{64 - CVA6Cfg.PLEN{1'b0}}, areq_i.fetch_paddr}
   191	  );
   192	  always_comb begin : p_fsm
   193	    // default assignment
   194	    state_d = state_q;
   195	    cache_en_d   = cache_en_q & en_i;// disabling the cache is always possible, enable needs to go via flush
   196	    flush_en = 1'b0;
   197	    cmp_en_d = 1'b0;
   198	    cache_rden = 1'b0;
   199	    cache_wren = 1'b0;
   200	    inv_en = 1'b0;
   201	    flush_d = flush_q | flush_i;  // register incoming flush
   202	
   203	    // interfaces
   204	    dreq_o.ready = 1'b0;
   205	    areq_o.fetch_req = 1'b0;
   206	    dreq_o.valid = 1'b0;
   207	    mem_data_req_o = 1'b0;
   208	    // performance counter
   209	    miss_o = 1'b0;
   210	
   211	    // handle invalidations unconditionally
   212	    // note: invals are mutually exclusive with
   213	    // ifills, since both arrive over the same IF
   214	    // however, we need to make sure below that we
   215	    // do not trigger a cache readout at the same time...
   216	    if (mem_rtrn_vld_i && mem_rtrn_i.rtype == ICACHE_INV_REQ) begin
   217	      inv_en = 1'b1;
   218	    end
   219	
   220	    unique case (state_q)
   221	      //////////////////////////////////
   222	      // this clears all valid bits
   223	      FLUSH: begin
   224	        flush_en = 1'b1;
   225	        if (flush_done) begin
   226	          state_d = IDLE;
   227	          flush_d = 1'b0;
   228	          // if the cache was not enabled set this
   229	          cache_en_d = en_i;
   230	        end
   231	      end
   232	      //////////////////////////////////
   233	      // wait for an incoming request
   234	      IDLE: begin
   235	        // only enable tag comparison if cache is enabled
   236	        cmp_en_d = cache_en_q;
   237	
   238	        // handle pending flushes, or perform cache clear upon enable
   239	        if (flush_d || (en_i && !cache_en_q)) begin
   240	          state_d = FLUSH;
   241	          // wait for incoming requests
   242	        end else begin
   243	          // mem requests are for sure invals here
   244	          if (!mem_rtrn_vld_i) begin
   245	            dreq_o.ready = 1'b1;
   246	            // we have a new request
   247	            if (dreq_i.req) begin
   248	              cache_rden = 1'b1;
   249	              state_d    = READ;
   250	            end
   251	          end
   252	          if (dreq_i.kill_s1) begin
   253	            state_d = IDLE;
   254	          end
   255	        end
   256	      end
   257	      //////////////////////////////////
   258	      // check whether we have a hit
   259	      // in case the cache is disabled,
   260	      // or in case the address is NC, we
   261	      // reuse the miss mechanism to handle
   262	      // the request
   263	      READ: begin
   264	        areq_o.fetch_req = '1;
   265	        // only enable tag comparison if cache is enabled
   266	        cmp_en_d    = cache_en_q;
   267	        // readout speculatively
   268	        cache_rden  = cache_en_q;
   269	
   270	        if (areq_i.fetch_valid && (!dreq_i.spec || ((CVA6Cfg.NonIdemPotenceEn && !addr_ni) || (!CVA6Cfg.NonIdemPotenceEn)))) begin
   271	          // check if we have to flush
   272	          if (flush_d) begin
   273	            state_d = IDLE;
   274	            // we have a hit or an exception output valid result
   275	          end else if (((|cl_hit && cache_en_q) || areq_i.fetch_exception.valid) && !inv_q) begin
   276	            dreq_o.valid = ~dreq_i.kill_s2;  // just don't output in this case
   277	            state_d      = IDLE;
   278	
   279	            // we can accept another request
   280	            // and stay here, but only if no inval is coming in
   281	            // note: we are not expecting ifill return packets here...
   282	            if (!mem_rtrn_vld_i) begin
   283	              dreq_o.ready = 1'b1;
   284	              if (dreq_i.req) begin
   285	                state_d = READ;
   286	              end
   287	            end
   288	            // if a request is being killed at this stage,
   289	            // we have to bail out and wait for the address translation to complete
   290	            if (dreq_i.kill_s1) begin
   291	              state_d = IDLE;
   292	            end
   293	            // we have a miss / NC transaction
   294	          end else if (dreq_i.kill_s2) begin
   295	            state_d = IDLE;
   296	          end else if (!inv_q) begin
   297	            cmp_en_d = 1'b0;
   298	            // only count this as a miss if the cache is enabled, and
   299	            // the address is cacheable
   300	            // send out ifill request
   301	            mem_data_req_o = 1'b1;
   302	            if (mem_data_ack_i) begin
   303	              miss_o  = ~paddr_is_nc;
   304	              state_d = MISS;
   305	            end
   306	          end
   307	          // bail out if this request is being killed (and we missed on the TLB)
   308	        end else if (dreq_i.kill_s2 || flush_d) begin
   309	          state_d = KILL_ATRANS;
   310	        end
   311	      end
   312	      //////////////////////////////////
   313	      // wait until the memory transaction
   314	      // returns. do not write to memory
   315	      // if the nc bit is set.
   316	      MISS: begin
   317	        // note: this is mutually exclusive with ICACHE_INV_REQ,
   318	        // so we do not have to check for invals here
   319	        if (mem_rtrn_vld_i && mem_rtrn_i.rtype == ICACHE_IFILL_ACK) begin
   320	          state_d = IDLE;
   321	          // only return data if request is not being killed
   322	          if (!(dreq_i.kill_s2 || flush_d)) begin
   323	            dreq_o.valid = 1'b1;
   324	            // only write to cache if this address is cacheable
   325	            cache_wren   = ~paddr_is_nc;
   326	          end
   327	          // bail out if this request is being killed
   328	        end else if (dreq_i.kill_s2 || flush_d) begin
   329	          state_d = KILL_MISS;
   330	        end
   331	      end
   332	      //////////////////////////////////
   333	      // killed address translation,
   334	      // wait until paddr is valid, and go
   335	      // back to idle
   336	      KILL_ATRANS: begin
   337	        areq_o.fetch_req = '1;
   338	        if (areq_i.fetch_valid) begin
   339	          state_d = IDLE;
   340	        end
   341	      end
   342	      //////////////////////////////////
   343	      // killed miss,
   344	      // wait until memory responds and
   345	      // go back to idle
   346	      KILL_MISS: begin
   347	        if (mem_rtrn_vld_i && mem_rtrn_i.rtype == ICACHE_IFILL_ACK) begin
   348	          state_d = IDLE;
   349	        end
   350	      end
   351	      default: begin
   352	        // we should never get here
   353	        state_d = FLUSH;
   354	      end
   355	    endcase  // state_q
   356	  end
   357	
   358	  ///////////////////////////////////////////////////////
   359	  // valid bit invalidation and replacement strategy
   360	  ///////////////////////////////////////////////////////
```

### Config Constants

```text
13:  localparam CVA6ConfigXlen = 32;
23:  localparam CVA6ConfigCExtEn = 1;
32:  localparam CVA6ConfigAxiAddrWidth = 64;
33:  localparam CVA6ConfigAxiDataWidth = 64;
34:  localparam CVA6ConfigFetchUserEn = 0;
35:  localparam CVA6ConfigFetchUserWidth = CVA6ConfigXlen;
37:  localparam CVA6ConfigDataUserWidth = CVA6ConfigXlen;
39:  localparam CVA6ConfigIcacheByteSize = 16384;
40:  localparam CVA6ConfigIcacheSetAssoc = 4;
41:  localparam CVA6ConfigIcacheLineWidth = 128;
44:  localparam CVA6ConfigDcacheLineWidth = 128;
47:  localparam CVA6ConfigMemTidWidth = 4;
69:  localparam CVA6ConfigMmuPresent = 1;
74:      XLEN: unsigned'(CVA6ConfigXlen),
82:      AxiAddrWidth: unsigned'(CVA6ConfigAxiAddrWidth),
83:      AxiDataWidth: unsigned'(CVA6ConfigAxiDataWidth),
86:      MemTidWidth: unsigned'(CVA6ConfigMemTidWidth),
97:      RVC: bit'(CVA6ConfigCExtEn),
111:      MmuPresent: bit'(CVA6ConfigMmuPresent),
148:      IcacheByteSize: unsigned'(CVA6ConfigIcacheByteSize),
149:      IcacheSetAssoc: unsigned'(CVA6ConfigIcacheSetAssoc),
150:      IcacheLineWidth: unsigned'(CVA6ConfigIcacheLineWidth),
154:      DcacheLineWidth: unsigned'(CVA6ConfigDcacheLineWidth),
160:      FetchUserWidth: unsigned'(CVA6ConfigFetchUserWidth),
161:      FetchUserEn: unsigned'(CVA6ConfigFetchUserEn),
```

### Filelist Path Risk

```text
1:+incdir+/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages
2:+incdir+/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/vendor/common_cells
3:+incdir+/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/vendor/tech_cells_generic
4:+incdir+/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/util
5:/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/config_pkg.sv
6:/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/cv32a6_imac_sv32_config_pkg.sv
7:/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/riscv_pkg.sv
8:/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/build_config_pkg.sv
9:/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/ariane_pkg.sv
10:/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/packages/wt_cache_pkg.sv
11:/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/vendor/common_cells/cf_math_pkg.sv
12:/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/vendor/common_cells/lzc.sv
13:/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/vendor/common_cells/lfsr.sv
14:/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/vendor/tech_cells_generic/tc_sram.sv
15:/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/util/tc_sram_wrapper.sv
16:/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/util/tc_sram_wrapper_cache_techno.sv
17:/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/util/sram.sv
18:/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/util/sram_cache.sv
19:/media/sf_source_env/cv32_full_l1_cache/rtl/l1_cache/icache/cva6_icache_full/rtl/cva6_icache.sv
```

Decision note: if the old path appears above, do not edit the I-Cache bundle filelist; create `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/sim/cva6_icache_full_for_cv32.f` later in PHASE I7.
