`ifndef RISCV_DRV_SV
`define RISCV_DRV_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class riscv_drv extends uvm_driver #(riscv_txn);
  `uvm_component_utils(riscv_drv)

  virtual riscv_if vif;

  function new(string name = "riscv_drv", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual riscv_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      
      if (req.hex_file_path != "") begin
        vif.load_hex(req.hex_file_path);
        `uvm_info("DRV", $sformatf("Loaded hex file: %s", req.hex_file_path), UVM_LOW)
      end

      wait(vif.rst_n === 1'b1);
      @(posedge vif.clk);
      
      seq_item_port.item_done();
    end
  endtask
endclass

`endif
