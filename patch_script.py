import sys
import re

def patch_fp_alu():
    with open('rtl/core/fp_alu.v', 'r') as f:
        content = f.read().replace('\r\n', '\n')
    
    replacements = [
        ('.raw_data(', '.in('),
        ('.unpacked_data(', '.out('),
        ('.fma_op(', '.op('),
        ('.result(fma_result)', '.out(fma_result)'),
        ('.result(divsqrt_result)', '.out(divsqrt_result)'),
        ('.result(cmp_result)', '.out(cmp_result)'),
        ('.result(sgnj_result)', '.out(sgnj_result)'),
        ('.result(cvt_result)', '.out(cvt_result)')
    ]
    
    for old, new in replacements:
        content = content.replace(old, new)
        
    with open('rtl/core/fp_alu.v', 'w') as f:
        f.write(content)

def patch_riscv_top():
    with open('rtl/core/riscv_top.v', 'r') as f:
        content = f.read().replace('\r\n', '\n')
        
    old_pattern = re.compile(r'fp_alu\s*#\(\s*\.EXTENSION_F\s*\(\s*EXTENSION_F\s*\),\s*\.EXTENSION_D\s*\(\s*EXTENSION_D\s*\)\s*\)\s*u_fp_alu\s*\(\s*\.fp_alu_op\s*\(\s*fp_alu_op_w\s*\),\s*\.fmt\s*\(\s*fmt_w\s*\),\s*\.rm\s*\(\s*rm_w\s*\),\s*\.fcsr_rm\s*\(\s*fcsr_rm_w\s*\),\s*\.rs1_data\s*\(\s*fp_rs1_data_w\s*\),\s*\.rs2_data\s*\(\s*fp_rs2_data_w\s*\),\s*\.rs3_data\s*\(\s*fp_rs3_data_w\s*\),\s*\.result\s*\(\s*fp_alu_result_w\s*\),\s*\.fflags\s*\(\s*fp_fflags_w\s*\)\s*\);')
            
    new_str = '''            fp_alu u_fp_alu (
                .fp_alu_op  (fp_alu_op_w),
                .fmt        (fmt_w),
                .rm         (rm_w),
                .fcsr_rm    (fcsr_rm_w),
                .rs1_data   (fp_rs1_data_w),
                .rs2_data   (fp_rs2_data_w),
                .rs3_data   (fp_rs3_data_w),
                .int_rs1_data (rs1_data_w),
                .int_to_fp  (int_to_fp_w),
                .fp_to_int  (fp_to_int_w),
                .rs2_addr   (instruction_w[24:20]),
                .result     (fp_alu_result_w),
                .fflags     (fp_fflags_w)
            );'''
            
    if old_pattern.search(content):
        content = old_pattern.sub(new_str, content)
    elif new_str in content:
        pass
    else:
        print("old_str not found in riscv_top.v")
        sys.exit(1)
    
    with open('rtl/core/riscv_top.v', 'w') as f:
        f.write(content)

patch_fp_alu()
patch_riscv_top()
