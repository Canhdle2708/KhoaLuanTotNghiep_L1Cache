/*
 *  Copyright 2026
 *
 *  SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
 */
/*
 *  Description   : HPDcache Victim Buffer skeleton
 */
module hpdcache_vbuf
//  {{{
import hpdcache_pkg::*;
//  Parameters
//  {{{
#(
    parameter hpdcache_cfg_t HPDcacheCfg = '0,

    parameter type hpdcache_nline_t = logic,
    parameter type hpdcache_tag_t = logic,
    parameter type hpdcache_set_t = logic,
    parameter type hpdcache_word_t = logic,
    parameter type hpdcache_way_vector_t = logic,

    parameter type hpdcache_access_data_t = logic,
    parameter type hpdcache_req_data_t = logic,

    parameter type hpdcache_mem_req_t = logic,
    parameter type hpdcache_mem_req_w_t = logic,
    parameter type hpdcache_mem_resp_w_t = logic,

    parameter int unsigned VBUF_DEPTH = 1
)
//  }}}

//  Ports
//  {{{
(
    input  logic                  clk_i,
    input  logic                  rst_ni,

    //      Global control signals
    //      {{{
    output logic                  empty_o,
    output logic                  full_o,
    output logic                  busy_o,
    input  logic                  drain_i,
    input  logic                  read_enable_i,
    input  logic                  wb_enable_i,
    input  logic                  safe_consume_i,
    output logic                  entry_ready_o,
    output hpdcache_nline_t       captured_nline_o,
    output logic                  safe_to_overwrite_o,
    output hpdcache_nline_t       safe_nline_o,
    output logic                  capture_pending_o,
    output logic                  writeback_done_o,
    output hpdcache_nline_t       writeback_done_nline_o,
    //      }}}

    //      CHECK interface
    //      {{{
    input  logic                  check_i,
    input  hpdcache_nline_t       check_nline_i,
    output logic                  check_hit_o,
    //      }}}

    //      FORWARD interface
    //      {{{
    input  logic                  fwd_req_i,
    input  hpdcache_nline_t       fwd_nline_i,
    input  hpdcache_word_t        fwd_word_i,
    output logic                  fwd_hit_o,
    output hpdcache_req_data_t    fwd_data_o,
    //      }}}

    //      ALLOC interface
    //      {{{
    input  logic                  alloc_i,
    output logic                  alloc_ready_o,
    input  hpdcache_nline_t       alloc_nline_i,
    input  hpdcache_tag_t         alloc_tag_i,
    input  hpdcache_set_t         alloc_set_i,
    input  hpdcache_way_vector_t  alloc_way_i,
    //      }}}

    //      CACHE DATA interface
    //      {{{
    output logic                  data_read_o,
    output hpdcache_set_t         data_read_set_o,
    output hpdcache_word_t        data_read_word_o,
    output hpdcache_way_vector_t  data_read_way_o,
    input  logic                  data_read_ready_i,
    input  logic                  data_capture_i,
    input  hpdcache_access_data_t data_read_data_i,
    output logic                  capture_done_o,
    //      }}}

    //      MEMORY interface
    //      {{{
    input  logic                  mem_req_write_ready_i,
    output logic                  mem_req_write_valid_o,
    output hpdcache_mem_req_t     mem_req_write_o,

    input  logic                  mem_req_write_data_ready_i,
    output logic                  mem_req_write_data_valid_o,
    output hpdcache_mem_req_w_t   mem_req_write_data_o,

    output logic                  mem_resp_write_ready_o,
    input  logic                  mem_resp_write_valid_i,
    input  hpdcache_mem_resp_w_t  mem_resp_write_i
    //      }}}
);
//  }}}

    //  Definition of constants and types
    //  {{{
    localparam int unsigned VbufLineBeats = HPDcacheCfg.u.clWords / HPDcacheCfg.u.accessWords;
    localparam int unsigned VbufBeatCntWidth =
        (VbufLineBeats > 1) ? $clog2(VbufLineBeats) : 1;
    localparam hpdcache_uint32 VbufMemReqFlits =
        HPDcacheCfg.u.memDataWidth < HPDcacheCfg.clWidth ?
        (HPDcacheCfg.clWidth / HPDcacheCfg.u.memDataWidth) - 1 : 0;
    localparam int unsigned VbufMemAddrPadWidth = HPDcacheCfg.u.memAddrWidth - HPDcacheCfg.u.paWidth;

    typedef logic [VbufBeatCntWidth-1:0] vbuf_beat_cnt_t;

    typedef enum logic [2:0] {
        VBUF_IDLE,
        VBUF_CAPTURE,
        VBUF_READY,
        VBUF_MEM_REQ,
        VBUF_MEM_DATA,
        VBUF_WAIT_RESP
    } vbuf_state_e;

    vbuf_state_e state_q, state_d;

    logic                                valid_q;
    logic                                safe_valid_q;
    hpdcache_nline_t                     nline_q;
    hpdcache_nline_t                     safe_nline_q;
    hpdcache_tag_t                       tag_q;
    hpdcache_set_t                       set_q;
    hpdcache_way_vector_t                way_q;
    hpdcache_access_data_t               victim_line_q [VbufLineBeats-1:0];
    vbuf_beat_cnt_t                      beat_count_q;
    vbuf_beat_cnt_t                      wb_beat_count_q, wb_beat_count_d;
    logic                                data_capture_q;
    logic                                data_read_accept;
    logic                                data_read_accept_q;
    logic                                capture_fire;
    logic                                capture_done_q;
    logic                                capture_last_beat;
    logic                                drain_fire;
    logic                                wb_last_beat;
    logic                                wb_data_fire;
    logic                                wb_done_fire;
    logic                                fwd_entry_valid;
    logic                                _unused_mem_resp_write;
    logic                                _unused_tag;
    //  }}}

    if (VBUF_DEPTH != 1) begin : gen_vbuf_depth_check
        initial begin
            $error("hpdcache_vbuf currently implements a single-entry VBUF only");
        end
    end

    //  Capture and optional write-back FSM
    //  {{{
    always_comb begin
        state_d = state_q;

        unique case (state_q)
            VBUF_IDLE: begin
                if (alloc_i) begin
                    state_d = VBUF_CAPTURE;
                end
            end

            VBUF_CAPTURE: begin
                if (capture_last_beat) begin
                    state_d = VBUF_READY;
                end
            end

            VBUF_READY: begin
                if (drain_fire) begin
                    state_d = VBUF_IDLE;
                end else if (wb_enable_i && valid_q) begin
                    state_d = VBUF_MEM_REQ;
                end
            end

            VBUF_MEM_REQ: begin
                if (mem_req_write_ready_i) begin
                    state_d = VBUF_MEM_DATA;
                end
            end

            VBUF_MEM_DATA: begin
                if (wb_data_fire && wb_last_beat) begin
                    state_d = VBUF_WAIT_RESP;
                end
            end

            VBUF_WAIT_RESP: begin
                if (mem_resp_write_valid_i) begin
                    state_d = VBUF_IDLE;
                end
            end

            default: begin
                state_d = VBUF_IDLE;
            end
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin : vbuf_state_ff
        if (!rst_ni) begin
            state_q <= VBUF_IDLE;
        end else begin
            state_q <= state_d;
        end
    end

    assign capture_last_beat =
        (state_q == VBUF_CAPTURE) &
        capture_fire &
        (beat_count_q == vbuf_beat_cnt_t'(VbufLineBeats - 1));
    assign data_read_accept = data_read_o & data_read_ready_i;
    //  Shadow mode follows the flush stream; owner mode follows only accepted VBUF reads.
    assign capture_fire = read_enable_i ? data_read_accept_q : data_capture_q;
    assign drain_fire = drain_i & valid_q & (state_q == VBUF_READY);
    assign wb_last_beat =
        (wb_beat_count_q == vbuf_beat_cnt_t'(VbufLineBeats - 1));
    assign wb_data_fire =
        (state_q == VBUF_MEM_DATA) & mem_req_write_data_ready_i;
    assign wb_done_fire =
        (state_q == VBUF_WAIT_RESP) & mem_resp_write_valid_i;
    assign _unused_mem_resp_write = 1'b0 && (|mem_resp_write_i);
    assign _unused_tag = 1'b0 && (|tag_q);

    always_comb begin : vbuf_wb_beat_count_comb
        wb_beat_count_d = wb_beat_count_q;

        if ((state_q == VBUF_READY) && wb_enable_i && valid_q) begin
            wb_beat_count_d = '0;
        end else if (wb_data_fire) begin
            if (wb_last_beat) begin
                wb_beat_count_d = '0;
            end else begin
                wb_beat_count_d = wb_beat_count_q + vbuf_beat_cnt_t'(1);
            end
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin : vbuf_capture_ff
        if (!rst_ni) begin
            valid_q        <= 1'b0;
            safe_valid_q   <= 1'b0;
            beat_count_q   <= '0;
            wb_beat_count_q <= '0;
            data_capture_q <= 1'b0;
            data_read_accept_q <= 1'b0;
            capture_done_q <= 1'b0;
        end else begin
            data_capture_q <= data_capture_i;
            data_read_accept_q <= data_read_accept;
            capture_done_q <= 1'b0;
            wb_beat_count_q <= wb_beat_count_d;

            if (alloc_i && alloc_ready_o) begin
                valid_q      <= 1'b1;
                beat_count_q <= '0;
                nline_q      <= alloc_nline_i;
                tag_q        <= alloc_tag_i;
                set_q        <= alloc_set_i;
                way_q        <= alloc_way_i;
            end

            if ((state_q == VBUF_CAPTURE) && capture_fire) begin
                victim_line_q[beat_count_q] <= data_read_data_i;
                if (capture_last_beat) begin
                    capture_done_q <= 1'b1;
                    safe_valid_q   <= 1'b1;
                    safe_nline_q   <= nline_q;
                end else begin
                    beat_count_q <= beat_count_q + vbuf_beat_cnt_t'(1);
                end
            end

            if (safe_consume_i) begin
                safe_valid_q <= 1'b0;
            end

            if (drain_fire) begin
                valid_q        <= 1'b0;
                beat_count_q   <= '0;
                wb_beat_count_q <= '0;
                capture_done_q <= 1'b0;
                data_read_accept_q <= 1'b0;
            end

            if (wb_done_fire) begin
                valid_q         <= 1'b0;
                wb_beat_count_q <= '0;
                data_read_accept_q <= 1'b0;
            end
        end
    end
    //  }}}

    //  Shadow capture outputs and optional memory write-back interface
    //  {{{
    assign empty_o                    = ~valid_q;
    assign full_o                     = valid_q;
    assign busy_o                     = (state_q == VBUF_CAPTURE) |
                                        (state_q == VBUF_MEM_REQ) |
                                        (state_q == VBUF_MEM_DATA) |
                                        (state_q == VBUF_WAIT_RESP);
    assign entry_ready_o              = valid_q & (state_q == VBUF_READY);
    assign alloc_ready_o              = (state_q == VBUF_IDLE);
    assign captured_nline_o           = nline_q;
    assign safe_to_overwrite_o        = safe_valid_q;
    assign safe_nline_o               = safe_nline_q;
    assign capture_pending_o          = read_enable_i &
                                        valid_q &
                                        (state_q == VBUF_CAPTURE);
    assign writeback_done_o           = wb_done_fire;
    assign writeback_done_nline_o     = nline_q;
    assign check_hit_o                = check_i &
                                        valid_q &
                                        ~wb_done_fire &
                                        (check_nline_i == nline_q);
    assign fwd_entry_valid            = valid_q &
                                        (state_q != VBUF_IDLE) &
                                        (state_q != VBUF_CAPTURE);
    assign fwd_hit_o                  = fwd_req_i &
                                        fwd_entry_valid &
                                        ~wb_done_fire &
                                        (fwd_nline_i == nline_q);

    always_comb begin : fwd_data_comb
        int unsigned fwd_word_idx;
        int unsigned fwd_cl_word_idx;
        int unsigned fwd_beat_idx;
        int unsigned fwd_word_in_beat_idx;

        fwd_data_o = '0;
        fwd_word_idx = hpdcache_uint'(fwd_word_i);
        fwd_cl_word_idx = '0;
        fwd_beat_idx = '0;
        fwd_word_in_beat_idx = '0;

        for (int unsigned i = 0; i < HPDcacheCfg.u.reqWords; i++) begin
            fwd_cl_word_idx = fwd_word_idx + i;
            if (fwd_cl_word_idx < HPDcacheCfg.u.clWords) begin
                fwd_beat_idx = fwd_cl_word_idx / HPDcacheCfg.u.accessWords;
                fwd_word_in_beat_idx = fwd_cl_word_idx % HPDcacheCfg.u.accessWords;
                fwd_data_o[i] = victim_line_q[fwd_beat_idx][fwd_word_in_beat_idx];
            end
        end
    end

    assign data_read_o                = read_enable_i &
                                        valid_q &
                                        (state_q == VBUF_CAPTURE) &
                                        ~data_read_accept_q;
    assign data_read_set_o            = read_enable_i ? set_q : '0;
    assign data_read_word_o           = read_enable_i ?
                                        hpdcache_word_t'(beat_count_q * HPDcacheCfg.u.accessWords) :
                                        '0;
    assign data_read_way_o            = read_enable_i ? way_q : '0;
    assign capture_done_o             = capture_done_q;
    assign mem_req_write_valid_o      = (state_q == VBUF_MEM_REQ);
    assign mem_req_write_o            = '{
        mem_req_addr: {{VbufMemAddrPadWidth{1'b0}},
                       nline_q,
                       {HPDcacheCfg.clOffsetWidth{1'b0}}},
        mem_req_len: hpdcache_mem_len_t'(VbufMemReqFlits),
        mem_req_size: get_hpdcache_mem_size(HPDcacheCfg.u.memDataWidth/8),
        mem_req_id: '0,
        mem_req_command: HPDCACHE_MEM_WRITE,
        mem_req_atomic: HPDCACHE_MEM_ATOMIC_ADD,
        mem_req_cacheable: 1'b1
    };
    assign mem_req_write_data_valid_o = (state_q == VBUF_MEM_DATA);
    assign mem_req_write_data_o       = '{
        mem_req_w_data: victim_line_q[wb_beat_count_q],
        mem_req_w_be: '1,
        mem_req_w_last: wb_last_beat
    };
    assign mem_resp_write_ready_o     = (state_q == VBUF_WAIT_RESP);
    //  }}}

endmodule
//  }}}
