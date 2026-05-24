import struct
with open('full.bin', 'rb') as f:
    data = f.read()
data = data.ljust(524288, b'\x00')
with open('imem.hex', 'w') as f_imem, open('dmem.hex', 'w') as f_dmem:
    for i in range(0, len(data), 4):
        word = data[i:i+4]
        if len(word) < 4:
            word = word.ljust(4, b'\x00')
        val = struct.unpack('<I', word)[0]
        f_imem.write(f"{val:08x}\n")
    for i in range(len(data)):
        f_dmem.write(f"{data[i]:02x}\n")
