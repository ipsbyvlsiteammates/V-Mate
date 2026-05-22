import sys
import os
import glob
import subprocess

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 run_single_test.py <test_name>")
        sys.exit(1)
    
    test_name = sys.argv[1]
    work_dir = "/home/guy/Sagi/riscv_processor/riscv-arch-test/work/"
    
    # Find ELF
    elf_files = glob.glob(f"{work_dir}/**/{test_name}", recursive=True)
    if not elf_files:
        print(f"ELF file {test_name} not found in {work_dir}")
        sys.exit(1)
    elf_file = elf_files[0]
    
    # Extract tohost
    nm_out = subprocess.check_output(f"riscv64-unknown-elf-nm {elf_file}", shell=True, universal_newlines=True)
    tohost = None
    for line in nm_out.splitlines():
        if " tohost" in line:
            tohost = line.split()[0]
            break
    if not tohost:
        print("tohost not found")
        sys.exit(1)
        
    # Generate full.bin
    subprocess.check_call(f"riscv64-unknown-elf-objcopy -O binary --set-section-flags .bss=alloc,load,contents {elf_file} full.bin", shell=True)
    
    # Pad and split
    with open("full.bin", "rb") as f:
        data = f.read()
    
    data = data.ljust(512 * 1024, b'\x00')
    
    with open("imem.hex", "w") as f_imem, open("dmem.hex", "w") as f_dmem:
        for i in range(0, len(data), 4):
            word = data[i:i+4]
            # imem: 32-bit words, little-endian
            val = int.from_bytes(word, 'little')
            f_imem.write(f"{val:08x}\n")
            
        for i in range(len(data)):
            f_dmem.write(f"{data[i]:02x}\n")
            
    # Remove trace.log
    if os.path.exists("trace.log"):
        os.remove("trace.log")
        
    # Run sim
    subprocess.call(f"./simv_arch_test +TOHOST_ADDR={tohost}", shell=True)
    
    # Read trace.log
    if os.path.exists("trace.log"):
        with open("trace.log", "r") as f:
            lines = f.readlines()
            print("--- TRACE START ---")
            for line in lines[:100]:
                print(line, end='')
            print("--- TRACE MIDDLE OMITTED ---")
            for line in lines[-100:]:
                print(line, end='')
            print("--- TRACE END ---")
    else:
        print("trace.log not found")

if __name__ == "__main__":
    main()
