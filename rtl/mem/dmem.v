`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////
// Module:  dmem
// Description: Data Memory for RISC-V RV32I Processor
//              4KB byte-addressable memory with byte/halfword/word access
//              Little-endian byte ordering
//              Synchronous write, combinational (asynchronous) read
//              Supports 'A' Extension (Atomic Instructions)
//////////////////////////////////////////////////////////////////////////////

module dmem #(
    parameter EXTENSION_D = 1,
    parameter DEPTH = 131072,  // Number of words (memory size = DEPTH * 4 bytes)
    parameter EXTENSION_A = 1
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        mem_write,
    input  wire        mem_read,
    input  wire [31:0] addr,
    input  wire [(EXTENSION_D ? 64 : 32)-1:0] write_data,
    input  wire [2:0]  mem_size,
    input  wire        amo_en,
    input  wire [4:0]  amo_op,
    output wire [(EXTENSION_D ? 64 : 32)-1:0] read_data
);

    localparam integer ADDR_BITS = 19;  // log2(DEPTH*4) = log2(4096) = 12

    // Byte-addressable memory array
    reg [7:0] mem [0:DEPTH*4-1];

    // Internal masked address
    wire [ADDR_BITS-1:0] masked_addr;
    assign masked_addr = addr[ADDR_BITS-1:0];

    // Combinational read logic
    reg [(EXTENSION_D ? 64 : 32)-1:0] read_data_reg;

    always @(*) begin
        if (mem_read || (EXTENSION_A && amo_en)) begin
            case (mem_size)
                3'b000: // LB - sign extend byte
                    if (EXTENSION_D) read_data_reg = { {56{mem[masked_addr][7]}}, mem[masked_addr] }; else read_data_reg = { {24{mem[masked_addr][7]}}, mem[masked_addr] };
                3'b001: // LH - sign extend halfword
                    read_data_reg = {{16{mem[masked_addr + 1][7]}}, mem[masked_addr + 1], mem[masked_addr]};
                3'b010: // LW - full word
                    read_data_reg = {mem[masked_addr + 3], mem[masked_addr + 2], mem[masked_addr + 1], mem[masked_addr]};
                3'b100: // LBU - zero extend byte
                    read_data_reg = {24'h0, mem[masked_addr]};
                3'b101: // LHU - zero extend halfword
                    read_data_reg = {16'h0, mem[masked_addr + 1], mem[masked_addr]};
                3'b011: // LD
                    if (EXTENSION_D) read_data_reg = { mem[masked_addr+7], mem[masked_addr+6], mem[masked_addr+5], mem[masked_addr+4], mem[masked_addr+3], mem[masked_addr+2], mem[masked_addr+1], mem[masked_addr] }; else read_data_reg = 0;
                default:
                    read_data_reg = 0;
            endcase
        end else begin
            read_data_reg = 0;
        end
    end

    // LR/SC Reservation Logic
    reg [31:0] reservation_addr;
    reg        reservation_valid;

    wire sc_success = reservation_valid && (reservation_addr == addr);

    assign read_data = (EXTENSION_A && amo_en && amo_op == 5'b00011) ? (sc_success ? 0 : 1) : read_data_reg;

    // AMO ALU Logic
    reg [(EXTENSION_D ? 64 : 32)-1:0] amo_write_data;
    always @(*) begin
        if (EXTENSION_A && amo_en) begin
            case (amo_op)
                5'b00000: amo_write_data = read_data_reg[31:0] + write_data[31:0]; // ADD
                5'b00001: amo_write_data = write_data[31:0]; // SWAP
                5'b00100: amo_write_data = read_data_reg[31:0] ^ write_data[31:0]; // XOR
                5'b01000: amo_write_data = read_data_reg[31:0] | write_data[31:0]; // OR
                5'b01100: amo_write_data = read_data_reg[31:0] & write_data[31:0]; // AND
                5'b10000: amo_write_data = ($signed(read_data_reg[31:0]) < $signed(write_data[31:0])) ? read_data_reg[31:0] : write_data[31:0]; // MIN
                5'b10100: amo_write_data = ($signed(read_data_reg[31:0]) > $signed(write_data[31:0])) ? read_data_reg[31:0] : write_data[31:0]; // MAX
                5'b11000: amo_write_data = (read_data_reg[31:0] < write_data[31:0]) ? read_data_reg[31:0] : write_data[31:0]; // MINU
                5'b11100: amo_write_data = (read_data_reg[31:0] > write_data[31:0]) ? read_data_reg[31:0] : write_data[31:0]; // MAXU
                default:  amo_write_data = write_data[31:0];
            endcase
        end else begin
            amo_write_data = write_data[31:0];
        end
    end

    wire cg_en = (!rst_n) | mem_write | (EXTENSION_A && amo_en);
    wire gated_clk;
    icg u_local_icg (
        .clk(clk),
        .en(cg_en),
        .gated_clk(gated_clk)
    );

    wire [(EXTENSION_D ? 64 : 32)-1:0] actual_write_data = (EXTENSION_A && amo_en) ? amo_write_data : write_data;
    
    wire execute_write = (EXTENSION_A && amo_en) ? 
                         ((amo_op == 5'b00010) ? 1'b0 : 
                          (amo_op == 5'b00011) ? sc_success : 1'b1) : 
                         mem_write;

    // Synchronous write logic
    always @(posedge gated_clk) begin
        if (!rst_n) begin
            reservation_valid <= 1'b0;
            reservation_addr  <= 32'h0;
        end else begin
            if (EXTENSION_A && amo_en) begin
                if (amo_op == 5'b00010) begin // LR
                    reservation_valid <= 1'b1;
                    reservation_addr  <= addr;
                end else if (amo_op == 5'b00011) begin // SC
                    reservation_valid <= 1'b0;
                end
            end

            if (execute_write) begin
                case (mem_size[1:0])
                    2'b00: // SB - store byte
                        mem[masked_addr] <= actual_write_data[7:0];
                    2'b01: // SH - store halfword
                        begin
                            mem[masked_addr]     <= actual_write_data[7:0];
                            mem[masked_addr + 1] <= actual_write_data[15:8];
                        end
                    2'b10: // SW - store word
                        begin
                            mem[masked_addr]     <= actual_write_data[7:0];
                            mem[masked_addr + 1] <= actual_write_data[15:8];
                            mem[masked_addr + 2] <= actual_write_data[23:16];
                            mem[masked_addr + 3] <= actual_write_data[31:24];
                        end
                2'b11: begin // SD
                    if (EXTENSION_D) begin
                        mem[masked_addr]   <= actual_write_data[7:0];
                        mem[masked_addr+1] <= actual_write_data[15:8];
                        mem[masked_addr+2] <= actual_write_data[23:16];
                        mem[masked_addr+3] <= actual_write_data[31:24];
                        mem[masked_addr+4] <= actual_write_data[39:32];
                        mem[masked_addr+5] <= actual_write_data[47:40];
                        mem[masked_addr+6] <= actual_write_data[55:48];
                        mem[masked_addr+7] <= actual_write_data[63:56];
                    end
                end
                    default: ; // No write
                endcase
            end
        end
    end

endmodule
