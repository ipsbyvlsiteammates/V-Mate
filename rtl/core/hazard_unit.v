module hazard_unit (
    input wire [4:0] rs1_addr_id,
    input wire [4:0] rs2_addr_id,
    input wire [4:0] rs3_addr_id,
    input wire [4:0] rd_addr_ex,
    input wire mem_read_ex,
    input wire fp_mem_read_ex,
    input wire pc_sel_ex,
    input wire exception_mem,
    input wire mret_exec_mem,
    output reg stall_pc,
    output reg stall_if_id,
    output reg flush_if_id,
    output reg flush_id_ex,
    output reg flush_ex_mem,
    output reg flush_mem_wb
);
    wire int_load_use = mem_read_ex && (rd_addr_ex != 0) && ((rd_addr_ex == rs1_addr_id) || (rd_addr_ex == rs2_addr_id));
    wire fp_load_use = fp_mem_read_ex && ((rd_addr_ex == rs1_addr_id) || (rd_addr_ex == rs2_addr_id) || (rd_addr_ex == rs3_addr_id));
    wire load_use_hazard = int_load_use || fp_load_use;
    wire control_hazard = pc_sel_ex;
    wire exception_hazard = exception_mem || mret_exec_mem;

    always @(*) begin
        stall_pc = 1'b0;
        stall_if_id = 1'b0;
        flush_if_id = 1'b0;
        flush_id_ex = 1'b0;
        flush_ex_mem = 1'b0;
        flush_mem_wb = 1'b0;

        if (exception_hazard) begin
            flush_if_id = 1'b1;
            flush_id_ex = 1'b1;
            flush_ex_mem = 1'b1;
            flush_mem_wb = 1'b1;
        end else if (control_hazard) begin
            flush_if_id = 1'b1;
            flush_id_ex = 1'b1;
        end else if (load_use_hazard) begin
            stall_pc = 1'b1;
            stall_if_id = 1'b1;
            flush_id_ex = 1'b1;
        end
    end
endmodule
