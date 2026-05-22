import os
import sys
import glob
import subprocess
import struct

def main():
    pattern = sys.argv[1]
    search_path = f"/home/guy/Sagi/riscv_processor/riscv-arch-test/work/sagi_rv32imafd/elfs/**/*{pattern}*.elf"
    elfs = glob.glob(search_path, recursive=True)
    if not elfs:
        print(f"ELF not found for pattern: {pattern}")
        sys.exit(1)
    elf = elfs[0]
    print(f"Found ELF: {elf}")
    
    nm_out = subprocess.check_output(["riscv64-unknown-elf-nm", elf], universal_newlines=True)
    tohost_addr = None
    for line in nm_out.splitlines():
        if " tohost" in line:
            tohost_addr = f"{int(line.split()[0], 16) & 0xFFFFFFFF:x}"
            break
    if not tohost_addr:
        print("tohost not found")
        sys.exit(1)
        
    subprocess.run(["riscv64-unknown-elf-objcopy", "-O", "binary", "--set-section-flags", ".bss=alloc,load,contents", elf, "sim/full.bin"], check=True)
    
    with open("sim/full.bin", "rb") as f:
        full_data = f.read()
    full_data = full_data.ljust(524288, b'\x00')
    
    with open("sim/imem.hex", "w") as f:
        for i in range(0, 524288, 4):
            word = struct.unpack("<I", full_data[i:i+4])[0]
            f.write(f"{word:08x}\n")
            
    with open("sim/dmem.hex", "w") as f:
        for i in range(524288):
            f.write(f"{full_data[i]:02x}\n")
            
    os.chdir("/home/guy/Sagi/riscv_processor/sim")
    sim_cmd = ["./simv_arch_test", f"+TOHOST_ADDR={tohost_addr}"]
    subprocess.run(sim_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    
    with open("trace.log", "r") as f:
        trace = f.readlines()
        
    disasm = subprocess.check_output(["riscv64-unknown-elf-objdump", "-D", elf], universal_newlines=True)
    
    os.chdir("/home/guy/Sagi/riscv_processor")
    with open(f"{pattern}_trace.log", "w") as f:
        f.writelines(trace[-2000:])
    with open(f"{pattern}_disasm.txt", "w") as f:
        f.write(disasm)
        
    print(f"Successfully generated {pattern}_trace.log and {pattern}_disasm.txt")

if __name__ == '__main__':
    main()
