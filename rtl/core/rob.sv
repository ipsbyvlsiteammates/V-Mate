module rob #(
    parameter ROB_DEPTH = 16,
    parameter ROB_IDX_W = 4
)(
    input  logic clk,
    input  logic rst_n,
    input  logic ooo_en,

    // Dispatch Interface
    input  logic dispatch_en,
    input  logic [4:0] dest_reg,
    input  logic dest_type,
    input  logic [31:0] pc,
    input  logic is_store,
    input  logic is_branch,
    input  logic [31:0] instruction,
    input  logic dispatch_exception,
    input  logic [3:0] dispatch_exception_cause,
    output logic [ROB_IDX_W-1:0] rob_idx,
    output logic rob_full,
    
    output logic [ROB_IDX_W-1:0] rob_head,

    // Complete Interface
    input  logic complete_en,
    input  logic [ROB_IDX_W-1:0] complete_idx,
    output logic [31:0] complete_instruction,
    input  logic [63:0] result,
    input  logic exception,
    input  logic [3:0] exception_cause,
    input  logic branch_mispredicted,
    input  logic [31:0] branch_target,

    // Commit Interface
    output logic commit_en,
    output logic [4:0] commit_dest_reg,
    output logic commit_dest_type,
    output logic [63:0] commit_result,
    output logic [31:0] commit_pc,
    output logic commit_exception,
    output logic [3:0] commit_exception_cause,
    output logic commit_is_store,
    output logic commit_is_branch,
    output logic [31:0] commit_instruction,
    output logic commit_branch_mispredicted,
    output logic [31:0] commit_branch_target,
    output logic [ROB_IDX_W-1:0] commit_rob_idx,
    input  logic commit_ack,

    // Flush Interface
    input  logic flush
);

    logic gated_clk;
    icg u_icg (
        .clk(clk),
        .en(ooo_en),
        .gated_clk(gated_clk)
    );

    typedef struct packed {
        logic valid;
        logic completed;
        logic [4:0] dest_reg;
        logic dest_type;
        logic [31:0] pc;
        logic is_store;
        logic is_branch;
        logic [31:0] instruction;
        logic [63:0] result;
        logic exception;
        logic [3:0] exception_cause;
        logic branch_mispredicted;
        logic [31:0] branch_target;
    } rob_entry_t;

    rob_entry_t rob_data [ROB_DEPTH-1:0];

    logic [ROB_IDX_W-1:0] head_ptr;
    logic [ROB_IDX_W-1:0] tail_ptr;
    logic [ROB_IDX_W:0] count;

    assign rob_full = (count == ROB_DEPTH);
    assign rob_idx = tail_ptr;
    assign rob_head = head_ptr;

    assign commit_en = (count > 0) && rob_data[head_ptr].valid && rob_data[head_ptr].completed;
    assign commit_dest_reg = rob_data[head_ptr].dest_reg;
    assign commit_dest_type = rob_data[head_ptr].dest_type;
    assign commit_result = rob_data[head_ptr].result;
    assign commit_pc = rob_data[head_ptr].pc;
    assign commit_exception = rob_data[head_ptr].exception;
    assign commit_exception_cause = rob_data[head_ptr].exception_cause;
    assign commit_is_store = rob_data[head_ptr].is_store;
    assign commit_is_branch = rob_data[head_ptr].is_branch;
    assign commit_instruction = rob_data[head_ptr].instruction;
    assign commit_branch_mispredicted = rob_data[head_ptr].branch_mispredicted;
    assign commit_branch_target = rob_data[head_ptr].branch_target;
    assign commit_rob_idx = head_ptr;

    always_ff @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            head_ptr <= '0;
            tail_ptr <= '0;
            count <= '0;
            for (int i = 0; i < ROB_DEPTH; i++) begin
                rob_data[i] <= '0;
            end
        end else if (flush) begin
            head_ptr <= '0;
            tail_ptr <= '0;
            count <= '0;
            for (int i = 0; i < ROB_DEPTH; i++) begin
                rob_data[i].valid <= 1'b0;
                rob_data[i].completed <= 1'b0;
            end
        end else begin
            if (dispatch_en && !rob_full) begin
                rob_data[tail_ptr].valid <= 1'b1;
                rob_data[tail_ptr].completed <= dispatch_exception;
                rob_data[tail_ptr].dest_reg <= dest_reg;
                rob_data[tail_ptr].dest_type <= dest_type;
                rob_data[tail_ptr].pc <= pc;
                rob_data[tail_ptr].is_store <= is_store;
                rob_data[tail_ptr].is_branch <= is_branch;
                rob_data[tail_ptr].instruction <= instruction;
                rob_data[tail_ptr].exception <= dispatch_exception;
                rob_data[tail_ptr].exception_cause <= dispatch_exception_cause;
                tail_ptr <= tail_ptr + 1'b1;
            end

            if (complete_en && rob_data[complete_idx].valid) begin
                rob_data[complete_idx].completed <= 1'b1;
                rob_data[complete_idx].result <= result;
                rob_data[complete_idx].exception <= exception;
                rob_data[complete_idx].exception_cause <= exception_cause;
                rob_data[complete_idx].branch_mispredicted <= branch_mispredicted;
                rob_data[complete_idx].branch_target <= branch_target;
            end

            if (commit_en && commit_ack) begin
                rob_data[head_ptr].valid <= 1'b0;
                rob_data[head_ptr].completed <= 1'b0;
                head_ptr <= head_ptr + 1'b1;
            end

            if ((dispatch_en && !rob_full) && !(commit_en && commit_ack)) begin
                count <= count + 1'b1;
            end else if (!(dispatch_en && !rob_full) && (commit_en && commit_ack)) begin
                count <= count - 1'b1;
            end
        end
    end
    assign complete_instruction = rob_data[complete_idx].instruction;
endmodule
