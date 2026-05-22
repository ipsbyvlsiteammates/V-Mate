
import sys

file_path = 'rtl/core/fp_divsqrt.sv'
try:
    with open(file_path, 'r') as f:
        content = f.read()
except Exception as e:
    print(f"Error reading file: {e}")
    sys.exit(1)

content = content.replace('\r\n', '\n')

replace1_old = '''    always_comb begin
        if (rs2_sig_norm_div != 0) begin
            div_sig_full = {1'b0, rs1_sig_norm_div, 56'b0} / rs2_sig_norm_div;
            div_rem      = 56'({1'b0, rs1_sig_norm_div, 56'b0} % rs2_sig_norm_div);
        end else begin
            div_sig_full = '0;
            div_rem      = '0;
        end
    end'''

replace1_new = '''    logic [55:0] safe_rs2_sig_norm_div;
    assign safe_rs2_sig_norm_div = (rs2_sig_norm_div != 0) ? rs2_sig_norm_div : 56'd1;
    
    always_comb begin
        if (rs2_sig_norm_div != 0) begin
            div_sig_full = {1'b0, rs1_sig_norm_div, 56'b0} / safe_rs2_sig_norm_div;
            div_rem      = 56'({1'b0, rs1_sig_norm_div, 56'b0} % safe_rs2_sig_norm_div);
        end else begin
            div_sig_full = '0;
            div_rem      = '0;
        end
    end'''

replace2_old = '''    always_comb begin
        if (div_sig_full == 0) begin
            div_sig = '0;
            div_exp_norm = div_exp;
        end else if (msb_pos >= 7'd55) begin
            div_discarded_mask = (113'd1 << shift_right_amt) - 113'd1;
            sticky_div = |(div_sig_full & div_discarded_mask) | (div_rem != 0);
            div_sig = 56'(div_sig_full >> shift_right_amt) | {55'b0, sticky_div};
            div_exp_norm = div_exp - 13'sd56 + signed'({6'b0, msb_pos});
        end else begin
            div_sig = 56'(div_sig_full << (7'd55 - msb_pos)) | {55'b0, (div_rem != 0)};
            div_exp_norm = div_exp - 13'sd56 + signed'({6'b0, msb_pos});
        end
    end'''

replace2_new = '''    always_comb begin
        div_discarded_mask = '0;
        sticky_div = 1'b0;
        if (div_sig_full == 0) begin
            div_sig = '0;
            div_exp_norm = div_exp;
        end else if (msb_pos >= 7'd55) begin
            div_discarded_mask = (113'd1 << shift_right_amt) - 113'd1;
            sticky_div = |(div_sig_full & div_discarded_mask) | (div_rem != 0);
            div_sig = 56'(div_sig_full >> shift_right_amt) | {55'b0, sticky_div};
            div_exp_norm = div_exp - 13'sd56 + signed'({6'b0, msb_pos});
        end else begin
            div_sig = 56'(div_sig_full << (7'd55 - msb_pos)) | {55'b0, (div_rem != 0)};
            div_exp_norm = div_exp - 13'sd56 + signed'({6'b0, msb_pos});
        end
    end'''

if replace1_old in content:
    content = content.replace(replace1_old, replace1_new)
else:
    print("Error: replace1_old not found in file")
    sys.exit(1)

if replace2_old in content:
    content = content.replace(replace2_old, replace2_new)
else:
    print("Error: replace2_old not found in file")
    sys.exit(1)

try:
    with open(file_path, 'w') as f:
        f.write(content)
    print("Patch applied successfully")
except Exception as e:
    print(f"Error writing file: {e}")
    sys.exit(1)

