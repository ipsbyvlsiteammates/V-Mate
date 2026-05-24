import os
import subprocess
import sys
import re
import struct

os.chdir('/home/guy/Sagi/riscv_processor/sim')

print("Running compile_uvm.sh...")
res = subprocess.run(['bash', './compile_uvm.sh'])
if res.returncode != 0:
    sys.exit(res.returncode)

print("Extracting tohost address...")
obj_file = '/home/guy/Sagi/riscv_processor/riscv-dv/out_2026-05-24/asm_test/riscv_arithmetic_basic_test_0.o'
res = subprocess.run(['riscv64-unknown-elf-nm', obj_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
if res.returncode != 0:
    print("nm failed")
    sys.exit(res.returncode)

match = re.search(r'^([0-9a-fA-F]+)\s+[A-Za-z]\s+tohost', res.stdout, re.MULTILINE)
if match:
    tohost_addr = match.group(1)
else:
    tohost_addr = None

if not tohost_addr:
    print("tohost not found")
    sys.exit(1)

print(f"tohost address: {tohost_addr}")

print("Converting to binary...")
res = subprocess.run(['riscv64-unknown-elf-objcopy', '-O', 'binary', obj_file, 'full.bin'])
if res.returncode != 0:
    print("objcopy failed")
    sys.exit(res.returncode)

print("Reading full.bin and padding...")
with open('full.bin', 'rb') as f:
    data = f.read()

data = data.ljust(524288, b'\x00')

print("Writing imem.hex and dmem.hex...")
with open('imem.hex', 'w') as f_imem:
    for i in range(0, len(data), 4):
        word = data[i:i+4]
        if len(word) < 4:
            word = word.ljust(4, b'\x00')
        val = struct.unpack('<I', word)[0]
        f_imem.write(f"{val:08x}\n")

with open('dmem.hex', 'w') as f_dmem:
    for i in range(len(data)):
        f_dmem.write(f"{data[i]:02x}\n")
print("Running simv_uvm...")
res = subprocess.run(['./simv_uvm', '+UVM_TESTNAME=riscv_fp_test', f'+TOHOST_ADDR={tohost_addr}', '-cm', 'line+cond+fsm+tgl+branch+assert'])
subprocess.run(['urg', '-dir', 'simv_uvm.vdb', '-format', 'text', '-report', 'urgReport'])
sys.exit(res.returncode)
