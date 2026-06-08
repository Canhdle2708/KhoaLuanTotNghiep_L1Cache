# PHASE I3 - I-Cache Memory Adapter Design

- Time: Wed May 27 08:40:39 AM UTC 2026
- ICACHE_ROOT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full`
- WORK_ROOT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work`
- I-Cache DUT: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/cva6_icache_full/rtl/cva6_icache.sv`
- Current D-Cache-only top: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/rtl/cv32e40p_l1_dcache_top.sv`

## I3-pre Status

This step only inspects the existing memory/top structure before creating `cva6_icache_mem_adapter.sv`.
No RTL source was modified in this step.

## CVA6 I-Cache Refill Interface

Request side from `cva6_icache.sv`:

- `mem_data_req_o`: request valid
- `mem_data_ack_i`: request accepted
- `mem_data_o.paddr`: physical refill address
- `mem_data_o.nc`: non-cacheable indicator
- `mem_data_o.way`: replacement way
- `mem_data_o.tid`: transaction id

Return side:

- `mem_rtrn_vld_i`: return valid
- `mem_rtrn_i.rtype = wt_cache_pkg::ICACHE_IFILL_ACK`: refill return
- `mem_rtrn_i.data`: `CVA6Cfg.ICACHE_LINE_WIDTH` bits, currently expected 128-bit
- `mem_rtrn_i.user`: user line payload, tied 0 unless needed
- `mem_rtrn_i.tid`: transaction id echoed back

## Exact typedef evidence

```systemverilog
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
```

## Current D-Cache-only Top Evidence

