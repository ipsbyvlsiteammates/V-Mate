
import sys, re

def step12():
    f1 = '/home/guy/Sagi/riscv_processor/scripts/run_arch_tests.py'
    with open(f1, 'r') as f: c1 = f.read()
    if 'tohost_addr = f"{int(line.split()[0], 16) & 0xFFFFFFFF:x}"' not in c1:
        c1 = c1.replace('tohost_addr = line.split()[0]', 'tohost_addr = f"{int(line.split()[0], 16) & 0xFFFFFFFF:x}"')
        with open(f1, 'w') as f: f.write(c1)

    f2 = '/home/guy/Sagi/riscv_processor/sim/tb_arch_test.sv'
    with open(f2, 'r') as f: c2 = f.read()
    if 'csr_w: %b | csr_op: %b' not in c2:
        pattern = r'\$fdisplay\(trace_file,\s*"PC: %h \| Instr: %h \| rs1_d: %h \| rs2_d: %h \| alu_res: %h \| mem_w: %b \| reg_w: %b",\s*(?:\\n)?\s*dut\.pc_out_w,\s*dut\.instruction_w,\s*dut\.rs1_data_w,\s*dut\.rs2_data_w,\s*dut\.alu_result_w,\s*dut\.mem_write_w,\s*dut\.reg_write_w\);'
        replacement = '$fdisplay(trace_file, "PC: %h | Instr: %h | rs1_d: %h | rs2_d: %h | alu_res: %h | mem_w: %b | reg_w: %b | csr_w: %b | csr_op: %b | csr_addr: %h | csr_wdata: %h | mscratch: %h", \\n                dut.pc_out_w, dut.instruction_w, dut.rs1_data_w, dut.rs2_data_w, dut.alu_result_w, dut.mem_write_w, dut.reg_write_w, dut.u_csr_file.csr_write, dut.u_csr_file.csr_op, dut.u_csr_file.csr_addr, dut.u_csr_file.csr_wdata, dut.u_csr_file.mscratch_reg);'
        c2_new = re.sub(pattern, lambda m: replacement, c2)
        if c2_new == c2:
            print("Regex replacement failed for tb_arch_test.sv")
            sys.exit(1)
        with open(f2, 'w') as f: f.write(c2_new)

def step6():
    with open('/home/guy/Sagi/riscv_processor/sim/full.bin', 'rb') as f: data = f.read()
    data = data.ljust(524288, b'\x00')[:524288]
    imem, dmem = data[:262144], data[262144:]
    with open('/home/guy/Sagi/riscv_processor/sim/imem.hex', 'w') as f:
        for i in range(0, len(imem), 4):
            w = imem[i:i+4]
            f.write(f"{w[3]:02x}{w[2]:02x}{w[1]:02x}{w[0]:02x}\n")
    with open('/home/guy/Sagi/riscv_processor/sim/dmem.hex', 'w') as f:
        for b in dmem: f.write(f"{b:02x}\n")

if sys.argv[1] == '12': step12()
elif sys.argv[1] == '6': step6()
