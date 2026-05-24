import re
with open('/home/guy/Sagi/riscv_processor/tb/uvm/tb_uvm_top.sv', 'r') as f:
    content = f.read()

new_content = re.sub(r"if \(dut\.bound_if\.write_data_mem\[0\] == 1'b1\) begin.*?\$finish;\s*end", 
'''$display("TOHOST WRITE: %0h", dut.bound_if.write_data_mem);
            if (dut.bound_if.write_data_mem == 1) begin
                $display("TEST PASSED");
            end else begin
                $display("TEST FAILED with code %0d", dut.bound_if.write_data_mem);
            end
            $finish;''', content, flags=re.DOTALL)

with open('/home/guy/Sagi/riscv_processor/tb/uvm/tb_uvm_top.sv', 'w') as f:
    f.write(new_content)
