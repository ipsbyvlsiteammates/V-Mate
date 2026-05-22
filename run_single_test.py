import sys
import os
import subprocess
import struct

if len(sys.argv) != 3:
    print("Usage: run_single_test.py <elf_path> <out_prefix>")
    sys.exit(1)

elf_path = sys.argv[1]
out_prefix = sys.argv[2]

try:
    nm_out = subprocess.check_output(f"riscv64-unknown-elf-nm {elf_path} | grep tohost", shell=True).decode()
    tohost_addr = nm_out.split()[0]
except Exception as e:
    print(f"Error extracting tohost: {e}")
    sys.exit(1)

try:
    subprocess.check_call(f"riscv64-unknown-elf-objcopy -O binary {elf_path} {out_prefix}.bin", shell=True)
except Exception as e:
    print(f"Error objcopy: {e}")
    sys.exit(1)

with open(f"{out_prefix}.bin", "rb") as f:
    data = f.read()
if len(data) < 512 * 1024:
    data += b'\x00' * (512 * 1024 - len(data))

imem = []
dmem = []
for i in range(0, len(data), 8):
    if i + 8 <= len(data):
        chunk = data[i:i+8]
        val1, val2 = struct.unpack("<II", chunk)
        imem.append(f"{val1:08x}")
        dmem.append(f"{val2:08x}")

with open("imem.hex", "w") as f:
    f.write("\n".join(imem))
with open("dmem.hex", "w") as f:
    f.write("\n".join(dmem))

try:
    subprocess.check_call(f"./simv_arch_test +TOHOST_ADDR={tohost_addr}", shell=True)
except Exception as e:
    print(f"Error running simv_arch_test: {e}")

try:
    subprocess.check_call(f"tail -n 300 trace.log > {out_prefix}_trace.txt", shell=True)
except Exception as e:
    print(f"Error tailing trace: {e}")

try:
    subprocess.check_call(f"riscv64-unknown-elf-objdump -D {elf_path} > {out_prefix}_disasm.txt", shell=True)
except Exception as e:
    print(f"Error objdump: {e}")
