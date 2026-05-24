`ifndef RISCV_COV_SV
`define RISCV_COV_SV
class riscv_cov extends uvm_subscriber #(riscv_txn);
  `uvm_component_utils(riscv_cov)

  function int get_fp_type(logic [63:0] data);
    logic [10:0] exp = data[62:52];
    logic [51:0] frac = data[51:0];
    if (exp == 11'h000 && frac == 52'h0) return 0; // Zero
    if (exp == 11'h000 && frac != 52'h0) return 1; // Subnormal
    if (exp == 11'h7FF && frac == 52'h0) return 3; // Infinity
    if (exp == 11'h7FF && frac != 52'h0) return 4; // NaN
    return 2; // Normal
  endfunction

  covergroup cg_instr_types;
    option.per_instance = 1;
    cp_opcode: coverpoint txn.instruction[6:0] {
      bins r_type = {7'b0110011};
      bins i_type = {7'b0010011, 7'b0000011, 7'b1100111};
      bins s_type = {7'b0100011};
      bins b_type = {7'b1100011};
      bins u_type = {7'b0110111, 7'b0010111};
      bins j_type = {7'b1101111};
      bins fp_load = {7'b0000111};
      bins fp_store = {7'b0100111};
      bins fp_madd = {7'b1000011};
      bins fp_msub = {7'b1000111};
      bins fp_nmsub = {7'b1001011};
      bins fp_nmadd = {7'b1001111};
      bins fp_op = {7'b1010011};
      bins amo = {7'b0101111};
    }
  endgroup

  covergroup cg_fp_behavior;
    option.per_instance = 1;
    cp_fcsr_rm: coverpoint txn.fcsr_rm {
      bins rne = {3'b000};
      bins rtz = {3'b001};
      bins rdn = {3'b010};
      bins rup = {3'b011};
      bins rmm = {3'b100};
      bins invalid = {3'b101, 3'b110, 3'b111};
    }
    cp_fflags: coverpoint txn.fflags_update {
      bins nx = {5'b00001};
      bins uf = {5'b00010};
      bins of = {5'b00100};
      bins dz = {5'b01000};
      bins nv = {5'b10000};
    }
    cp_exception: coverpoint txn.exception {
      bins no_exc = {0};
      bins exc = {1};
    }
    cp_rs1_type: coverpoint get_fp_type(txn.fp_rs1_data) {
      bins zero = {0};
      bins subnormal = {1};
      bins normal = {2};
      bins infinity = {3};
      bins nan = {4};
    }
    cp_rs2_type: coverpoint get_fp_type(txn.fp_rs2_data) {
      bins zero = {0};
      bins subnormal = {1};
      bins normal = {2};
      bins infinity = {3};
      bins nan = {4};
    }
    cross cp_fcsr_rm, cp_fflags;
    cross cp_fcsr_rm, cp_exception;
    cross cp_exception, cp_fflags;
  endgroup

  covergroup cg_amo_behavior;
    option.per_instance = 1;
    cp_amo_op: coverpoint txn.amo_op {
      bins lr = {5'b00010};
      bins sc = {5'b00011};
      bins amoswap = {5'b00001};
      bins amoadd = {5'b00000};
      bins amoxor = {5'b00100};
      bins amoand = {5'b01100};
      bins amoor = {5'b01000};
      bins amomin = {5'b10000};
      bins amomax = {5'b10100};
      bins amominu = {5'b11000};
      bins amomaxu = {5'b11100};
    }
    cp_reservation_valid: coverpoint txn.reservation_valid {
      bins valid = {1};
      bins invalid = {0};
    }
    cross cp_amo_op, cp_reservation_valid;
  endgroup

  covergroup cg_csr_behavior;
    option.per_instance = 1;
    cp_csr_op: coverpoint txn.csr_op {
      bins rw = {2'b01};
      bins rs = {2'b10};
      bins rc = {2'b11};
    }
    cp_csr_write: coverpoint txn.csr_write {
      bins write = {1};
      bins no_write = {0};
    }
  endgroup

  riscv_txn txn;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_instr_types = new();
    cg_fp_behavior = new();
    cg_amo_behavior = new();
    cg_csr_behavior = new();
  endfunction
  virtual function void write(riscv_txn t);
    this.txn = t;
    cg_instr_types.sample();
    if (t.fp_we || t.instruction[6:0] == 7'b0100111 || t.instruction[6:0] == 7'b1010011 || t.instruction[6:0] == 7'b1000011 || t.instruction[6:0] == 7'b1000111 || t.instruction[6:0] == 7'b1001011 || t.instruction[6:0] == 7'b1001111) begin
      cg_fp_behavior.sample();
    end
    if (t.amo_en) begin
      cg_amo_behavior.sample();
    end
    if (t.csr_op != 2'b00) begin
      cg_csr_behavior.sample();
    end
  endfunction
endclass
`endif
