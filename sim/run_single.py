import os
import sys
import subprocess

elf = '/home/guy/Sagi/riscv_processor/riscv-arch-test/work/sagi_rv32imafd/elfs/rv32i/D/D-fadd.d-00.elf'
sim_dir = '/home/guy/Sagi/riscv_processor/sim'

nm_out = subprocess.check_output(['riscv64-unknown-elf-nm', elf]).decode()
tohost = ''
for line in nm_out.splitlines():
    if line.endswith(' tohost'):
        tohost = line.split()[0]
        break

tohost_hex = f"{int(tohost, 16) & 0xFFFFFFFF:x}"

subprocess.check_call(['riscv64-unknown-elf-objcopy', '-O', 'binary', elf, f'{sim_dir}/full.bin'])

with open(f'{sim_dir}/full.bin', 'rb') as f:
    data = f.read()

data = data.ljust(524288, b'\x00')[:524288]
imem_data = data[:262144]
dmem_data = data[262144:]

with open(f'{sim_dir}/imem.hex', 'w') as f:
    for i in range(0, len(imem_data), 4):
        word = imem_data[i:i+4]
        f.write(f"{word[3]:02x}{word[2]:02x}{word[1]:02x}{word[0]:02x}\n")

with open(f'{sim_dir}/dmem.hex', 'w') as f:
    for b in dmem_data:
        f.write(f"{b:02x}\n")

os.chdir(sim_dir)
subprocess.check_call(['vcs', '-sverilog', '-debug_access+all', '-kdb', '-lca', '-timescale=1ns/1ps', '-f', 'filelist_arch_test.f', '-o', 'simv_arch_test'])
subprocess.run(['./simv_arch_test', f'+TOHOST_ADDR={tohost_hex}'])
