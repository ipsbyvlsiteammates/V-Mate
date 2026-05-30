import os
import subprocess
import sys
import struct
import glob
import shutil
import re

dv_dir = '/home/guy/Sagi/riscv_processor/riscv-dv'
sim_dir = '/home/guy/Sagi/riscv_processor/sim'

# 1. Patch tb_uvm_top.sv
tb_file = '/home/guy/Sagi/riscv_processor/tb/uvm/tb_uvm_top.sv'
with open(tb_file, 'r') as f:
    tb_content = f.read()

if 'tohost_addr' not in tb_content:
    monitor_code = '''
    longint tohost_addr;
    initial begin
        if (!$value$plusargs("TOHOST_ADDR=%x", tohost_addr)) begin
            $display("WARNING: +TOHOST_ADDR not provided. Using default.");
            tohost_addr = 64'h80001000;
        end
    end

    always @(posedge clk) begin
        if (dut.bound_if.mem_write_mem && dut.bound_if.alu_result_mem == tohost_addr) begin
            if (dut.bound_if.write_data_mem[0] == 1'b1) begin
                if (dut.bound_if.write_data_mem >> 1 == 0) begin
                    $display("TEST PASSED");
                end else begin
                    $display("TEST FAILED with code %0d", dut.bound_if.write_data_mem >> 1);
                end
                $finish;
            end
        end
    end

    initial begin
        #50000000; // 50ms timeout
        $display("TEST TIMEOUT");
        $finish;
    end
'''
    tb_content = tb_content.replace('endmodule', monitor_code + '\nendmodule')
    with open(tb_file, 'w') as f:
        f.write(tb_content)

# 2. Patch sequences
seq_file = '/home/guy/Sagi/riscv_processor/tb/uvm/riscv_base_seq.sv'
with open(seq_file, 'r') as f:
    seq_content = f.read()
seq_content = re.sub(r'repeat\s*\(\s*50\s*\)', 'repeat(50)', seq_content)
with open(seq_file, 'w') as f:
        f.write(seq_content)

fp_seq_file = '/home/guy/Sagi/riscv_processor/tb/uvm/riscv_fp_seq.sv'
with open(fp_seq_file, 'r') as f:
    fp_seq_content = f.read()
fp_seq_content = re.sub(r'i\s*<\s*50', 'i < 50', fp_seq_content)
with open(fp_seq_file, 'w') as f:
    f.write(fp_seq_content)

# 3. Generate tests
tests = [
    'riscv_precise_exceptions_fp_test',
    'riscv_ooo_mode_toggling_test',
    'riscv_nan_boxing_forwarding_test',
    'riscv_m_mode_serialization_test',
    'riscv_fcsr_dependency_test',
    'riscv_clock_gating_stall_test',
    'riscv_amo_ooo_fp_test',
    'riscv_async_interrupt_ooo_fp_test',
    'riscv_branch_mispredict_overlap_test',
    'riscv_lsq_forwarding_trap_test',
    'riscv_speculative_csr_test',
]

os.chdir(dv_dir)
env = os.environ.copy()
env['RISCV_GCC'] = subprocess.check_output(['which', 'riscv64-unknown-elf-gcc']).decode().strip()
env['RISCV_OBJCOPY'] = subprocess.check_output(['which', 'riscv64-unknown-elf-objcopy']).decode().strip()
env['SPIKE_PATH'] = '/home/guy/Sagi/riscv_processor/spike_install/bin'
env['PATH'] = '/home/guy/Sagi/riscv_processor/dtc_install/bin:' + env['PATH']

python_exe = 'python3'

if os.path.exists('out_regression'):
    shutil.rmtree('out_regression')

