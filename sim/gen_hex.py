import sys
import struct

with open('test.bin', 'rb') as f:
    data = bytearray(f.read())

target_size = 512 * 1024
if len(data) < target_size:
    data.extend(b'\x00' * (target_size - len(data)))
else:
    data = data[:target_size]

imem_data = data[:256*1024]
dmem_data = data[256*1024:]

with open('imem.hex', 'w') as f:
    for i in range(0, len(imem_data), 4):
        word = struct.unpack('<I', imem_data[i:i+4])[0]
        f.write(f'{word:08x}\n')

with open('dmem.hex', 'w') as f:
    for b in dmem_data:
        f.write(f'{b:02x}\n')
