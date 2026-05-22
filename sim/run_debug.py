import os, sys, subprocess, struct
elf = sys.argv[1]
nm_out = subprocess.check_output(['riscv64-unknown-elf-nm', elf]).decode()
tohost_addr = None
for line in nm_out.splitlines():
    if ' tohost' in line:
        tohost_addr = f"{int(line.split()[0], 16) & 0xFFFFFFFF:x}"
        break
subprocess.run(['riscv64-unknown-elf-objcopy', '-O', 'binary', '--set-section-flags', '.bss=alloc,load,contents', elf, 'full.bin'], check=True)
with open('full.bin', 'rb') as f: full_data = f.read()
full_data = full_data.ljust(524288, b'\x00')
with open('imem.hex', 'w') as f:
    for i in range(0, 524288, 4):
        f.write(f"{struct.unpack('<I', full_data[i:i+4])[0]:08x}\n")
with open('dmem.hex', 'w') as f:
    for i in range(524288):
        f.write(f"{full_data[i]:02x}\n")
res = subprocess.run(['./simv_arch_test', f'+TOHOST_ADDR={tohost_addr}'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
print(res.stdout)