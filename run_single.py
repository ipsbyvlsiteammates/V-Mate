import os, subprocess, struct
import sys
test_name = sys.argv[1] if len(sys.argv) > 1 else 'F-fnmsub.s-08.elf'
elf_path = '/home/guy/Sagi/riscv_processor/riscv-arch-test/work/sagi_rv32imafd/elfs/rv32i/F/' + test_name
try:
    comp = subprocess.run(["vcs", "-sverilog", "-debug_access+all", "-kdb", "-lca", "-timescale=1ns/1ps", "-f", "filelist_arch_test.f", "-o", "simv_arch_test"], cwd="/home/guy/Sagi/riscv_processor/sim", stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
    if comp.returncode != 0:
        with open("/home/guy/Sagi/riscv_processor/sim/sim_stdout.log", "w") as f:
            f.write("COMPILE FAILED\n" + comp.stdout)
        exit(1)
    nm_out = subprocess.check_output(["riscv64-unknown-elf-nm", elf_path]).decode()
    tohost_addr = [line.split()[0] for line in nm_out.splitlines() if " tohost" in line][0]
    tohost_addr = f"{int(tohost_addr, 16) & 0xFFFFFFFF:x}"
    subprocess.run(["riscv64-unknown-elf-objcopy", "-O", "binary", "--set-section-flags", ".bss=alloc,load,contents", elf_path, "sim/full.bin"], cwd="/home/guy/Sagi/riscv_processor", check=True)
    with open("/home/guy/Sagi/riscv_processor/sim/full.bin", "rb") as f:
        full_data = f.read().ljust(524288, b'\x00')
    with open("/home/guy/Sagi/riscv_processor/sim/imem.hex", "w") as f:
        for i in range(0, 524288, 4):
            f.write(f"{struct.unpack('<I', full_data[i:i+4])[0]:08x}\n")
    with open("/home/guy/Sagi/riscv_processor/sim/dmem.hex", "w") as f:
        for i in range(524288):
            f.write(f"{full_data[i]:02x}\n")
    res = subprocess.run(["./simv_arch_test", f"+TOHOST_ADDR={tohost_addr}"], cwd="/home/guy/Sagi/riscv_processor/sim", stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
    with open("/home/guy/Sagi/riscv_processor/sim/sim_stdout.log", "w") as f:
        f.write(res.stdout)
except Exception as e:
    with open("/home/guy/Sagi/riscv_processor/sim/sim_stdout.log", "w") as f:
        f.write(str(e))
    exit(1)
