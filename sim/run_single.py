import os
import sys
import subprocess

elf = sys.argv[1]
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
data = data.ljust(524288, b'\x00')

with open(f'{sim_dir}/imem.hex', 'w') as f:
    for i in range(0, len(data), 4):
        word = data[i:i+4].ljust(4, b'\x00')
        f.write(f"{word[3]:02x}{word[2]:02x}{word[1]:02x}{word[0]:02x}\n")

with open(f'{sim_dir}/dmem.hex', 'w') as f:
    for i in range(len(data)):
        f.write(f"{data[i]:02x}\n")
os.chdir(sim_dir)
subprocess.check_call(['vcs', '-sverilog', '-debug_access+all', '-kdb', '-lca', '-timescale=1ns/1ps', '-f', 'filelist_arch_test.f', '-o', 'simv_arch_test'])
subprocess.run(['./simv_arch_test', f'+TOHOST_ADDR={tohost_hex}'])
