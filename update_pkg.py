import sys
file_path = 'tb/uvm/riscv_uvm_pkg.sv'
try:
    with open(file_path, 'r') as f:
        content = f.read()
    
    lines = content.splitlines(True)
    new_lines = []
    for line in lines:
        new_lines.append(line)
        if '`include "riscv_ext_seq.sv"' in line and 'riscv_fp_seq.sv' not in content:
            new_lines.append('  `include "riscv_fp_seq.sv"\n')
        if '`include "riscv_ext_test.sv"' in line and 'riscv_fp_test.sv' not in content:
            new_lines.append('  `include "riscv_fp_test.sv"\n')
            
    with open(file_path, 'w') as f:
        f.writelines(new_lines)
except Exception as e:
    print(e)
    sys.exit(1)
