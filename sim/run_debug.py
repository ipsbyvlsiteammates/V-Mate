import os
import subprocess
import struct

os.chdir('/home/guy/Sagi/riscv_processor/sim')
tests = ["riscv_floating_point_arithmetic_test_0", "riscv_amo_test_0"]

for test in tests:
    o_file = f"../riscv-dv/out_regression/asm_test/{test}.o"
    if not os.path.exists(o_file):
        print(f"File not found: {o_file}")
        continue
    
    try:
        nm_out = subprocess.check_output(f"riscv64-unknown-elf-nm {o_file} | grep tohost", shell=True).decode()
        tohost_addr = nm_out.split()[0]
    except Exception as e:
        print(f"Failed to find tohost for {test}: {e}")
        continue
        
    try:
        subprocess.check_call(f"riscv64-unknown-elf-objcopy -O binary {o_file} full.bin", shell=True)
    except Exception as e:
        print(f"Failed to objcopy {test}: {e}")
        continue
        
    with open("full.bin", "rb") as f:
        data = f.read()
        
    data = data.ljust(524288, b'\x00')
    
    with open("imem.hex", "w") as f:
        for i in range(0, len(data), 4):
            word = struct.unpack("<I", data[i:i+4])[0]
            f.write(f"{word:08x}\n")
            
    with open("dmem.hex", "w") as f:
        for i in range(len(data)):
            f.write(f"{data[i]:02x}\n")
            
    cmd = f"./simv_uvm +UVM_TESTNAME=riscv_test +TOHOST_ADDR={tohost_addr}"
    print(f"Running: {cmd}")
    with open(f"{test}_debug.log", "w") as log_f:
        subprocess.call(cmd, shell=True, stdout=log_f, stderr=subprocess.STDOUT)

