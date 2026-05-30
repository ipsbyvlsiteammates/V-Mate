import sys
failed_tests_list = []
import os
import subprocess
import sys
import glob

def bin_to_hex(bin_file, imem_file, dmem_file):
    import os
    if not os.path.exists(bin_file) or os.path.getsize(bin_file) == 0:
        with open(imem_file, "w") as f: pass
        with open(dmem_file, "w") as f: pass
        return
    with open(bin_file, "rb") as f:
        data = f.read()
    imem_data = data
    rem = len(imem_data) % 4
    if rem != 0:
        imem_data += b'\x00' * (4 - rem)
    with open(imem_file, "w") as f:
        it = iter(imem_data)
        for _ in range(len(imem_data) // 4):
            w0 = next(it)
            w1 = next(it)
            w2 = next(it)
            w3 = next(it)
            val = w0 | (w1 << 8) | (w2 << 16) | (w3 << 24)
            f.write(f"{val:08x}\n")
    with open(dmem_file, "w") as f:
        for b in data:
            f.write(f"{b:02x}\n")
def run_cmd(cmd, cwd=None, shell=False):
    print(f"Running: {cmd if shell else ' '.join(cmd)}")
    try:
        result = subprocess.run(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True, shell=shell, timeout=120)
        print(result.stdout)
        if result.returncode != 0:
            print(f"Command failed: {cmd if shell else ' '.join(cmd)}")
            failed_tests_list.append(1)
        return result.stdout
    except subprocess.TimeoutExpired as e:
        print(f"Command timed out: {cmd if shell else ' '.join(cmd)}")
        if e.stdout:
            print(e.stdout)
        failed_tests_list.append(1)
        return ""

def find_executable(name):
    cmd = f"find /home/guy/Sagi/riscv_processor/riscv-unified-db/bin /opt/riscv/bin -name {name} 2>/dev/null | head -n 1"
    print(f"Finding {name}...")
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, shell=True)
    path = result.stdout.strip()
    if not path:
        print(f"Could not find {name}")
        failed_tests_list.append(1)
    return path

def main():
    gcc_path = find_executable("riscv64-unknown-elf-gcc")
    objcopy_path = find_executable("riscv64-unknown-elf-objcopy")
    
    os.environ['RISCV_GCC'] = gcc_path
    os.environ['RISCV_OBJCOPY'] = objcopy_path
    os.environ['SPIKE_PATH'] = '/home/guy/Sagi/riscv_processor/bin'
    
    gcc_dir = os.path.dirname(gcc_path)
    os.environ['PATH'] = gcc_dir + os.pathsep + os.environ.get('PATH', '')
    
    nm_path = objcopy_path.replace("objcopy", "nm")
    
    tests = [
        "csr_hazard_multicore_interrupt_test",
        "mem_hazard_dma_cache_coherence_test",
        "resource_exhaustion_rob_lsq_full_test",
        "fpu_edge_case_denormal_pipeline_flush_test",
        "clock_gating_debug_mode_wakeup_test"
    ]
    
    sim_dir = "/home/guy/Sagi/riscv_processor/sim"
    riscv_dv_dir = "/home/guy/Sagi/riscv_processor/riscv-dv"
    
    # Compile UVM
#     run_cmd(["bash", "compile_uvm.sh"], cwd=sim_dir)
    
    for test in tests:
        print(f"\n--- Running {test} ---")
        
        # Run riscv-dv
        run_cmd(["python3", "run.py", "--target", "rv32imafdc", "--test", test, "--iterations", "1"], cwd=riscv_dv_dir)
        
        # Find the generated ELF file
        elf_paths = glob.glob(f"{riscv_dv_dir}/out_*/asm_test/{test}_0.o")
        if not elf_paths:
            print(f"Could not find ELF for {test}")
            failed_tests_list.append(1)
            continue
        elf_paths.sort(key=os.path.getmtime, reverse=True)
        elf_path = elf_paths[0]
        
        # Extract tohost
        nm_cmd = [nm_path, elf_path]
        nm_res = subprocess.run(nm_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        tohost_addr = ""
        for line in nm_res.stdout.split('\n'):
            if " tohost" in line:
                tohost_addr = line.split()[0]
                break
        
        if not tohost_addr:
            print(f"Could not find tohost in {elf_path}")
            failed_tests_list.append(1)
            continue
            
        # Convert to hex
        bin_path = elf_path.replace(".o", ".bin")
        hex_path = elf_path.replace(".o", ".hex")
        run_cmd([objcopy_path, "-O", "binary", elf_path, bin_path])
        imem_path = os.path.join(sim_dir, "imem.hex")
        dmem_path = os.path.join(sim_dir, "dmem.hex")
        bin_to_hex(bin_path, imem_path, dmem_path)
        
        # Run simv_uvm
        simv_cmd = ["./simv_uvm", f"+UVM_TESTNAME={test}", f"+tohost_addr={tohost_addr}"]
        print(f"Running simv_uvm for {test}")
        try:
            simv_res = subprocess.run(simv_cmd, cwd=sim_dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True, timeout=120)
            if "UVM_ERROR :    0" in simv_res.stdout and "UVM_FATAL :    0" in simv_res.stdout:
                print(f"{test} PASSED")
            else:
                print(simv_res.stdout)
                print(f"{test} FAILED")
                failed_tests_list.append(1)
        except subprocess.TimeoutExpired as e:
            print(f"{test} TIMED OUT")
            if e.stdout:
                print(e.stdout)
            failed_tests_list.append(1)

if __name__ == '__main__':
    main()

if len(failed_tests_list) > 0:
    print(f'{len(failed_tests_list)} tests failed')
    sys.exit(1)
else:
    print('All tests passed')
