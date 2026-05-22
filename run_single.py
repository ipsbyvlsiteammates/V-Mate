import sys
import os
import subprocess

def main():
    elf_path = sys.argv[1]
    if not os.path.exists(elf_path):
        print(f"Error: ELF file does not exist: {elf_path}")
        sys.exit(1)
        
    nm_cmd = "riscv64-unknown-elf-nm"
    objcopy_cmd = "riscv64-unknown-elf-objcopy"
    
    result = subprocess.run(['bash', '-l', '-c', f"{nm_cmd} {elf_path}"], capture_output=True, text=True)
    if result.returncode != 0:
        nm_cmd = "riscv32-unknown-elf-nm"
        objcopy_cmd = "riscv32-unknown-elf-objcopy"
        result = subprocess.run(['bash', '-l', '-c', f"{nm_cmd} {elf_path}"], capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Both nm commands failed.")
            print(f"Last stderr: {result.stderr}")
            print(f"Last stdout: {result.stdout}")
            sys.exit(1)
            
    out = result.stdout
    tohost = ""
    for line in out.splitlines():
        if "tohost" in line:
            tohost = line.split()[0]
            break
            
    if not tohost:
        print("tohost not found")
        sys.exit(1)
        
    result = subprocess.run(['bash', '-l', '-c', f"{objcopy_cmd} -O binary {elf_path} sim/full.bin"], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"objcopy failed: {result.stderr}")
        sys.exit(1)
    
    with open("sim/full.bin", "rb") as f:
        data = f.read()
    if len(data) < 524288:
        data += b'\x00' * (524288 - len(data))
    with open("sim/full.bin", "wb") as f:
        f.write(data)
        
    words = []
    for i in range(0, len(data), 4):
        word = data[i:i+4]
        words.append(f"{int.from_bytes(word, 'little'):08x}")
        
    with open("sim/imem.hex", "w") as f:
        f.write("\n".join(words) + "\n")
    with open("sim/dmem.hex", "w") as f:
        f.write("\n".join(words) + "\n")
        
    os.chdir("sim")
    if os.path.exists("trace.log"):
        os.remove("trace.log")
    result = subprocess.run(['bash', '-l', '-c', f"./simv_arch_test +TOHOST_ADDR={tohost} > run.log 2>&1"], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"simv_arch_test returned {result.returncode}")

if __name__ == '__main__':
    main()
