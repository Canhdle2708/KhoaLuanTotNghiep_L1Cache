// Lint-only blackbox for vendor SRAM model.
// This is not an I-Cache replacement. The real tc_sram.sv remains copied in rtl/vendor/tech_cells_generic.

module tc_sram #(
  parameter int unsigned NumWords  = 32'd1024,
  parameter int unsigned DataWidth = 32'd128,
  parameter int unsigned ByteWidth = 32'd8,
  parameter int unsigned NumPorts  = 32'd2,
  parameter int unsigned Latency   = 32'd1,
  parameter              SimInit   = "none",
  parameter bit          PrintSimCfg = 1'b0,
  parameter              ImplKey   = "none",
  parameter int unsigned AddrWidth = (NumWords > 32'd1) ? $clog2(NumWords) : 32'd1,
  parameter int unsigned BeWidth   = (DataWidth + ByteWidth - 32'd1) / ByteWidth,
  parameter type         addr_t    = logic [AddrWidth-1:0],
  parameter type         data_t    = logic [DataWidth-1:0],
  parameter type         be_t      = logic [BeWidth-1:0]
) (
  input  logic                 clk_i,
  input  logic                 rst_ni,
  input  logic  [NumPorts-1:0] req_i,
  input  logic  [NumPorts-1:0] we_i,
  input  addr_t [NumPorts-1:0] addr_i,
  input  data_t [NumPorts-1:0] wdata_i,
  input  be_t   [NumPorts-1:0] be_i,
  output data_t [NumPorts-1:0] rdata_o
);
  assign rdata_o = '0;
endmodule