for test in tests:
    print(f"Running riscv-dv for {test}...")
    cmd = [
        python_exe, 'run.py',
        '--target', 'rv32imafdc',
        '--isa', 'rv32imafdc',
        '--mabi', 'ilp32d',
        '--test', test,
        '--iterations', '1',
        '-o', 'out_regression',
        '--steps', 'gen,gcc_compile',
        '--gcc_opts=-mno-relax -march=rv32imafdc_zifencei'
    ]
    res = subprocess.run(cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    if res.returncode != 0:
        print(f"Failed to generate {test}")
        print(res.stderr)

# 4. Compile UVM
os.chdir(sim_dir)
print("Compiling UVM testbench...")
res = subprocess.run(['bash', './compile_uvm.sh'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
with open('compile_uvm.log', 'w') as log_f:
    log_f.write(res.stdout)
    log_f.write(res.stderr)
if res.returncode != 0:
    print("Failed to compile UVM")
    print(res.stderr)
    sys.exit(1)

# 5. Run simulations
o_files = glob.glob(os.path.join(dv_dir, 'out_regression/asm_test/*.o'))
print(f"Found {len(o_files)} object files.")

for obj_file in o_files:
    test_name = os.path.basename(obj_file).replace('.o', '')
    elf_file = obj_file
    print(f"Processing {test_name}...")
    
    res = subprocess.run(['riscv64-unknown-elf-nm', obj_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    with open(f'{test_name}_nm.log', 'w') as log_f:
        log_f.write(res.stdout)
        log_f.write(res.stderr)
    
    tohost_addr = None
    for line in res.stdout.splitlines():
        parts = line.split()
        if len(parts) >= 3 and parts[-1] == 'tohost':
            tohost_addr = parts[0]
            break
    if not tohost_addr:
        print(f"tohost not found for {test_name}, skipping...")
        continue
        
    res = subprocess.run(['riscv64-unknown-elf-objcopy', '-O', 'binary', elf_file, 'full.bin'])
    if res.returncode != 0:
        print(f"objcopy failed for {test_name}")
        continue
        
    with open('full.bin', 'rb') as f:
        data = f.read()
    data = data.ljust(524288, b'\x00')
    
    with open('imem.hex', 'w') as f_imem, open('dmem.hex', 'w') as f_dmem:
        for i in range(0, len(data), 4):
            word = data[i:i+4]
            if len(word) < 4:
                word = word.ljust(4, b'\x00')
            val = struct.unpack('<I', word)[0]
            f_imem.write(f"{val:08x}\n")
        for i in range(len(data)):
            f_dmem.write(f"{data[i]:02x}\n")
            
    print(f"Running simulation for {test_name}...")
    res = subprocess.run([
        './simv_uvm',
        '+UVM_TESTNAME=riscv_test',
        f'+TOHOST_ADDR={tohost_addr}',
        '-cm', 'line+cond+fsm+tgl+branch+assert',
        '-cm_name', test_name
    ], stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    
    with open(f'{test_name}_sim.log', 'w') as log_f:
        log_f.write(res.stdout)
        log_f.write(res.stderr)
    
    if res.returncode != 0 or 'TEST FAILED' in res.stdout or 'TEST TIMEOUT' in res.stdout or re.search(r'UVM_ERROR\s*:\s*[1-9]', res.stdout) or re.search(r'UVM_FATAL\s*:\s*[1-9]', res.stdout):
        print(f"Simulation failed for {test_name} (rc={res.returncode})")
        for line in res.stdout.splitlines():
            if 'UVM_ERROR' in line or 'UVM_FATAL' in line or 'TEST FAILED' in line or 'TEST TIMEOUT' in line:
                print(line)
    else:
        print(f"Simulation passed for {test_name}")

# 6. Generate coverage report
print("Generating coverage report...")
res = subprocess.run(['urg', '-dir', 'simv_uvm.vdb', '-format', 'text', '-report', 'urgReport'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
with open('urg.log', 'w') as log_f:
    log_f.write(res.stdout)
    log_f.write(res.stderr)

print("Coverage Summary:")
if os.path.exists('urgReport/dashboard.txt'):
    with open('urgReport/dashboard.txt', 'r') as f:
        print(f.read())
print("Done.")