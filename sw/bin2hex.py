#!/usr/bin/env python3
# Usage: bin2hex.py program.bin program.hex
# One 32-bit hex word per line, word 0 first - matches imem.v's
# word-indexed mem[] array directly via $readmemh (no @address directives
# needed, since the array already starts at index 0).

import sys

def main():
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} <input.bin> <output.hex>")
        sys.exit(1)

    with open(sys.argv[1], "rb") as f:
        data = f.read()

    # Pad to a multiple of 4 bytes in case the binary isn't word-aligned
    if len(data) % 4 != 0:
        data += b"\x00" * (4 - (len(data) % 4))

    with open(sys.argv[2], "w") as out:
        for i in range(0, len(data), 4):
            word = data[i:i+4]
            # little-endian: data[i] is the least significant byte
            value = word[0] | (word[1] << 8) | (word[2] << 16) | (word[3] << 24)
            out.write(f"{value:08x}\n")

    print(f"wrote {len(data)//4} words to {sys.argv[2]}")

if __name__ == "__main__":
    main()
