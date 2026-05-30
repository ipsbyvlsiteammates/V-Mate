`ifndef NEW_RISCV_SEQS_SV
`define NEW_RISCV_SEQS_SV

// 1. csr_hazard_fcsr_rm_change_seq
class csr_hazard_fcsr_rm_change_seq extends riscv_base_seq;
    `uvm_object_utils(csr_hazard_fcsr_rm_change_seq)
    function new(string name = "csr_hazard_fcsr_rm_change_seq"); super.new(name); endfunction
    task body();
        riscv_txn txn;
        int count = 0;
        repeat(50) begin
            txn = riscv_txn::type_id::create("txn");
            start_item(txn);
            if(!txn.randomize()) `uvm_error("SEQ", "Randomization failed")
            if (count == 0) txn.hex_file_path = "";
            else txn.hex_file_path = "";
            finish_item(txn);
            count++;
        end
    endtask
endclass

// 2. mem_hazard_lsu_branch_mispredict_seq
class mem_hazard_lsu_branch_mispredict_seq extends riscv_base_seq;
    `uvm_object_utils(mem_hazard_lsu_branch_mispredict_seq)
    function new(string name = "mem_hazard_lsu_branch_mispredict_seq"); super.new(name); endfunction
    task body();
        riscv_txn txn;
        int count = 0;
        repeat(50) begin
            txn = riscv_txn::type_id::create("txn");
            start_item(txn);
            if(!txn.randomize()) `uvm_error("SEQ", "Randomization failed")
            if (count == 0) txn.hex_file_path = "";
            else txn.hex_file_path = "";
            finish_item(txn);
            count++;
        end
    endtask
endclass

// 3. resource_exhaustion_rob_full_exception_seq
class resource_exhaustion_rob_full_exception_seq extends riscv_base_seq;
    `uvm_object_utils(resource_exhaustion_rob_full_exception_seq)
    function new(string name = "resource_exhaustion_rob_full_exception_seq"); super.new(name); endfunction
    task body();
        riscv_txn txn;
        int count = 0;
        repeat(50) begin
            txn = riscv_txn::type_id::create("txn");
            start_item(txn);
            if(!txn.randomize()) `uvm_error("SEQ", "Randomization failed")
            if (count == 0) txn.hex_file_path = "";
            else txn.hex_file_path = "";
            finish_item(txn);
            count++;
        end
    endtask
endclass

// 4. fpu_subnormal_fma_nan_boxing_seq
class fpu_subnormal_fma_nan_boxing_seq extends riscv_base_seq;
    `uvm_object_utils(fpu_subnormal_fma_nan_boxing_seq)
    function new(string name = "fpu_subnormal_fma_nan_boxing_seq"); super.new(name); endfunction
    task body();
        riscv_txn txn;
        int count = 0;
        repeat(50) begin
            txn = riscv_txn::type_id::create("txn");
            start_item(txn);
            if(!txn.randomize()) `uvm_error("SEQ", "Randomization failed")
            if (count == 0) txn.hex_file_path = "";
            else txn.hex_file_path = "";
            finish_item(txn);
            count++;
        end
    endtask
endclass

// 5. fpu_concurrent_mixed_precision_seq
class fpu_concurrent_mixed_precision_seq extends riscv_base_seq;
    `uvm_object_utils(fpu_concurrent_mixed_precision_seq)
    function new(string name = "fpu_concurrent_mixed_precision_seq"); super.new(name); endfunction
    task body();
        riscv_txn txn;
        int count = 0;
        repeat(50) begin
            txn = riscv_txn::type_id::create("txn");
            start_item(txn);
            if(!txn.randomize()) `uvm_error("SEQ", "Randomization failed")
            if (count == 0) txn.hex_file_path = "";
            else txn.hex_file_path = "";
            finish_item(txn);
            count++;
        end
    endtask
endclass

// 6. clock_gating_stall_wakeup_seq
class clock_gating_stall_wakeup_seq extends riscv_base_seq;
    `uvm_object_utils(clock_gating_stall_wakeup_seq)
    function new(string name = "clock_gating_stall_wakeup_seq"); super.new(name); endfunction
    task body();
        riscv_txn txn;
        int count = 0;
        repeat(50) begin
            txn = riscv_txn::type_id::create("txn");
            start_item(txn);
            if(!txn.randomize()) `uvm_error("SEQ", "Randomization failed")
            if (count == 0) txn.hex_file_path = "";
            else txn.hex_file_path = "";
            finish_item(txn);
            count++;
        end
    endtask
endclass


// icache_hazard_self_modifying_code_test_seq
class icache_hazard_self_modifying_code_test_seq extends riscv_base_seq;
    `uvm_object_utils(icache_hazard_self_modifying_code_test_seq)
    function new(string name = "icache_hazard_self_modifying_code_test_seq"); super.new(name); endfunction
    task body();
        riscv_txn txn;
        int count = 0;
        repeat(50) begin
            txn = riscv_txn::type_id::create("txn");
            start_item(txn);
            if(!txn.randomize()) `uvm_error("SEQ", "Randomization failed")
            if (count == 0) txn.hex_file_path = "";
            else txn.hex_file_path = "";
            finish_item(txn);
            count++;
        end
    endtask
endclass

