import os
import re

sb_path = '../tb/uvm/riscv_sb.sv'
cu_path = '../rtl/core/control_unit.v'

if os.path.exists(sb_path):
    with open(sb_path, 'r') as f:
        sb_content = f.read()

    sb_content = sb_content.replace('    logic is_illegal;\n', '')
    sb_content = sb_content.replace('    logic [4:0] exp_fflags;\n', '    logic [4:0] exp_fflags;\n    logic is_illegal;\n')

    pattern = r"if\s*\(\s*opcode\s*==\s*7'b0101111\s*\)\s*begin\s*if\s*\(\s*funct3\s*!=\s*3'b010\s*&&\s*funct3\s*!=\s*3'b011\s*\)\s*begin\s*is_illegal\s*=\s*1'b1;\s*end\s*end"
    replacement = '''if (opcode == 7'b0101111) begin
            if ((funct3 != 3'b010 && funct3 != 3'b011) || 
                (funct7[6:2] != 5'd0 && funct7[6:2] != 5'd1 && funct7[6:2] != 5'd2 && 
                 funct7[6:2] != 5'd3 && funct7[6:2] != 5'd4 && funct7[6:2] != 5'd12 && 
                 funct7[6:2] != 5'd8 && funct7[6:2] != 5'd16 && funct7[6:2] != 5'd20 && 
                 funct7[6:2] != 5'd24 && funct7[6:2] != 5'd28)) begin
                is_illegal = 1'b1;
            end
        end'''
    
    if re.search(pattern, sb_content, flags=re.DOTALL):
        sb_content = re.sub(pattern, replacement, sb_content, flags=re.DOTALL)
        print("Patched opcode == 7'b0101111 in riscv_sb.sv")
    else:
        print("Could not find opcode == 7'b0101111 in riscv_sb.sv")

    with open(sb_path, 'w') as f:
        f.write(sb_content)
else:
    print(f"{sb_path} not found")

if os.path.exists(cu_path):
    with open(cu_path, 'r') as f:
        cu_content = f.read()

    amo_pattern = r"(`OP_AMO:\s*begin)(.*?)(?=`OP_[A-Z_]+:\s*begin|endcase)"
    
    def amo_repl(m):
        block = m.group(2)
        block = re.sub(r"if\s*\(\s*funct3\s*!=\s*3'b010.*?end", "", block, flags=re.DOTALL)
        
        new_logic = '''
                if ((funct3 != 3'b010 && funct3 != 3'b011) || 
                    (funct7[6:2] != 5'd0 && funct7[6:2] != 5'd1 && funct7[6:2] != 5'd2 && 
                     funct7[6:2] != 5'd3 && funct7[6:2] != 5'd4 && funct7[6:2] != 5'd12 && 
                     funct7[6:2] != 5'd8 && funct7[6:2] != 5'd16 && funct7[6:2] != 5'd20 && 
                     funct7[6:2] != 5'd24 && funct7[6:2] != 5'd28)) begin
                    exception = 1'b1;
                    exception_cause = 4'd2;
                end
'''
        return m.group(1) + block + new_logic

    if re.search(amo_pattern, cu_content, flags=re.DOTALL):
        cu_content = re.sub(amo_pattern, amo_repl, cu_content, flags=re.DOTALL)
        print("Patched OP_AMO in control_unit.v")
    else:
        print("Could not find OP_AMO block in control_unit.v")

    with open(cu_path, 'w') as f:
        f.write(cu_content)
else:
    print(f"{cu_path} not found")
