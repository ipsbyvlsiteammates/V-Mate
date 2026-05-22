import re
import os

filepath = 'rtl/core/fp_round_pack.sv'
with open(filepath, 'r') as f:
    content = f.read()

unbounded_logic = '''    logic unbounded_guard, unbounded_round, unbounded_sticky;
    logic unbounded_round_up;
    logic unbounded_tiny;

    always_comb begin
        if (is_fp32) begin
            unbounded_guard = norm_sig[31];
            unbounded_round = norm_sig[30];
            unbounded_sticky = |norm_sig[29:0];
        end else begin
            unbounded_guard = norm_sig[2];
            unbounded_round = norm_sig[1];
            unbounded_sticky = norm_sig[0];
        end
        
        unbounded_round_up = 1'b0;
        case (rm)
            RNE: unbounded_round_up = unbounded_guard && (unbounded_round || unbounded_sticky || norm_sig[is_fp32 ? 32 : 3]);
            RTZ: unbounded_round_up = 1'b0;
            RDN: unbounded_round_up = sign && (unbounded_guard || unbounded_round || unbounded_sticky);
            RUP: unbounded_round_up = !sign && (unbounded_guard || unbounded_round || unbounded_sticky);
            RMM: unbounded_round_up = unbounded_guard;
            default: unbounded_round_up = 1'b0;
        endcase

        if (sig == 0) begin
            unbounded_tiny = 1'b0;
        end else if (unbounded_exp < 0) begin
            unbounded_tiny = 1'b1;
        end else if (unbounded_exp == 0) begin
            if (is_fp32) begin
                unbounded_tiny = !((norm_sig[54:32] == 23'h7FFFFF) && unbounded_round_up);
            end else begin
                unbounded_tiny = !((norm_sig[54:3] == 52'hFFFFFFFFFFFFF) && unbounded_round_up);
            end
        end else begin
            unbounded_tiny = 1'b0;
        end
    end'''

if "unbounded_tiny" not in content:
    target = "    logic signed [12:0] final_exp;"
    if target in content:
        content = content.replace(target, unbounded_logic + "\n" + target)
    else:
        match = re.search(r"^[ \t]*logic\s+(?:signed\s+)?\[[^\]]+\]\s+final_exp\s*;", content, re.MULTILINE)
        if match:
            content = content[:match.start()] + unbounded_logic + "\n" + match.group(0) + content[match.end():]
        else:
            print("Target 1 not found. File content:")
            print(content)
            exit(1)

    content = re.sub(r"uf\s*=\s*1'b0;\s*out_exp\s*=\s*8'h01;", "uf = unbounded_tiny & nx;\n                    out_exp = 8'h01;", content)
    content = re.sub(r"uf\s*=\s*nx;\s*out_exp\s*=\s*8'h00;", "uf = unbounded_tiny & nx;\n                    out_exp = 8'h00;", content)
    content = re.sub(r"uf\s*=\s*1'b0;\s*out_exp\s*=\s*11'h001;", "uf = unbounded_tiny & nx;\n                    out_exp = 11'h001;", content)
    content = re.sub(r"uf\s*=\s*nx;\s*out_exp\s*=\s*11'h000;", "uf = unbounded_tiny & nx;\n                    out_exp = 11'h000;", content)

    with open(filepath, 'w') as f:
        f.write(content)
print("Patch applied successfully")