// fpu_advanced_exceptions_test_seq
class fpu_advanced_exceptions_test_seq extends riscv_base_seq;
    `uvm_object_utils(fpu_advanced_exceptions_test_seq)
    function new(string name = "fpu_advanced_exceptions_test_seq"); super.new(name); endfunction
    task body();
        riscv_txn txn;
        int count = 0;
        repeat(50) begin
            txn = riscv_txn::type_id::create("txn");
            start_item(txn);
            if(!txn.randomize()) `uvm_error("SEQ", "Randomization failed")
            if (count == 0) txn.hex_file_path = "";
            else txn.hex_file_path = "";
            finish_item(txn);
            count++;
        end
    endtask
endclass

// branch_predictor_thrashing_test_seq
class branch_predictor_thrashing_test_seq extends riscv_base_seq;
    `uvm_object_utils(branch_predictor_thrashing_test_seq)
    function new(string name = "branch_predictor_thrashing_test_seq"); super.new(name); endfunction
    task body();
        riscv_txn txn;
        int count = 0;
        repeat(50) begin
            txn = riscv_txn::type_id::create("txn");
            start_item(txn);
            if(!txn.randomize()) `uvm_error("SEQ", "Randomization failed")
            if (count == 0) txn.hex_file_path = "";
            else txn.hex_file_path = "";
            finish_item(txn);
            count++;
        end
    endtask
endclass

// lsq_unaligned_forwarding_test_seq
class lsq_unaligned_forwarding_test_seq extends riscv_base_seq;
    `uvm_object_utils(lsq_unaligned_forwarding_test_seq)
    function new(string name = "lsq_unaligned_forwarding_test_seq"); super.new(name); endfunction
    task body();
        riscv_txn txn;
        int count = 0;
        repeat(50) begin
            txn = riscv_txn::type_id::create("txn");
            start_item(txn);
            if(!txn.randomize()) `uvm_error("SEQ", "Randomization failed")
            if (count == 0) txn.hex_file_path = "";
            else txn.hex_file_path = "";
            finish_item(txn);
            count++;
        end
    endtask
endclass


class riscv_ooo_page_fault_cache_eviction_test_seq extends riscv_base_seq;
  `uvm_object_utils(riscv_ooo_page_fault_cache_eviction_test_seq)
  function new(string name="riscv_ooo_page_fault_cache_eviction_test_seq");
    super.new(name);
  endfunction
  task body();
    #1000;
  endtask
endclass

class riscv_interrupt_storm_fpu_context_test_seq extends riscv_base_seq;
  `uvm_object_utils(riscv_interrupt_storm_fpu_context_test_seq)
  function new(string name="riscv_interrupt_storm_fpu_context_test_seq");
    super.new(name);
  endfunction
  task body();
    #1000;
  endtask
endclass

class riscv_misaligned_amo_pmp_fault_test_seq extends riscv_base_seq;
  `uvm_object_utils(riscv_misaligned_amo_pmp_fault_test_seq)
  function new(string name="riscv_misaligned_amo_pmp_fault_test_seq");
    super.new(name);
  endfunction
  task body();
    #1000;
  endtask
endclass

class riscv_icache_coherence_dma_test_seq extends riscv_base_seq;
  `uvm_object_utils(riscv_icache_coherence_dma_test_seq)
  function new(string name="riscv_icache_coherence_dma_test_seq");
    super.new(name);
  endfunction
  task body();
    #1000;
  endtask
endclass

class csr_hazard_multicore_interrupt_seq extends riscv_base_seq;
  `uvm_object_utils(csr_hazard_multicore_interrupt_seq)
  function new(string name = "csr_hazard_multicore_interrupt_seq");
    super.new(name);
  endfunction
  virtual task body();
    `uvm_info(get_type_name(), "Executing csr_hazard_multicore_interrupt_seq", UVM_LOW)
  endtask
endclass

class mem_hazard_dma_cache_coherence_seq extends riscv_base_seq;
  `uvm_object_utils(mem_hazard_dma_cache_coherence_seq)
  function new(string name = "mem_hazard_dma_cache_coherence_seq");
    super.new(name);
  endfunction
  virtual task body();
    `uvm_info(get_type_name(), "Executing mem_hazard_dma_cache_coherence_seq", UVM_LOW)
  endtask
endclass

class resource_exhaustion_rob_lsq_full_seq extends riscv_base_seq;
  `uvm_object_utils(resource_exhaustion_rob_lsq_full_seq)
  function new(string name = "resource_exhaustion_rob_lsq_full_seq");
    super.new(name);
  endfunction
  virtual task body();
    `uvm_info(get_type_name(), "Executing resource_exhaustion_rob_lsq_full_seq", UVM_LOW)
  endtask
endclass

class fpu_edge_case_denormal_pipeline_flush_seq extends riscv_base_seq;
  `uvm_object_utils(fpu_edge_case_denormal_pipeline_flush_seq)
  function new(string name = "fpu_edge_case_denormal_pipeline_flush_seq");
    super.new(name);
  endfunction
  virtual task body();
    `uvm_info(get_type_name(), "Executing fpu_edge_case_denormal_pipeline_flush_seq", UVM_LOW)
  endtask
endclass

class clock_gating_debug_mode_wakeup_seq extends riscv_base_seq;
  `uvm_object_utils(clock_gating_debug_mode_wakeup_seq)
  function new(string name = "clock_gating_debug_mode_wakeup_seq");
    super.new(name);
  endfunction
  virtual task body();
    `uvm_info(get_type_name(), "Executing clock_gating_debug_mode_wakeup_seq", UVM_LOW)
  endtask
endclass
`endif
