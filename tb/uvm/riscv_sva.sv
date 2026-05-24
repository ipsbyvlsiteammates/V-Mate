module riscv_sva (
    input logic clk,
    input logic rst_n,
    input logic [31:0] pc_out,
    input logic [31:0] instruction,
    input logic exception_mem,
    input logic amo_en_mem,
    input logic reservation_valid,
    input logic mem_read_mem,
    input logic mem_write_mem,
    input logic fp_we_mem,
    input logic reg_write_mem
);
    property p_no_x_on_pc;
        @(posedge clk) disable iff (!rst_n)
        (!$isunknown(pc_out));
    endproperty
    assert property (p_no_x_on_pc) else $error("PC contains X");

    // Deadlock detection: PC should not be stable for more than 1000 cycles
    property p_deadlock;
        @(posedge clk) disable iff (!rst_n)
        $stable(pc_out) [*1000] |-> 0;
    endproperty
    assert property (p_deadlock) else $error("Deadlock detected: PC %0h has not changed for 1000 cycles", pc_out);

    // AMO operations should assert memory read or write
    property p_amo_mem_access;
        @(posedge clk) disable iff (!rst_n)
        amo_en_mem |-> (mem_read_mem || mem_write_mem);
    endproperty
    assert property (p_amo_mem_access) else $error("AMO operation without memory access");

    // Exception should not have X
    property p_no_x_on_exception;
        @(posedge clk) disable iff (!rst_n)
        (!$isunknown(exception_mem));
    endproperty
    assert property (p_no_x_on_exception) else $error("Exception signal contains X");

    // Write enable signals should not be X
    property p_no_x_on_we;
        @(posedge clk) disable iff (!rst_n)
        (!$isunknown(reg_write_mem) && !$isunknown(fp_we_mem));
    endproperty
    assert property (p_no_x_on_we) else $error("Write enable signals contain X");

    // Liveness: reservation_valid should eventually be cleared
    property p_reservation_liveness;
        @(posedge clk) disable iff (!rst_n)
        reservation_valid |-> s_eventually (!reservation_valid);
    endproperty
    assert property (p_reservation_liveness) else $error("Reservation valid asserted indefinitely (Liveness issue)");

    // Exception should prevent register writes
    property p_exception_no_write;
        @(posedge clk) disable iff (!rst_n)
        exception_mem |-> (!reg_write_mem && !fp_we_mem);
    endproperty
    assert property (p_exception_no_write) else $error("Register write enabled during exception");

endmodule
