module pipe_if_id (
    input wire clk,
    input wire rst_n,
    input wire stall,
    input wire flush,
    input wire [31:0] pc_if,
    input wire [31:0] instruction_if,
    input wire [31:0] pc_plus4_if,
    output reg [31:0] pc_id,
    output reg [31:0] instruction_id,
    output reg [31:0] pc_plus4_id
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_id <= 32'b0;
            instruction_id <= 32'b0;
            pc_plus4_id <= 32'b0;
        end else if (flush) begin
            pc_id <= 32'b0;
            instruction_id <= 32'b0;
            pc_plus4_id <= 32'b0;
        end else if (!stall) begin
            pc_id <= pc_if;
            instruction_id <= instruction_if;
            pc_plus4_id <= pc_plus4_if;
        end
    end
endmodule