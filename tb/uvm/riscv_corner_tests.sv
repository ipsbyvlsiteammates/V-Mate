`ifndef NEW_RISCV_TESTS_SV
`define NEW_RISCV_TESTS_SV

// 1. csr_hazard_fcsr_rm_change_test
class csr_hazard_fcsr_rm_change_test extends riscv_test;
    `uvm_component_utils(csr_hazard_fcsr_rm_change_test)
    function new(string name = "csr_hazard_fcsr_rm_change_test", uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        csr_hazard_fcsr_rm_change_seq seq;
        phase.raise_objection(this);
        seq = csr_hazard_fcsr_rm_change_seq::type_id::create("seq");
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
    endtask
endclass

// 2. mem_hazard_lsu_branch_mispredict_test
class mem_hazard_lsu_branch_mispredict_test extends riscv_test;
    `uvm_component_utils(mem_hazard_lsu_branch_mispredict_test)
    function new(string name = "mem_hazard_lsu_branch_mispredict_test", uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        mem_hazard_lsu_branch_mispredict_seq seq;
        phase.raise_objection(this);
        seq = mem_hazard_lsu_branch_mispredict_seq::type_id::create("seq");
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
    endtask
endclass

// 3. resource_exhaustion_rob_full_exception_test
class resource_exhaustion_rob_full_exception_test extends riscv_test;
    `uvm_component_utils(resource_exhaustion_rob_full_exception_test)
    function new(string name = "resource_exhaustion_rob_full_exception_test", uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        resource_exhaustion_rob_full_exception_seq seq;
        phase.raise_objection(this);
        seq = resource_exhaustion_rob_full_exception_seq::type_id::create("seq");
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
    endtask
endclass

// 4. fpu_subnormal_fma_nan_boxing_test
class fpu_subnormal_fma_nan_boxing_test extends riscv_test;
    `uvm_component_utils(fpu_subnormal_fma_nan_boxing_test)
    function new(string name = "fpu_subnormal_fma_nan_boxing_test", uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        fpu_subnormal_fma_nan_boxing_seq seq;
        phase.raise_objection(this);
        seq = fpu_subnormal_fma_nan_boxing_seq::type_id::create("seq");
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
    endtask
endclass

// 5. fpu_concurrent_mixed_precision_test
class fpu_concurrent_mixed_precision_test extends riscv_test;
    `uvm_component_utils(fpu_concurrent_mixed_precision_test)
    function new(string name = "fpu_concurrent_mixed_precision_test", uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        fpu_concurrent_mixed_precision_seq seq;
        phase.raise_objection(this);
        seq = fpu_concurrent_mixed_precision_seq::type_id::create("seq");
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
    endtask
endclass

// 6. clock_gating_stall_wakeup_test
class clock_gating_stall_wakeup_test extends riscv_test;
    `uvm_component_utils(clock_gating_stall_wakeup_test)
    function new(string name = "clock_gating_stall_wakeup_test", uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        clock_gating_stall_wakeup_seq seq;
        phase.raise_objection(this);
        seq = clock_gating_stall_wakeup_seq::type_id::create("seq");
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
    endtask
endclass


// icache_hazard_self_modifying_code_test
class icache_hazard_self_modifying_code_test extends riscv_test;
    `uvm_component_utils(icache_hazard_self_modifying_code_test)
    function new(string name = "icache_hazard_self_modifying_code_test", uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        icache_hazard_self_modifying_code_test_seq seq;
        phase.raise_objection(this);
        seq = icache_hazard_self_modifying_code_test_seq::type_id::create("seq");
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
    endtask
endclass

// fpu_advanced_exceptions_test
class fpu_advanced_exceptions_test extends riscv_test;
    `uvm_component_utils(fpu_advanced_exceptions_test)
    function new(string name = "fpu_advanced_exceptions_test", uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        fpu_advanced_exceptions_test_seq seq;
        phase.raise_objection(this);
        seq = fpu_advanced_exceptions_test_seq::type_id::create("seq");
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
    endtask
endclass

// branch_predictor_thrashing_test
class branch_predictor_thrashing_test extends riscv_test;
    `uvm_component_utils(branch_predictor_thrashing_test)
    function new(string name = "branch_predictor_thrashing_test", uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        branch_predictor_thrashing_test_seq seq;
        phase.raise_objection(this);
        seq = branch_predictor_thrashing_test_seq::type_id::create("seq");
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
    endtask
endclass

// lsq_unaligned_forwarding_test
class lsq_unaligned_forwarding_test extends riscv_test;
    `uvm_component_utils(lsq_unaligned_forwarding_test)
    function new(string name = "lsq_unaligned_forwarding_test", uvm_component parent = null); super.new(name, parent); endfunction
    virtual task run_phase(uvm_phase phase);
        lsq_unaligned_forwarding_test_seq seq;
        phase.raise_objection(this);
        seq = lsq_unaligned_forwarding_test_seq::type_id::create("seq");
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
    endtask
endclass


class riscv_ooo_page_fault_cache_eviction_test extends riscv_test;
  `uvm_component_utils(riscv_ooo_page_fault_cache_eviction_test)
  function new(string name="riscv_ooo_page_fault_cache_eviction_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    riscv_ooo_page_fault_cache_eviction_test_seq seq;
    phase.raise_objection(this);
    seq = riscv_ooo_page_fault_cache_eviction_test_seq::type_id::create("seq");
    seq.start(env.agent.sqr);
    phase.drop_objection(this);
  endtask
endclass

class riscv_interrupt_storm_fpu_context_test extends riscv_test;
  `uvm_component_utils(riscv_interrupt_storm_fpu_context_test)
  function new(string name="riscv_interrupt_storm_fpu_context_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    riscv_interrupt_storm_fpu_context_test_seq seq;
    phase.raise_objection(this);
    seq = riscv_interrupt_storm_fpu_context_test_seq::type_id::create("seq");
    seq.start(env.agent.sqr);
    phase.drop_objection(this);
  endtask
endclass

class riscv_misaligned_amo_pmp_fault_test extends riscv_test;
  `uvm_component_utils(riscv_misaligned_amo_pmp_fault_test)
  function new(string name="riscv_misaligned_amo_pmp_fault_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    riscv_misaligned_amo_pmp_fault_test_seq seq;
    phase.raise_objection(this);
    seq = riscv_misaligned_amo_pmp_fault_test_seq::type_id::create("seq");
    seq.start(env.agent.sqr);
    phase.drop_objection(this);
  endtask
endclass

class riscv_icache_coherence_dma_test extends riscv_test;
  `uvm_component_utils(riscv_icache_coherence_dma_test)
  function new(string name="riscv_icache_coherence_dma_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    riscv_icache_coherence_dma_test_seq seq;
    phase.raise_objection(this);
    seq = riscv_icache_coherence_dma_test_seq::type_id::create("seq");
    seq.start(env.agent.sqr);
    phase.drop_objection(this);
  endtask
endclass

class csr_hazard_multicore_interrupt_test extends riscv_test;
  `uvm_component_utils(csr_hazard_multicore_interrupt_test)
  function new(string name = "csr_hazard_multicore_interrupt_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    csr_hazard_multicore_interrupt_seq seq;
    seq = csr_hazard_multicore_interrupt_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sqr);
    phase.drop_objection(this);
  endtask
endclass

class mem_hazard_dma_cache_coherence_test extends riscv_test;
  `uvm_component_utils(mem_hazard_dma_cache_coherence_test)
  function new(string name = "mem_hazard_dma_cache_coherence_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    mem_hazard_dma_cache_coherence_seq seq;
    seq = mem_hazard_dma_cache_coherence_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sqr);
    phase.drop_objection(this);
  endtask
endclass

class resource_exhaustion_rob_lsq_full_test extends riscv_test;
  `uvm_component_utils(resource_exhaustion_rob_lsq_full_test)
  function new(string name = "resource_exhaustion_rob_lsq_full_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    resource_exhaustion_rob_lsq_full_seq seq;
    seq = resource_exhaustion_rob_lsq_full_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sqr);
    phase.drop_objection(this);
  endtask
endclass

class fpu_edge_case_denormal_pipeline_flush_test extends riscv_test;
  `uvm_component_utils(fpu_edge_case_denormal_pipeline_flush_test)
  function new(string name = "fpu_edge_case_denormal_pipeline_flush_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    fpu_edge_case_denormal_pipeline_flush_seq seq;
    seq = fpu_edge_case_denormal_pipeline_flush_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sqr);
    phase.drop_objection(this);
  endtask
endclass

class clock_gating_debug_mode_wakeup_test extends riscv_test;
  `uvm_component_utils(clock_gating_debug_mode_wakeup_test)
  function new(string name = "clock_gating_debug_mode_wakeup_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  task run_phase(uvm_phase phase);
    clock_gating_debug_mode_wakeup_seq seq;
    seq = clock_gating_debug_mode_wakeup_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agent.sqr);
    phase.drop_objection(this);
  endtask
endclass
`endif
