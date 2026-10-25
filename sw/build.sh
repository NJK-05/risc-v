#!/bin/bash
# Run this from inside sw/. Requires gcc-riscv64-unknown-elf (already
# installed per the project toolchain).
set -e

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 \
    -nostdlib -nostartfiles -O0 \
    -T link.ld -o program.elf start.s main.c

riscv64-unknown-elf-objcopy -O binary program.elf program.bin

python3 bin2hex.py program.bin program.hex

echo "Done. Load program.hex into imem via \$readmemh in your testbench."
