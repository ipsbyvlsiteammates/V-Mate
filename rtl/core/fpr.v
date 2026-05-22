`timescale 1ns/1ps

module fpr #(
    parameter EXTENSION_F = 0,
    parameter EXTENSION_D = 0
)(
    input  wire clk,
    input  wire rst_n,
    input  wire we,
    input  wire [4:0] rd_addr,
    input  wire [4:0] rs1_addr,
    input  wire [4:0] rs2_addr,
    input  wire [4:0] rs3_addr,
    input  wire [1:0] fmt,
    input  wire [(EXTENSION_D ? 64 : (EXTENSION_F ? 32 : 32))-1:0] write_data,
    output wire [(EXTENSION_D ? 64 : (EXTENSION_F ? 32 : 32))-1:0] rs1_data,
    output wire [(EXTENSION_D ? 64 : (EXTENSION_F ? 32 : 32))-1:0] rs2_data,
    output wire [(EXTENSION_D ? 64 : (EXTENSION_F ? 32 : 32))-1:0] rs3_data
);

    localparam FLEN = EXTENSION_D ? 64 : (EXTENSION_F ? 32 : 32);

    reg [FLEN-1:0] fpr_array [0:31];
    integer i;

    wire cg_en = (!rst_n) | we;
    wire gated_clk;

    icg u_local_icg (
        .clk(clk),
        .en(cg_en),
        .gated_clk(gated_clk)
    );

    always @(posedge gated_clk) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                fpr_array[i] <= {FLEN{1'b0}};
            end
        end else if (we) begin
            if (EXTENSION_D && fmt == 2'b00) begin
                fpr_array[rd_addr] <= {32'hFFFFFFFF, write_data[31:0]};
            end else begin
                fpr_array[rd_addr] <= write_data;
            end
        end
    end

    assign rs1_data = fpr_array[rs1_addr];
    assign rs2_data = fpr_array[rs2_addr];
    assign rs3_data = fpr_array[rs3_addr];

endmodule
