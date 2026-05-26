#!/bin/bash
set -e
cd /home/guy/Sagi/riscv_processor

ELF_FILE="riscv-arch-test/work/sagi_rv32imafd/elfs/F-fadd.s-00.elf"
if [ ! -f "$ELF_FILE" ]; then
    echo "ELF file not found: $ELF_FILE"
    exit 1
fi

TOHOST_ADDR=$(riscv64-unknown-elf-nm $ELF_FILE | grep tohost | awk '{print $1}')
if [ -z "$TOHOST_ADDR" ]; then
    echo "tohost address not found"
    exit 1
fi

riscv64-unknown-elf-objcopy -O binary $ELF_FILE test.bin

python3 << 'EOF'
import sys
with open('test.bin', 'rb') as f:
    data = f.read()
data = data.ljust(512*1024, bytes([0]))
with open('sim/imem.hex', 'w') as f:
    for i in range(0, len(data), 4):
        word = data[i:i+4]
        f.write(f'{int.from_bytes(word, byteorder="little"):08x}\n')
with open('sim/dmem.hex', 'w') as f:
    for i in range(len(data)):
        f.write(f'{data[i]:02x}\n')
EOF

cd sim
./simv_arch_test +TOHOST_ADDR=$TOHOST_ADDR > sim_output.txt 2>&1 || true

tail -n 200 trace.log > trace_tail.log || true
if [ -f FP_TRACE ]; then
    tail -n 200 FP_TRACE > fp_trace_tail.log || true
fi
