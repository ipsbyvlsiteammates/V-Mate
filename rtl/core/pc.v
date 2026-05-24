module pc #(
    parameter RESET_VECTOR = 32'h80000000
) (
    input wire clk,
    input wire rst_n,
    input wire stall,
    input wire pc_sel,
    input wire [31:0] pc_target,
    input wire exception,
    input wire [31:0] mtvec,
    input wire mret_exec,
    input wire [31:0] mepc,
    output reg [31:0] pc_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out <= RESET_VECTOR;
        end else if (exception) begin
            pc_out <= mtvec;
        end else if (mret_exec) begin
            pc_out <= mepc;
        end else if (!stall) begin
            if (pc_sel) begin
                pc_out <= pc_target;
            end else begin
                pc_out <= pc_out + 32'd4;
            end
        end
    end
endmodule