```systemverilog
     1	module cv32e40p_l1_dcache_top;
     2	
     3	  import cv32_hpdcache_if_pkg::*;
     4	
     5	  localparam int unsigned IMEM_WORDS = 256;
     6	  localparam int unsigned DMEM_WORDS = 4096;
     7	  localparam int unsigned MEM_READ_LATENCY = 2;
     8	  localparam logic [31:0] DONE_ADDR = 32'h2000_0004;
     9	
    10	  logic clk = 1'b0;
    11	  logic rst_n = 1'b0;
    12	  logic fetch_enable = 1'b0;
    13	  logic done = 1'b0;
    14	  logic pass = 1'b0;
    15	
    16	  logic instr_req;
    17	  logic instr_gnt;
    18	  logic instr_rvalid;
    19	  logic [31:0] instr_addr;
    20	  logic [31:0] instr_rdata;
    21	  logic [31:0] instr_rdata_q;
    22	  logic instr_rvalid_q;
    23	
    24	  logic data_req;
    25	  logic data_gnt;
    26	  logic data_rvalid;
    27	  logic data_we;
    28	  logic [3:0] data_be;
    29	  logic [31:0] data_addr;
    30	  logic [31:0] data_wdata;
    31	  logic [31:0] data_rdata;
    32	  logic data_err;
    33	
    34	  logic cache_req_valid;
    35	  logic cache_req_ready;
    36	  cv32_hpdcache_req_t cache_req;
    37	  logic cache_rsp_valid;
    38	  cv32_hpdcache_rsp_t cache_rsp;
    39	
    40	  logic mem_req_read_ready;
    41	  logic mem_req_read_valid;
    42	  logic [31:0] mem_req_read_addr;
    43	  logic [7:0] mem_req_read_len;
    44	  logic [2:0] mem_req_read_size;
    45	  logic [3:0] mem_req_read_id;
    46	  logic [1:0] mem_req_read_command;
    47	  logic [3:0] mem_req_read_atomic;
    48	  logic mem_req_read_cacheable;
    49	
    50	  logic mem_resp_read_ready;
    51	  logic mem_resp_read_valid;
    52	  logic [1:0] mem_resp_read_error;
    53	  logic [3:0] mem_resp_read_id;
    54	  logic [127:0] mem_resp_read_data;
    55	  logic mem_resp_read_last;
    56	
    57	  logic mem_req_write_ready;
    58	  logic mem_req_write_valid;
    59	  logic [31:0] mem_req_write_addr;
    60	  logic [7:0] mem_req_write_len;
    61	  logic [2:0] mem_req_write_size;
    62	  logic [3:0] mem_req_write_id;
    63	  logic [1:0] mem_req_write_command;
    64	  logic [3:0] mem_req_write_atomic;
    65	  logic mem_req_write_cacheable;
    66	
    67	  logic mem_req_write_data_ready;
    68	  logic mem_req_write_data_valid;
    69	  logic [127:0] mem_req_write_data;
    70	  logic [15:0] mem_req_write_be;
    71	  logic mem_req_write_last;
    72	
    73	  logic mem_resp_write_ready;
    74	  logic mem_resp_write_valid;
    75	  logic mem_resp_write_is_atomic;
    76	  logic [1:0] mem_resp_write_error;
    77	  logic [3:0] mem_resp_write_id;
    78	
    79	  logic evt_cache_write_miss;
    80	  logic evt_cache_read_miss;
    81	  logic evt_write_req;
    82	  logic evt_read_req;
    83	  logic evt_stall;
    84	  logic wbuf_empty;
    85	
    86	  logic [31:0] imem [0:IMEM_WORDS-1];
    87	  logic [31:0] dmem [0:DMEM_WORDS-1];
    88	
    89	  int unsigned cycle_count;
    90	  int unsigned core_load_count;
    91	  int unsigned core_store_count;
    92	  int unsigned mem_read_count;
    93	  int unsigned mem_write_count;
    94	  int unsigned read_miss_count;
    95	  int unsigned write_miss_count;
    96	
    97	  logic rd_pending_q;
    98	  logic rd_valid_q;
    99	  int unsigned rd_delay_q;
   100	  logic [31:0] rd_addr_q;
   101	  logic [3:0] rd_id_q;
   102	
   103	  logic wr_addr_valid_q;
   104	  logic wr_resp_valid_q;
   105	  logic [31:0] wr_addr_q;
   106	  logic [3:0] wr_id_q;
   107	
   108	  initial begin : init_imem
   109	    for (int i = 0; i < IMEM_WORDS; i++) begin
   110	      imem[i] = 32'h0000_0013;
   111	    end
   112	
   113	    // Store/load 0x100, fill same-index dirty lines at 0x200 and 0x300, then
   114	    // reload 0x100 to exercise a dirty-conflict path before DONE.
   115	    imem[0]  = 32'h1000_0093; // addi x1,  x0, 0x100
   116	    imem[1]  = 32'h0110_0113; // addi x2,  x0, 0x011
   117	    imem[2]  = 32'h0020_a023; // sw   x2,  0(x1)
   118	    imem[3]  = 32'h0000_a183; // lw   x3,  0(x1)
   119	    imem[4]  = 32'h0000_a203; // lw   x4,  0(x1)
   120	    imem[5]  = 32'h2000_0293; // addi x5,  x0, 0x200
   121	    imem[6]  = 32'h0220_0313; // addi x6,  x0, 0x022
   122	    imem[7]  = 32'h0062_a023; // sw   x6,  0(x5)
   123	    imem[8]  = 32'h3000_0393; // addi x7,  x0, 0x300
   124	    imem[9]  = 32'h0330_0413; // addi x8,  x0, 0x033
   125	    imem[10] = 32'h0083_a023; // sw   x8,  0(x7)
   126	    imem[11] = 32'h0000_a483; // lw   x9,  0(x1)
   127	    imem[12] = 32'h0090_a823; // sw   x9, 16(x1)
   128	    imem[13] = 32'h2000_0537; // lui  x10, 0x20000
   129	    imem[14] = 32'h0000_0593; // addi x11, x0, 0
   130	    imem[15] = 32'h00b5_2223; // sw   x11, 4(x10)
   131	    imem[16] = 32'h0000_006f; // jal  x0, 0
   132	  end
   133	
   134	  initial begin : init_dmem
   135	    for (int i = 0; i < DMEM_WORDS; i++) begin
   136	      dmem[i] = 32'h1000_0000 + i;
   137	    end
   138	  end
   139	
   140	  cv32e40p_top #(
   141	      .COREV_PULP      (0),
   142	      .COREV_CLUSTER   (0),
   143	      .FPU             (0),
   144	      .FPU_ADDMUL_LAT  (0),
   145	      .FPU_OTHERS_LAT  (0),
   146	      .ZFINX           (0),
   147	      .NUM_MHPMCOUNTERS(1)
   148	  ) core_i (
   149	      .clk_i (clk),
   150	      .rst_ni(rst_n),
   151	      .pulp_clock_en_i(1'b1),
   152	      .scan_cg_en_i(1'b0),
   153	      .boot_addr_i(32'h0000_0000),
   154	      .mtvec_addr_i(32'h0000_0000),
   155	      .dm_halt_addr_i(32'h0000_0800),
   156	      .hart_id_i(32'h0000_0000),
   157	      .dm_exception_addr_i(32'h0000_0000),
   158	      .instr_req_o(instr_req),
   159	      .instr_gnt_i(instr_gnt),
   160	      .instr_rvalid_i(instr_rvalid),
   161	      .instr_addr_o(instr_addr),
   162	      .instr_rdata_i(instr_rdata),
   163	      .data_req_o(data_req),
   164	      .data_gnt_i(data_gnt),
   165	      .data_rvalid_i(data_rvalid),
   166	      .data_we_o(data_we),
   167	      .data_be_o(data_be),
   168	      .data_addr_o(data_addr),
   169	      .data_wdata_o(data_wdata),
   170	      .data_rdata_i(data_rdata),
   171	      .irq_i(32'b0),
   172	      .irq_ack_o(),
   173	      .irq_id_o(),
   174	      .debug_req_i(1'b0),
   175	      .debug_havereset_o(),
   176	      .debug_running_o(),
   177	      .debug_halted_o(),
   178	      .fetch_enable_i(fetch_enable),
   179	      .core_sleep_o()
   180	  );
   181	
   182	  cv32_data_to_hpdcache_adapter adapter_i (
   183	      .clk_i(clk),
   184	      .rst_ni(rst_n),
   185	      .cv32_data_req_i(data_req),
   186	      .cv32_data_gnt_o(data_gnt),
   187	      .cv32_data_rvalid_o(data_rvalid),
   188	      .cv32_data_we_i(data_we),
   189	      .cv32_data_be_i(data_be),
   190	      .cv32_data_addr_i(data_addr),
   191	      .cv32_data_wdata_i(data_wdata),
   192	      .cv32_data_rdata_o(data_rdata),
   193	      .cv32_data_err_o(data_err),
   194	      .hpdcache_req_valid_o(cache_req_valid),
   195	      .hpdcache_req_ready_i(cache_req_ready),
   196	      .hpdcache_req_o(cache_req),
   197	      .hpdcache_rsp_valid_i(cache_rsp_valid),
   198	      .hpdcache_rsp_i(cache_rsp),
   199	      .busy_o(),
   200	      .outstanding_tid_o()
   201	  );
   202	
   203	  hpdcache_cv32_wrapper dcache_i (
   204	      .clk_i(clk),
   205	      .rst_ni(rst_n),
   206	      .req_valid_i(cache_req_valid),
   207	      .req_ready_o(cache_req_ready),
   208	      .req_i(cache_req),
   209	      .rsp_valid_o(cache_rsp_valid),
   210	      .rsp_o(cache_rsp),
   211	      .mem_req_read_ready_i(mem_req_read_ready),
   212	      .mem_req_read_valid_o(mem_req_read_valid),
   213	      .mem_req_read_addr_o(mem_req_read_addr),
   214	      .mem_req_read_len_o(mem_req_read_len),
   215	      .mem_req_read_size_o(mem_req_read_size),
   216	      .mem_req_read_id_o(mem_req_read_id),
   217	      .mem_req_read_command_o(mem_req_read_command),
   218	      .mem_req_read_atomic_o(mem_req_read_atomic),
   219	      .mem_req_read_cacheable_o(mem_req_read_cacheable),
   220	      .mem_resp_read_ready_o(mem_resp_read_ready),
   221	      .mem_resp_read_valid_i(mem_resp_read_valid),
   222	      .mem_resp_read_error_i(mem_resp_read_error),
   223	      .mem_resp_read_id_i(mem_resp_read_id),
   224	      .mem_resp_read_data_i(mem_resp_read_data),
   225	      .mem_resp_read_last_i(mem_resp_read_last),
   226	      .mem_req_write_ready_i(mem_req_write_ready),
   227	      .mem_req_write_valid_o(mem_req_write_valid),
   228	      .mem_req_write_addr_o(mem_req_write_addr),
   229	      .mem_req_write_len_o(mem_req_write_len),
   230	      .mem_req_write_size_o(mem_req_write_size),
   231	      .mem_req_write_id_o(mem_req_write_id),
   232	      .mem_req_write_command_o(mem_req_write_command),
   233	      .mem_req_write_atomic_o(mem_req_write_atomic),
   234	      .mem_req_write_cacheable_o(mem_req_write_cacheable),
   235	      .mem_req_write_data_ready_i(mem_req_write_data_ready),
   236	      .mem_req_write_data_valid_o(mem_req_write_data_valid),
   237	      .mem_req_write_data_o(mem_req_write_data),
   238	      .mem_req_write_be_o(mem_req_write_be),
   239	      .mem_req_write_last_o(mem_req_write_last),
   240	      .mem_resp_write_ready_o(mem_resp_write_ready),
   241	      .mem_resp_write_valid_i(mem_resp_write_valid),
   242	      .mem_resp_write_is_atomic_i(mem_resp_write_is_atomic),
   243	      .mem_resp_write_error_i(mem_resp_write_error),
   244	      .mem_resp_write_id_i(mem_resp_write_id),
   245	      .evt_cache_write_miss_o(evt_cache_write_miss),
   246	      .evt_cache_read_miss_o(evt_cache_read_miss),
   247	      .evt_write_req_o(evt_write_req),
   248	      .evt_read_req_o(evt_read_req),
   249	      .evt_stall_o(evt_stall),
   250	      .wbuf_empty_o(wbuf_empty)
   251	  );
   252	
   253	  assign instr_gnt = instr_req;
   254	  assign instr_rvalid = instr_rvalid_q;
   255	  assign instr_rdata = instr_rdata_q;
   256	
   257	  always @(posedge clk or negedge rst_n) begin
   258	    if (!rst_n) begin
   259	      instr_rvalid_q <= 1'b0;
   260	      instr_rdata_q <= 32'h0000_0013;
   261	    end else begin
   262	      instr_rvalid_q <= instr_req;
   263	      instr_rdata_q <= imem[instr_addr[31:2] % IMEM_WORDS];
   264	    end
   265	  end
   266	
   267	  function automatic logic [127:0] read_mem_line(input logic [31:0] addr);
   268	    automatic int unsigned base_word;
   269	    base_word = ({addr[31:4], 4'b0} >> 2) % DMEM_WORDS;
   270	    read_mem_line = {
   271	      dmem[(base_word + 3) % DMEM_WORDS],
   272	      dmem[(base_word + 2) % DMEM_WORDS],
   273	      dmem[(base_word + 1) % DMEM_WORDS],
   274	      dmem[(base_word + 0) % DMEM_WORDS]
   275	    };
   276	  endfunction
   277	
   278	  task automatic write_mem_beat(
   279	      input logic [31:0] addr,
   280	      input logic [127:0] data,
   281	      input logic [15:0] be
   282	  );
   283	    automatic int unsigned base_word;
   284	    base_word = ({addr[31:4], 4'b0} >> 2) % DMEM_WORDS;
   285	    for (int b = 0; b < 16; b++) begin
   286	      if (be[b]) begin
   287	        dmem[(base_word + (b / 4)) % DMEM_WORDS][8*(b % 4) +: 8] = data[8*b +: 8];
   288	      end
   289	    end
   290	  endtask
   291	
   292	  assign mem_req_read_ready = !rd_pending_q;
   293	  assign mem_resp_read_valid = rd_pending_q & rd_valid_q;
   294	  assign mem_resp_read_error = 2'b00;
   295	  assign mem_resp_read_id = rd_id_q;
   296	  assign mem_resp_read_data = read_mem_line(rd_addr_q);
   297	  assign mem_resp_read_last = 1'b1;
   298	
   299	  always @(posedge clk or negedge rst_n) begin
   300	    if (!rst_n) begin
   301	      rd_pending_q <= 1'b0;
   302	      rd_valid_q <= 1'b0;
   303	      rd_delay_q <= 0;
   304	      rd_addr_q <= 32'h0;
   305	      rd_id_q <= 4'h0;
   306	    end else begin
   307	      if (!rd_pending_q && mem_req_read_valid && mem_req_read_ready) begin
   308	        rd_pending_q <= 1'b1;
   309	        rd_valid_q <= 1'b0;
   310	        rd_delay_q <= MEM_READ_LATENCY;
   311	        rd_addr_q <= mem_req_read_addr;
   312	        rd_id_q <= mem_req_read_id;
   313	      end else if (rd_pending_q && !rd_valid_q) begin
   314	        if (rd_delay_q == 0) begin
   315	          rd_valid_q <= 1'b1;
   316	        end else begin
   317	          rd_delay_q <= rd_delay_q - 1;
   318	        end
   319	      end else if (rd_pending_q && rd_valid_q && mem_resp_read_ready) begin
   320	        rd_pending_q <= 1'b0;
   321	        rd_valid_q <= 1'b0;
   322	      end
   323	    end
   324	  end
   325	
   326	  assign mem_req_write_ready = !wr_addr_valid_q;
   327	  assign mem_req_write_data_ready = wr_addr_valid_q & !wr_resp_valid_q;
   328	  assign mem_resp_write_valid = wr_resp_valid_q;
   329	  assign mem_resp_write_is_atomic = 1'b0;
   330	  assign mem_resp_write_error = 2'b00;
   331	  assign mem_resp_write_id = wr_id_q;
   332	
   333	  always @(posedge clk or negedge rst_n) begin
   334	    if (!rst_n) begin
   335	      wr_addr_valid_q <= 1'b0;
   336	      wr_resp_valid_q <= 1'b0;
   337	      wr_addr_q <= 32'h0;
   338	      wr_id_q <= 4'h0;
   339	    end else begin
   340	      if (!wr_addr_valid_q && mem_req_write_valid && mem_req_write_ready) begin
   341	        wr_addr_valid_q <= 1'b1;
   342	        wr_addr_q <= mem_req_write_addr;
   343	        wr_id_q <= mem_req_write_id;
   344	      end
   345	
   346	      if (wr_addr_valid_q && mem_req_write_data_valid && mem_req_write_data_ready) begin
   347	        write_mem_beat(wr_addr_q, mem_req_write_data, mem_req_write_be);
   348	        if (mem_req_write_last) begin
   349	          wr_addr_valid_q <= 1'b0;
   350	          wr_resp_valid_q <= 1'b1;
   351	        end
   352	      end
   353	
   354	      if (wr_resp_valid_q && mem_resp_write_ready) begin
   355	        wr_resp_valid_q <= 1'b0;
   356	      end
   357	    end
   358	  end
   359	
   360	  always @(posedge clk or negedge rst_n) begin
```

