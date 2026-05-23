module forwarding_unit #(parameter FLEN = 64) (
    input wire [4:0] rs1_addr_ex,
    input wire [4:0] rs2_addr_ex,
    input wire [4:0] rs3_addr_ex,
    input wire [4:0] rd_addr_mem,
    input wire reg_write_mem,
    input wire fp_we_mem,
    input wire [4:0] rd_addr_wb,
    input wire reg_write_wb,
    input wire fp_we_wb,
    output reg [1:0] forward_a,
    output reg [1:0] forward_b,
    output reg [1:0] forward_fp_a,
    output reg [1:0] forward_fp_b,
    output reg [1:0] forward_fp_c
);
    // Integer Forwarding
    always @(*) begin
        forward_a = 2'b00;
        if (reg_write_mem && (rd_addr_mem != 0) && (rd_addr_mem == rs1_addr_ex)) begin
            forward_a = 2'b10;
        end else if (reg_write_wb && (rd_addr_wb != 0) && (rd_addr_wb == rs1_addr_ex)) begin
            forward_a = 2'b01;
        end
    end

    always @(*) begin
        forward_b = 2'b00;
        if (reg_write_mem && (rd_addr_mem != 0) && (rd_addr_mem == rs2_addr_ex)) begin
            forward_b = 2'b10;
        end else if (reg_write_wb && (rd_addr_wb != 0) && (rd_addr_wb == rs2_addr_ex)) begin
            forward_b = 2'b01;
        end
    end

    // FP Forwarding
    always @(*) begin
        forward_fp_a = 2'b00;
        if (fp_we_mem && (rd_addr_mem == rs1_addr_ex)) begin
            forward_fp_a = 2'b10;
        end else if (fp_we_wb && (rd_addr_wb == rs1_addr_ex)) begin
            forward_fp_a = 2'b01;
        end
    end

    always @(*) begin
        forward_fp_b = 2'b00;
        if (fp_we_mem && (rd_addr_mem == rs2_addr_ex)) begin
            forward_fp_b = 2'b10;
        end else if (fp_we_wb && (rd_addr_wb == rs2_addr_ex)) begin
            forward_fp_b = 2'b01;
        end
    end

    always @(*) begin
        forward_fp_c = 2'b00;
        if (fp_we_mem && (rd_addr_mem == rs3_addr_ex)) begin
            forward_fp_c = 2'b10;
        end else if (fp_we_wb && (rd_addr_wb == rs3_addr_ex)) begin
            forward_fp_c = 2'b01;
        end
    end
endmodule
