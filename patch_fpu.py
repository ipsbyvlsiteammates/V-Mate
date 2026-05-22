import sys

fp_fma_path = 'rtl/core/fp_fma.sv'
fpr_path = 'rtl/core/fpr.v'

with open(fp_fma_path, 'r') as f:
    fp_fma_content = f.read()

fma_old = '''        if (op == 3'b000 || op == 3'b001) begin
            eff_rs2 = '0';
            eff_rs2.sig = {1'b1, 55'b0};
            eff_rs2.exp = 13'sd0;
            eff_rs2.is_zero = 1'b0;
            eff_rs2.is_inf = 1'b0;
            eff_rs2.is_nan = 1'b0;
            eff_rs2.is_snan = 1'b0;
            eff_rs2.is_qnan = 1'b0;
            eff_rs2.sign = 1'b0;
            eff_rs3 = rs2_unpacked;
        end else if (op == 3'b010) begin
            eff_rs2 = rs2_unpacked;
            eff_rs3 = '0';
            eff_rs3.is_zero = 1'b1;
            eff_rs3.sign = eff_rs1.sign ^ eff_rs2.sign;'''

fma_new = '''        if (op == 3'b000 || op == 3'b001) begin
            eff_rs2 = '0';
            eff_rs2.sig = {1'b1, 55'b0};
            eff_rs2.exp = 13'sd0;
            eff_rs2.is_zero = 1'b0;
            eff_rs2.is_inf = 1'b0;
            eff_rs2.is_nan = 1'b0;
            eff_rs2.is_snan = 1'b0;
            eff_rs2.is_qnan = 1'b0;
            eff_rs2.is_subnormal = 1'b0;
            eff_rs2.sign = 1'b0;
            eff_rs3 = rs2_unpacked;
        end else if (op == 3'b010) begin
            eff_rs2 = rs2_unpacked;
            eff_rs3 = '0';
            eff_rs3.is_zero = 1'b1;
            eff_rs3.is_inf = 1'b0;
            eff_rs3.is_nan = 1'b0;
            eff_rs3.is_snan = 1'b0;
            eff_rs3.is_qnan = 1'b0;
            eff_rs3.is_subnormal = 1'b0;
            eff_rs3.exp = 13'sd0;
            eff_rs3.sig = 56'b0;
            eff_rs3.sign = eff_rs1.sign ^ eff_rs2.sign;'''

if fma_old in fp_fma_content:
    fp_fma_content = fp_fma_content.replace(fma_old, fma_new)
    with open(fp_fma_path, 'w') as f:
        f.write(fp_fma_content)
    print("fp_fma.sv patched successfully.")
else:
    print("Error: fma_old not found in fp_fma.sv")
    sys.exit(1)

with open(fpr_path, 'r') as f:
    fpr_content = f.read()

fpr_old = '''    always @(posedge gated_clk) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                fpr_array[i] <= {FLEN{1'b0}};
            end
        end else if (we) begin
            fpr_array[rd_addr] <= write_data;
        end
    end'''

fpr_new = '''    always @(posedge gated_clk) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                fpr_array[i] <= {FLEN{1'b0}};
            end
        end else if (we) begin
            if (EXTENSION_D && fmt == 2'b00) begin
                fpr_array[rd_addr] <= {32'hFFFFFFFF, write_data[31:0]};
            end else begin
                fpr_array[rd_addr] <= write_data;
            end
        end
    end'''

if fpr_old in fpr_content:
    fpr_content = fpr_content.replace(fpr_old, fpr_new)
    with open(fpr_path, 'w') as f:
        f.write(fpr_content)
    print("fpr.v patched successfully.")
else:
    print("Error: fpr_old not found in fpr.v")
    sys.exit(1)
