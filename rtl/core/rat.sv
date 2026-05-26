module rat (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        ooo_en,

    // Read Interface
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rs3,
    input  logic        rs1_type, // 0=INT, 1=FP
    input  logic        rs2_type,
    input  logic        rs3_type,
    output logic [3:0]  rs1_rob_idx,
    output logic        rs1_in_rob,
    output logic [3:0]  rs2_rob_idx,
    output logic        rs2_in_rob,
    output logic [3:0]  rs3_rob_idx,
    output logic        rs3_in_rob,

    // Dispatch Interface
    input  logic        dispatch_en,
    input  logic [4:0]  dest_reg,
    input  logic        dest_type,
    input  logic [3:0]  rob_idx,

    // Commit Interface
    input  logic        commit_en,
    input  logic [4:0]  commit_dest_reg,
    input  logic        commit_dest_type,
    input  logic [3:0]  commit_rob_idx,

    // Flush Interface
    input  logic        flush
);

    // Clock Gating
    wire gated_clk;
    icg u_icg (
        .clk(clk),
        .en(ooo_en),
        .gated_clk(gated_clk)
    );

    // RAT Arrays
    logic [3:0] int_rat_idx   [0:31];
    logic       int_rat_valid [0:31];
    logic [3:0] fp_rat_idx    [0:31];
    logic       fp_rat_valid  [0:31];

    // Combinational Read Logic
    // Note: INT register 0 (x0) is hardwired to 0 and never in ROB
    assign rs1_rob_idx = rs1_type ? fp_rat_idx[rs1] : int_rat_idx[rs1];
    assign rs1_in_rob  = (rs1_type == 1'b0 && rs1 == 5'd0) ? 1'b0 : (rs1_type ? fp_rat_valid[rs1] : int_rat_valid[rs1]);

    assign rs2_rob_idx = rs2_type ? fp_rat_idx[rs2] : int_rat_idx[rs2];
    assign rs2_in_rob  = (rs2_type == 1'b0 && rs2 == 5'd0) ? 1'b0 : (rs2_type ? fp_rat_valid[rs2] : int_rat_valid[rs2]);

    assign rs3_rob_idx = rs3_type ? fp_rat_idx[rs3] : int_rat_idx[rs3];
    assign rs3_in_rob  = (rs3_type == 1'b0 && rs3 == 5'd0) ? 1'b0 : (rs3_type ? fp_rat_valid[rs3] : int_rat_valid[rs3]);

    // Synchronous Write/Update Logic
    integer i;
    always_ff @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                int_rat_idx[i]   <= 4'd0;
                int_rat_valid[i] <= 1'b0;
                fp_rat_idx[i]    <= 4'd0;
                fp_rat_valid[i]  <= 1'b0;
            end
        end else if (flush) begin
            for (i = 0; i < 32; i = i + 1) begin
                int_rat_valid[i] <= 1'b0;
                fp_rat_valid[i]  <= 1'b0;
            end
        end else begin
            // Commit Logic
            if (commit_en) begin
                if (commit_dest_type == 1'b0 && commit_dest_reg != 5'd0) begin
                    if (int_rat_idx[commit_dest_reg] == commit_rob_idx) begin
                        int_rat_valid[commit_dest_reg] <= 1'b0;
                    end
                end else if (commit_dest_type == 1'b1) begin
                    if (fp_rat_idx[commit_dest_reg] == commit_rob_idx) begin
                        fp_rat_valid[commit_dest_reg] <= 1'b0;
                    end
                end
            end

            // Dispatch Logic (Placed after commit to ensure dispatch overrides commit on same-cycle collisions)
            if (dispatch_en) begin
                if (dest_type == 1'b0 && dest_reg != 5'd0) begin
                    int_rat_valid[dest_reg] <= 1'b1;
                    int_rat_idx[dest_reg]   <= rob_idx;
                end else if (dest_type == 1'b1) begin
                    fp_rat_valid[dest_reg] <= 1'b1;
                    fp_rat_idx[dest_reg]   <= rob_idx;
                end
            end
        end
    end

endmodule