## Open Interface Decision

Need determine from the extracted D-Cache-only top whether the shared memory model already has a clean request/response interface.
If it does not, I3 should create the I-Cache memory adapter with a small generic read-line interface for the future `l1_mem_arbiter.sv`, then I4 will define the arbiter around that interface.

## I3 Implementation - cva6_icache_mem_adapter

- Time: Wed May 27 08:43:24 AM UTC 2026
- RTL file: `/media/sf_source_env/cv32_full_l1_cache/cv32e40p-master/rtl/l1_cache/work/rtl/cva6_icache_mem_adapter.sv`

### I-Cache request fields used

- `icache_mem_data_i.paddr[31:0]` -> `l1_read_req_addr_o`
- `icache_mem_data_i.nc` -> `l1_read_req_nc_o`
- `icache_mem_data_i.way` -> `l1_read_req_way_o`
- `icache_mem_data_i.tid` -> `l1_read_req_tid_o` and returned as `icache_mem_rtrn_o.tid`

### Request/response protocol

- `icache_mem_data_ack_o` asserts only when the future L1 arbiter accepts the read-line request.
- One outstanding I-Cache refill is supported.
- Request fields are held stable while waiting for `l1_read_req_ready_i`.
- Response is returned as `ICACHE_IFILL_ACK`.

### Cache line mapping

- `l1_read_rsp_data_i` maps directly to `icache_mem_rtrn_o.data`.
- Width is `CVA6Cfg.ICACHE_LINE_WIDTH`, expected 128-bit from current CVA6 config.
- `icache_mem_rtrn_o.user` is tied to zero.
- Invalidation fields are tied to zero because this adapter only generates refill responses.

### Notes for PHASE I4

- `l1_mem_arbiter.sv` should expose this adapter's read-line valid/ready/data interface.
- The D-Cache read/write interfaces in the old top are still embedded in `cv32e40p_l1_dcache_top.sv`; I4 should extract equivalent logic into a shared arbiter/memory path without modifying the old top.
