import sys
import struct

def main():
    try:
        with open('sim/full.bin', 'rb') as f:
            data = f.read()
    except FileNotFoundError:
        print("sim/full.bin not found")
        sys.exit(1)
        
    pad_len = 524288 - len(data)
    if pad_len > 0:
        data += b'\x00' * pad_len
    else:
        data = data[:524288]
        
    with open('sim/imem.hex', 'w') as f:
        for i in range(0, len(data), 4):
            word = struct.unpack('<I', data[i:i+4])[0]
            f.write(f"{word:08x}\n")
            
    with open('sim/dmem.hex', 'w') as f:
        for i in range(len(data)):
            f.write(f"{data[i]:02x}\n")

if __name__ == '__main__':
    main()
