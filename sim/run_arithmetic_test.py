import os
import subprocess
import sys
import struct
import glob
import shutil
import re

dv_dir = '/home/guy/Sagi/riscv_processor/riscv-dv'
sim_dir = '/home/guy/Sagi/riscv_processor/sim'
test = 'riscv_arithmetic_basic_test'

os.chdir(dv_dir)
env = os.environ.copy()
env['RISCV_GCC'] = subprocess.check_output(['which', 'riscv64-unknown-elf-gcc']).decode().strip()
env['RISCV_OBJCOPY'] = subprocess.check_output(['which', 'riscv64-unknown-elf-objcopy']).decode().strip()
env['SPIKE_PATH'] = '/home/guy/Sagi/riscv_processor/spike_install/bin'
env['PATH'] = '/home/guy/Sagi/riscv_processor/dtc_install/bin:' + env['PATH']

python_exe = os.path.join(dv_dir, '.venv/bin/python3')

if os.path.exists('out_single'):
    shutil.rmtree('out_single')

print(f"Running riscv-dv for {test}...")
cmd = [
    python_exe, 'run.py',
    '--target', 'rv32imafdc',
    '--isa', 'rv32imafd',
    '--mabi', 'ilp32d',
    '--test', test,
    '--iterations', '1',
    '-o', 'out_single',
    '--steps', 'gen,gcc_compile',
    '--gcc_opts=-mno-relax -march=rv32imafd_zifencei'
]
res = subprocess.run(cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
if res.returncode != 0:
    print(f"Failed to generate {test}")
    print(res.stderr)
    sys.exit(1)

os.chdir(sim_dir)
o_files = glob.glob(os.path.join(dv_dir, 'out_single/asm_test/*.o'))
if not o_files:
    print("No object files found.")
    sys.exit(1)

obj_file = o_files[0]
elf_file = obj_file

res = subprocess.run(['riscv64-unknown-elf-nm', obj_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
tohost_addr = None
for line in res.stdout.splitlines():
    parts = line.split()
    if len(parts) >= 3 and parts[-1] == 'tohost':
        tohost_addr = parts[0]
        break

if not tohost_addr:
    print("tohost not found")
    sys.exit(1)

res = subprocess.run(['riscv64-unknown-elf-objcopy', '-O', 'binary', elf_file, 'full.bin'])
if res.returncode != 0:
    print("objcopy failed")
    sys.exit(1)

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

print(f"Running simulation for {test}...")
res = subprocess.run([
    './simv_uvm',
    '+UVM_TESTNAME=riscv_test',
    f'+TOHOST_ADDR={tohost_addr}',
    '-cm', 'line+cond+fsm+tgl+branch+assert',
    '-cm_name', test
], stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)

print(res.stdout)
if res.returncode != 0 or 'TEST FAILED' in res.stdout or 'TEST TIMEOUT' in res.stdout or re.search(r'UVM_ERROR\\s*:\\s*[1-9]', res.stdout) or re.search(r'UVM_FATAL\\s*:\\s*[1-9]', res.stdout):
    print(f"Simulation failed (rc={res.returncode})")
    sys.exit(1)
else:
    print("Simulation passed")
    sys.exit(0)
