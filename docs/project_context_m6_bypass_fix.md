## M6 follow-up — WB→ID register bypass (bug found during C-program bring-up)

Status: ✅ Fixed and verified in simulation against the real compiled `main.c`. Re-run the M6 testbench in Vivado to confirm on your side.

### Symptom

First real run of the compiled C program in Vivado: all four M6 checks failed (`errors = 4`), the byte array was `XX` everywhere except one 4-byte write at address 10 (`mem[10..13]`) instead of the expected result at `0x100`.

### Root cause

A coverage gap in the M3 forwarding design, not an M6 or toolchain problem. Forwarding only serves an instruction that is already in EX, i.e. a producer 1 or 2 instructions ahead (EX/MEM, MEM/WB). A producer exactly 3 instructions ahead is in WB while the consumer is in ID: the regfile only updates on the clock edge, so the consumer reads the old value, and EX-stage forwarding is too late to help.

The load-use stall opens the same hole a second way. The 1-cycle bubble delays the stalled consumer, so an older producer that was at distance 2 retires through WB before the consumer reaches EX, and is no longer visible to forwarding.

In the compiled program: `addi s0,sp,32` followed three instructions later by `sw zero,-20(s0)` read `s0 = 0` (store went to `0xFFFFFFEC`); and the final `lw a5,-28(s0)` / `lw a4,-20(s0)` / `sw a4,0(a5)` sequence read a stale `a5 = 10` after the stall, writing to address 10.

### Why M2–M5 didn't catch it

None of those testbenches placed a consumer exactly 3 instructions after its producer, and none combined a load-use stall with a second, older producer. The tests passed because they never exercised the gap, not because the gap wasn't there.

### Fix

`riscv_core_top.v`: the regfile outputs are renamed `rs1_data_rf`/`rs2_data_rf`, and `rs1_data_id`/`rs2_data_id` now select `write_back_data` instead when `mem_wb_reg_write` is set and `mem_wb_rd_addr` (non-zero) matches the ID-stage source register. Done in the top module, so `regfile.v` is untouched. This covers both cases above: in each, the producer is in WB during the consumer's final ID cycle.

### Verification

- New `tb/tb_core_top_hazards.v`: sweeps producer→consumer distance 1–4 for both ALU and load producers, plus a load-use stall with an older producer on the other operand (9 checks). Against the pre-fix design it failed exactly 3 cases (ALU distance 3, load distance 3, stall + older producer); after the fix all 9 pass.
- Real compiled `main.c` (RV32I, `-O0`) run through the fixed pipeline: stores step through sum values `0x2d` → `0x37`, final store lands at `0x100` with `0x37` (55), result bytes `37 00 00 00`.
- Full regression: `tb_core_top_m2` … `m6` all pass against the fixed top.

Caveat: the pipeline-level reproduction used my own behavioral models for `alu`, `alu_control`, `imm_gen` and `dmem` (written to RV32I semantics), plus your real `control_unit.v`/`imem.v`. The bug lives in the top-level hazard logic, which is your real code under test, but the final confirmation is the M6 testbench in your own Vivado run.

### Lessons worth keeping

- Systematic sweeps over the parameter that matters (here: producer→consumer distance) find gaps that a handful of hand-picked cases miss. M3's tests used distances 1, 2, and 4, and the missing case was 3.
- Hazard fixes interact: the load-use stall changed the effective distance for other operands, which a per-hazard test wouldn't reveal. Test hazards in combination, not only individually.
- A real compiled program is a far better stress test than hand-written snippets — compilers emit exactly the dependency patterns humans don't think to write.
