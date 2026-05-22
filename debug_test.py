import os
import subprocess
import struct

elf_path = '/home/guy/Sagi/riscv_processor/riscv-arch-test/work/sagi_rv32imafd/elfs/rv32i/I/I-add-00.elf'
nm_out = subprocess.check_output(['riscv64-unknown-elf-nm', elf_path]).decode()
tohost_addr = None
for line in nm_out.splitlines():
    if ' tohost' in line:
        tohost_addr = line.split()[0]
        break

subprocess.run(['riscv64-unknown-elf-objcopy', '-O', 'binary', '--set-section-flags', '.bss=alloc,load,contents', elf_path, '/home/guy/Sagi/riscv_processor/sim/full.bin'], check=True)

with open('/home/guy/Sagi/riscv_processor/sim/full.bin', 'rb') as f:
    full_data = f.read()

full_data = full_data.ljust(524288, b'\x00')
imem_data = full_data[0:262144]
dmem_data = full_data[262144:524288]

with open('/home/guy/Sagi/riscv_processor/sim/imem.hex', 'w') as f:
    for i in range(0, 262144, 4):
        word = struct.unpack('<I', imem_data[i:i+4])[0]
        f.write(f'{word:08x}\n')

with open('/home/guy/Sagi/riscv_processor/sim/dmem.hex', 'w') as f:
    for i in range(262144):
        f.write(f'{dmem_data[i]:02x}\n')

os.chdir('/home/guy/Sagi/riscv_processor/sim')
sim_cmd = ['./simv_arch_test', f'+TOHOST_ADDR={tohost_addr}']
print('=== TOHOST ===')
print(tohost_addr)
try:
    res = subprocess.run(sim_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, timeout=15)
    print('=== STDOUT ===')
    print(res.stdout)
    print('=== STDERR ===')
    print(res.stderr)
except subprocess.TimeoutExpired as e:
    print('=== TIMEOUT ===')
    if e.stdout: print(e.stdout)
    if e.stderr: print(e.stderr)
