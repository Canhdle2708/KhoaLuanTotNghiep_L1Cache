// Compile-only harness for the real CVA6 I-Cache DUT.
// This file is not an I-Cache replacement and must not be used as functional logic.

module cva6_icache_compile_harness
  import ariane_pkg::*;
  import wt_cache_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(
        cva6_config_pkg::cva6_cfg
    )
) ();

  typedef struct packed {
    logic [CVA6Cfg.XLEN-1:0]  cause;
    logic [CVA6Cfg.XLEN-1:0]  tval;
    logic [CVA6Cfg.GPLEN-1:0] tval2;
    logic [31:0]              tinst;
    logic                     gva;
    logic                     valid;
  } exception_t;

  typedef struct packed {
    logic                    fetch_valid;
    logic [CVA6Cfg.PLEN-1:0] fetch_paddr;
    exception_t              fetch_exception;
  } icache_areq_t;

  typedef struct packed {
    logic                    fetch_req;
    logic [CVA6Cfg.VLEN-1:0] fetch_vaddr;
  } icache_arsp_t;

  typedef struct packed {
    logic                    req;
    logic                    kill_s1;
    logic                    kill_s2;
    logic                    spec;
    logic [CVA6Cfg.VLEN-1:0] vaddr;
  } icache_dreq_t;

  typedef struct packed {
    logic                                ready;
    logic                                valid;
    logic [CVA6Cfg.FETCH_WIDTH-1:0]      data;
    logic [CVA6Cfg.FETCH_USER_WIDTH-1:0] user;
    logic [CVA6Cfg.VLEN-1:0]             vaddr;
    exception_t                          ex;
  } icache_drsp_t;

  typedef struct packed {
    logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] way;
    logic [CVA6Cfg.PLEN-1:0]                   paddr;
    logic                                      nc;
    logic [CVA6Cfg.MEM_TID_WIDTH-1:0]          tid;
  } icache_req_t;

  typedef struct packed {
    wt_cache_pkg::icache_in_t                  rtype;
    logic [CVA6Cfg.ICACHE_LINE_WIDTH-1:0]      data;
    logic [CVA6Cfg.ICACHE_USER_LINE_WIDTH-1:0] user;
    struct packed {
      logic                                      vld;
      logic                                      all;
      logic [CVA6Cfg.ICACHE_INDEX_WIDTH-1:0]     idx;
      logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] way;
    } inv;
    logic [CVA6Cfg.MEM_TID_WIDTH-1:0]          tid;
  } icache_rtrn_t;

  logic clk_i;
  logic rst_ni;
  logic flush_i;
  logic en_i;
  logic miss_o;

  icache_areq_t areq_i;
  icache_arsp_t areq_o;
  icache_dreq_t dreq_i;
  icache_drsp_t dreq_o;

  logic         mem_rtrn_vld_i;
  icache_rtrn_t mem_rtrn_i;
  logic         mem_data_req_o;
  logic         mem_data_ack_i;
  icache_req_t  mem_data_o;

  always_comb begin
    clk_i          = 1'b0;
    rst_ni         = 1'b1;
    flush_i        = 1'b0;
    en_i           = 1'b1;
    areq_i         = '0;
    dreq_i         = '0;
    mem_rtrn_vld_i = 1'b0;
    mem_rtrn_i     = '0;
    mem_data_ack_i = 1'b0;
  end

  cva6_icache #(
      .CVA6Cfg       (CVA6Cfg),
      .icache_areq_t (icache_areq_t),
      .icache_arsp_t (icache_arsp_t),
      .icache_dreq_t (icache_dreq_t),
      .icache_drsp_t (icache_drsp_t),
      .icache_req_t  (icache_req_t),
      .icache_rtrn_t (icache_rtrn_t),
      .RdTxId        ('0)
  ) i_cva6_icache (
      .clk_i          (clk_i),
      .rst_ni         (rst_ni),
      .flush_i        (flush_i),
      .en_i           (en_i),
      .miss_o         (miss_o),
      .areq_i         (areq_i),
      .areq_o         (areq_o),
      .dreq_i         (dreq_i),
      .dreq_o         (dreq_o),
      .mem_rtrn_vld_i (mem_rtrn_vld_i),
      .mem_rtrn_i     (mem_rtrn_i),
      .mem_data_req_o (mem_data_req_o),
      .mem_data_ack_i (mem_data_ack_i),
      .mem_data_o     (mem_data_o)
  );

endmodule
