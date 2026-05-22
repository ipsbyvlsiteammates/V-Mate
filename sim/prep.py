with open('sim/full.bin', 'rb') as f:
    data = f.read()
data = data.ljust(524288, b'\x00')
with open('sim/imem.hex', 'w') as f:
    for i in range(0, len(data), 4):
        word = data[i:i+4]
        f.write(f"{int.from_bytes(word, 'little'):08x}\n")
with open('sim/dmem.hex', 'w') as f:
    for i in range(len(data)):
        f.write(f"{data[i]:02x}\n")
