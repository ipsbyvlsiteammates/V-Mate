`timescale 1ns/1ps
module iq #(
    parameter IQ_DEPTH = 8
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        ooo_en,
    input  logic        flush,

    // Dispatch Interface
    input  logic        dispatch_en,
    input  logic [3:0]  rob_idx,
    input  logic [31:0] op_type,
    input  logic [4:0]  alu_op,
    input  logic [31:0] pc,
    input  logic [31:0] imm,
    input  logic        rs1_wait,
    input  logic [3:0]  rs1_rob_idx,
    input  logic [63:0] rs1_data,
    input  logic        rs2_wait,
    input  logic [3:0]  rs2_rob_idx,
    input  logic [63:0] rs2_data,
    input  logic        rs3_wait,
    input  logic [3:0]  rs3_rob_idx,
    input  logic [63:0] rs3_data,
    output logic        iq_full,
    
    input  logic [3:0]  rob_head,

    // Wakeup Interface (CDB)
    input  logic        cdb_en,
    input  logic [3:0]  cdb_rob_idx,
    input  logic [63:0] cdb_data,

    // Issue Interface
    output logic        issue_en,
    output logic [3:0]  issue_rob_idx,
    output logic [31:0] issue_op_type,
    output logic [4:0]  issue_alu_op,
    output logic [31:0] issue_pc,
    output logic [31:0] issue_imm,
    output logic [63:0] issue_rs1_data,
    output logic [63:0] issue_rs2_data,
    output logic [63:0] issue_rs3_data,
    input  logic        issue_ack
);

    logic gated_clk;
    icg u_icg (
        .clk(clk),
        .en(ooo_en),
        .gated_clk(gated_clk)
    );

    typedef struct packed {
        logic        valid;
        logic [3:0]  rob_idx;
        logic [31:0] op_type;
        logic [4:0]  alu_op;
        logic [31:0] pc;
        logic [31:0] imm;
        logic        rs1_wait;
        logic [3:0]  rs1_rob_idx;
        logic [63:0] rs1_data;
        logic        rs2_wait;
        logic [3:0]  rs2_rob_idx;
        logic [63:0] rs2_data;
        logic        rs3_wait;
        logic [3:0]  rs3_rob_idx;
        logic [63:0] rs3_data;
    } iq_entry_t;

    iq_entry_t [IQ_DEPTH-1:0] entries;
    logic [IQ_DEPTH-1:0] ready;
    logic [IQ_DEPTH-1:0] alloc_mask;
    logic [IQ_DEPTH-1:0] issue_mask;

    logic alloc_valid;
    logic [$clog2(IQ_DEPTH)-1:0] alloc_idx;

    always_comb begin
        alloc_valid = 1'b0;
        alloc_idx = '0;
        alloc_mask = '0;
        for (int i = 0; i < IQ_DEPTH; i++) begin
            if (!entries[i].valid) begin
                alloc_valid = 1'b1;
                alloc_idx = i[$clog2(IQ_DEPTH)-1:0];
                alloc_mask[i] = 1'b1;
                break;
            end
        end
    end

    assign iq_full = !alloc_valid;

    logic [IQ_DEPTH-1:0] rs1_match;
    logic [IQ_DEPTH-1:0] rs2_match;
    logic [IQ_DEPTH-1:0] rs3_match;

    always_comb begin
        for (int i = 0; i < IQ_DEPTH; i++) begin
            logic is_mem_op;
            logic mem_ready;
            
            rs1_match[i] = entries[i].valid && entries[i].rs1_wait && cdb_en && (entries[i].rs1_rob_idx == cdb_rob_idx);
            rs2_match[i] = entries[i].valid && entries[i].rs2_wait && cdb_en && (entries[i].rs2_rob_idx == cdb_rob_idx);
            rs3_match[i] = entries[i].valid && entries[i].rs3_wait && cdb_en && (entries[i].rs3_rob_idx == cdb_rob_idx);
            
            is_mem_op = (entries[i].op_type[6:0] == 7'b0000011) || 
                        (entries[i].op_type[6:0] == 7'b0100011) || 
                        (entries[i].op_type[6:0] == 7'b0101011) || 
                        (entries[i].op_type[6:0] == 7'b0000111) || 
                        (entries[i].op_type[6:0] == 7'b0100111);
            
            mem_ready = !is_mem_op || (entries[i].rob_idx == rob_head);

            ready[i] = entries[i].valid && 
                       (!entries[i].rs1_wait || rs1_match[i]) && 
                       (!entries[i].rs2_wait || rs2_match[i]) && 
                       (!entries[i].rs3_wait || rs3_match[i]) &&
                       mem_ready;
        end
    end

    logic sel_valid;
    logic [$clog2(IQ_DEPTH)-1:0] sel_idx;

    always_comb begin
        sel_valid = 1'b0;
        sel_idx = '0;
        issue_mask = '0;
        for (int i = 0; i < IQ_DEPTH; i++) begin
            if (ready[i]) begin
                sel_valid = 1'b1;
                sel_idx = i[$clog2(IQ_DEPTH)-1:0];
                issue_mask[i] = 1'b1;
                break;
            end
        end
    end

    assign issue_en       = sel_valid;
    assign issue_rob_idx  = entries[sel_idx].rob_idx;
    assign issue_op_type  = entries[sel_idx].op_type;
    assign issue_alu_op   = entries[sel_idx].alu_op;
    assign issue_pc       = entries[sel_idx].pc;
    assign issue_imm      = entries[sel_idx].imm;
    assign issue_rs1_data = rs1_match[sel_idx] ? cdb_data : entries[sel_idx].rs1_data;
    assign issue_rs2_data = rs2_match[sel_idx] ? cdb_data : entries[sel_idx].rs2_data;
    assign issue_rs3_data = rs3_match[sel_idx] ? cdb_data : entries[sel_idx].rs3_data;

    always_ff @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < IQ_DEPTH; i++) begin
                entries[i].valid <= 1'b0;
            end
        end else if (flush) begin
            for (int i = 0; i < IQ_DEPTH; i++) begin
                entries[i].valid <= 1'b0;
            end
        end else begin
            for (int i = 0; i < IQ_DEPTH; i++) begin
                if (issue_ack && issue_mask[i]) begin
                    entries[i].valid <= 1'b0;
                end
                
                if (dispatch_en && !iq_full && alloc_mask[i]) begin
                    entries[i].valid       <= 1'b1;
                    entries[i].rob_idx     <= rob_idx;
                    entries[i].op_type     <= op_type;
                    entries[i].alu_op      <= alu_op;
                    entries[i].pc          <= pc;
                    entries[i].imm         <= imm;
                    
                    if (rs1_wait && cdb_en && (rs1_rob_idx == cdb_rob_idx)) begin
                        entries[i].rs1_wait <= 1'b0;
                        entries[i].rs1_data <= cdb_data;
                    end else begin
                        entries[i].rs1_wait <= rs1_wait;
                        entries[i].rs1_data <= rs1_data;
                    end
                    entries[i].rs1_rob_idx <= rs1_rob_idx;

                    if (rs2_wait && cdb_en && (rs2_rob_idx == cdb_rob_idx)) begin
                        entries[i].rs2_wait <= 1'b0;
                        entries[i].rs2_data <= cdb_data;
                    end else begin
                        entries[i].rs2_wait <= rs2_wait;
                        entries[i].rs2_data <= rs2_data;
                    end
                    entries[i].rs2_rob_idx <= rs2_rob_idx;

                    if (rs3_wait && cdb_en && (rs3_rob_idx == cdb_rob_idx)) begin
                        entries[i].rs3_wait <= 1'b0;
                        entries[i].rs3_data <= cdb_data;
                    end else begin
                        entries[i].rs3_wait <= rs3_wait;
                        entries[i].rs3_data <= rs3_data;
                    end
                    entries[i].rs3_rob_idx <= rs3_rob_idx;
                end else if (entries[i].valid) begin
                    if (rs1_match[i]) begin
                        entries[i].rs1_wait <= 1'b0;
                        entries[i].rs1_data <= cdb_data;
                    end
                    if (rs2_match[i]) begin
                        entries[i].rs2_wait <= 1'b0;
                        entries[i].rs2_data <= cdb_data;
                    end
                    if (rs3_match[i]) begin
                        entries[i].rs3_wait <= 1'b0;
                        entries[i].rs3_data <= cdb_data;
                    end
                end
            end
        end
    end

endmodule