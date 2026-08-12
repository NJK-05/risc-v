# RV32I Pipelined RISC-V Core — Project Context

Last updated: after M1 completion (single-cycle datapath verified)

## 1. Project overview

Building a 5-stage pipelined RV32I RISC-V core in Verilog, developed and simulated
on Ubuntu 22.04 using Vivado (xsim) as the primary simulator. No FPGA is used —
verification is entirely through self-checking testbenches, and the end goal
includes carrying the design through synthesis (Vivado) and a full RTL-to-GDSII
flow via OpenLane on the open-source SKY130 PDK.

Full architecture spec (pipeline stage breakdown, hazard strategy, module list,
milestone list) lives in `docs/riscv_pipeline_spec.md` — this file tracks
**progress and decisions made so far**; that one is the original design plan.

## 2. Folder structure

```
riscv_pipelined_core/
├── rtl/          — all design source modules
├── tb/           — one testbench per module
├── sw/           — (not started) C test programs for later verification
├── sim/          — simulator output, gitignored
├── docs/
│   ├── riscv_pipeline_spec.md     — original architecture spec
│   └── project_context.md         — this file
└── vivado/       — Vivado project files live here only (gitignored)
```

## 3. Toolchain

- **Vivado (xsim)** — used for all RTL simulation so far. Vivado ignores the
  `$dumpfile`/`$dumpvars` lines in testbenches (Icarus-style VCD dumping) and
  uses its own native waveform viewer instead — this is expected, not a bug.
- **`gcc-riscv64-unknown-elf`** — installed, not yet used. Needed at M6 (real C
  program verification).
- **Icarus Verilog** — deliberately NOT installed on the user's machine (Vivado
  covers simulation). All modules below were verified in a sandboxed Icarus
  environment during development as a correctness check before being handed
  over, but the user's own verification loop is Vivado-only.
- **Docker + OpenLane** — not installed yet. Deferred until M8 (GDSII stage) to
  avoid an unused, potentially-stale install sitting around.

## 4. Modules completed and verified

All modules below have a corresponding testbench in `tb/`, and all currently
pass 100% of their checks in the user's own Vivado (xsim) environment.

| Module | Purpose | Status |
|---|---|---|
| `regfile.v` | 32×32 register file, x0 hardwired to zero | ✅ Verified (5/5 checks) |
| `alu.v` | ALU supporting all RV32I arithmetic/logic/compare ops | ✅ Verified (13/13 checks) |
| `imm_gen.v` | Immediate generator for I/S/B/U/J instruction formats | ✅ Verified (6/6 checks) |
| `alu_control.v` | Decodes ALUOp + funct3/funct7 into ALU operation select | ✅ Verified (13/13 checks) |
| `control_unit.v` | Main decoder: opcode → all datapath control signals | ✅ Verified (27/27 checks) |
| `pc_reg.v` | Program counter register, async reset | ✅ Verified (as part of core_top) |
| `imem.v` | Instruction memory (sim model, word-addressable) | ✅ Verified (as part of core_top) |
| `dmem.v` | Data memory (sim model, byte-addressable, handles all load/store sizes + sign extension) | ✅ Verified (as part of core_top) |
| `riscv_core_top.v` | **M1 milestone** — full single-cycle datapath integrating all modules above | ✅ Verified (6/6 checks, real instruction sequence) |

**M1 test program** (in `tb_core_top.v`) exercises ADDI, ADD, SW, LW, and a taken
BEQ branch that correctly skips an instruction — confirms the full fetch →
decode → execute → memory → write-back path works correctly for a real,
non-trivial instruction sequence, including a live control-flow change.

## 5. Key design decisions made so far

These are worth remembering for the eventual project writeup / interview
explanations, since they're not arbitrary:

- **`alu_src_a` is 2-bit (rs1 / PC / zero)**, not a simple 1-bit mux. This lets
  LUI and AUIPC reuse the existing ALU ADD path (`0 + imm` for LUI, `PC + imm`
  for AUIPC) instead of needing dedicated hardware for each.
- **Branch/jump target addresses are computed by a separate adder
  (`branch_target = pc + imm`) in `riscv_core_top.v`, not through the main ALU.**
  This is because branches need both a comparison (rs1 vs rs2, via the ALU) and
  a target address (PC + imm) in the same cycle — one ALU can't do both at once.
- **Load/store size (`funct3`) is passed directly into `dmem.v`**, bypassing
  `control_unit.v` entirely, since the size is already fully determined by
  funct3 and doesn't need to be re-encoded as a separate control signal.
- **All state updates (PC, register file, data memory) commit on the same
  clock edge**, using values computed combinationally during the current
  cycle — the standard single-cycle datapath pattern. This works cleanly at
  M1 because only one instruction is ever "in flight," so there's no
  same-cycle hazard to worry about yet.
- **The `default` case in `control_unit.v` is a silent NOP**, not an
  exception/trap. Documented as a known simplification — real hardware would
  trap on an illegal opcode.

## 6. Milestone progress (from the original spec)

| Milestone | Status |
|---|---|
| M1 — Single-cycle datapath working | ✅ Done |
| M2 — Pipeline registers added (no hazard handling yet) | ⬜ Next up |
| M3 — Forwarding unit added | ⬜ Not started |
| M4 — Load-use stall added | ⬜ Not started |
| M5 — Branch/jump flush logic added | ⬜ Not started |
| M6 — Real compiled C program runs correctly | ⬜ Not started |
| M7 — Vivado synthesis + timing report | ⬜ Not started |
| M8 — OpenLane → GDSII on SKY130 | ⬜ Not started |

## 7. Immediate next step (M2)

Split the single-cycle datapath into 5 pipeline stages (IF, ID, EX, MEM, WB) by
inserting pipeline registers between them:

- `if_id_reg.v` — {instruction, PC, PC+4}
- `id_ex_reg.v` — {control signals, rs1_data, rs2_data, imm, rs1_addr, rs2_addr, rd_addr}
- `ex_mem_reg.v` — {ALU result, rs2_data, rd_addr, control signals, branch target/taken}
- `mem_wb_reg.v` — {memory read data, ALU result, rd_addr, control signals}

At M2, deliberately **no hazard handling yet** — dependent instructions will
produce wrong results if placed back-to-back. Verification at this stage means
manually inserting NOPs between dependent instructions and confirming
instructions correctly flow through all 5 stages with the right latency.
Forwarding (M3), stalling (M4), and flushing (M5) get added afterward, each
independently testable against a targeted hazard scenario.

## 8. Resume framing (current stage)

> **5-Stage Pipelined RV32I RISC-V Core | Verilog, Vivado, RISC-V GCC**
> Designing and verifying a pipelined RV32I processor core from scratch in
> Verilog, implementing data forwarding, hazard detection, and control-flow
> flushing; verified with self-checking testbenches and moving toward
> synthesis and ASIC layout via the OpenLane/SKY130 open-source flow.

Update to the "completed" framing (naming OpenLane/SKY130 explicitly) once M7
and M8 are done — see `docs/riscv_pipeline_spec.md` §nothing needed, just
swap the wording as discussed previously in the project chat.
