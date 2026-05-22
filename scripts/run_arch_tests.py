import os
import subprocess
import glob
import struct
import sys

def main():
    extensions = sys.argv[1] if len(sys.argv) > 1 else "I"
    print(f"Running make to generate ELFs for extensions: {extensions}...")
    os.chdir("/home/guy/Sagi/riscv_processor/riscv-arch-test")
    subprocess.run(["make", "clean"], check=True)
    subprocess.run(["make", "CONFIG_FILES=config/cores/sagi_rv32imafd/test_config.yaml", f"EXTENSIONS={extensions}", "JOBS=8"], check=True)
    os.chdir("/home/guy/Sagi/riscv_processor")

    elfs = glob.glob("/home/guy/Sagi/riscv_processor/riscv-arch-test/work/sagi_rv32imafd/elfs/**/*.elf", recursive=True)
    print(f"Found {len(elfs)} ELFs.")

    passed = 0
    failed = 0

    print("Compiling testbench...")
    os.chdir("/home/guy/Sagi/riscv_processor/sim")
    subprocess.run(["vcs", "-sverilog", "-debug_access+all", "-kdb", "-lca", "-timescale=1ns/1ps", "-f", "filelist_arch_test.f", "-o", "simv_arch_test"], check=True)
    os.chdir("/home/guy/Sagi/riscv_processor")

    for elf in elfs:
        print(f"Running {os.path.basename(elf)}...")
        nm_out = subprocess.check_output(["riscv64-unknown-elf-nm", elf]).decode()
        tohost_addr = None
        for line in nm_out.splitlines():
            if " tohost" in line:
                tohost_addr = f"{int(line.split()[0], 16) & 0xFFFFFFFF:x}"
                break
        if not tohost_addr:
            print("  tohost not found!")
            failed += 1
            continue

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
        result = subprocess.run(sim_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        os.chdir("/home/guy/Sagi/riscv_processor")

        if "TEST PASSED" in result.stdout:
            print("  PASSED")
            passed += 1
        else:
            print("  FAILED")
            failed += 1

    print(f"Summary: {passed} passed, {failed} failed.")
    if failed > 0:
        sys.exit(1)

if __name__ == "__main__":
    main()
