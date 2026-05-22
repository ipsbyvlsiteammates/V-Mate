import sys
with open("full.bin", "rb") as f:
    data = f.read()
data = data.ljust(524288, b'\x00')
imem_data = data[:262144]
dmem_data = data[262144:]
with open("imem.hex", "w") as f:
    for i in range(0, len(imem_data), 4):
        word = int.from_bytes(imem_data[i:i+4], byteorder='little')
        f.write(f"{word:08x}\n")
with open("dmem.hex", "w") as f:
    for b in dmem_data:
        f.write(f"{b:02x}\n")
