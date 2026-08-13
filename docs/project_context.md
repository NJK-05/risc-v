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

## M2 — Pipeline registers added (no hazard handling yet)

Status: ✅ Done. Update the milestone table (§6) and mark M3 as next up.

### Modules added

| Module | Purpose |
|---|---|
| `if_id_reg.v` | Latches {PC, PC+4, instruction} between IF and ID |
| `id_ex_reg.v` | Latches {control signals, rs1_data, rs2_data, imm, rs1_addr, rs2_addr, rd_addr, funct3, funct7_5} between ID and EX |
| `ex_mem_reg.v` | Latches {ALU result, rs2_data, rd_addr, control signals, branch_target, branch_taken, pc_plus4, funct3} between EX and MEM |
| `mem_wb_reg.v` | Latches {mem read data, ALU result, pc_plus4, rd_addr, control signals} between MEM and WB |

`riscv_core_top.v` was rewritten from the M1 single-cycle datapath to the 5-stage pipelined version, wired through all four registers above. The M1 version is preserved in git history (see below) rather than kept as a separate file in `rtl/`.

### Design decisions made during M2

- **Every pipeline register exposes `stall`/`flush` ports now**, tied to `1'b0` in `riscv_core_top.v` for M2. This is so M3 (forwarding — doesn't need these), M4 (load-use stall), and M5 (branch/jump flush) can wire up real logic without touching the register modules again.
- **Branch/jump resolution happens in EX**, not ID. `branch_target = id_ex_pc + id_ex_imm` (shared by branches and JAL); JALR uses the ALU result with the LSB cleared instead. This mirrors the field list already decided for `ex_mem_reg.v` (which carries `branch_target`/`branch_taken` forward).
- **JAL vs. JALR is distinguished without adding an opcode field to the pipeline registers.** `control_unit.v` already sets `alu_src=0` for JAL and `alu_src=1` for JALR, so `jump & ~alu_src` / `jump & alu_src` does it for free.
- **On reset or flush, control signals clear to the same all-zero state `control_unit.v`'s default case already treats as a safe NOP** — so a squashed/reset pipeline stage behaves identically to a real decoded NOP flowing through.

### Known, deliberate M2 limitations

These are expected at this stage, not bugs — each is addressed by a later milestone:

- **No forwarding (M3).** A dependent instruction placed immediately after its producer reads a stale regfile value. Verified around this for now by manually inserting NOPs (minimum safe gap: 3 NOPs / 4-instruction spacing between producer and consumer, given the 4-cycle IF→WB latency).
- **No load-use stall (M4).** Same underlying issue as above, specific to loads.
- **No branch/jump flush (M5).** EX-stage resolution *does* correctly redirect the PC on a taken branch/jump, but the two instructions already fetched into `if_id_reg`/`id_ex_reg` at that point are not squashed — they continue down the pipeline and may incorrectly execute. Avoid testing taken branches/jumps until M5. The M2 testbench deliberately excludes them for this reason.

### Testbench

`tb/tb_core_top_m2.v` (module name `tb_core_top_m2`, to avoid colliding with M1's `tb_core_top` — both testbenches live in the project simultaneously, switch "Set as Top" in Vivado's Sources panel depending on which one you're running).

Straight-line program only (no branches), exercising I-type→R-type, R-type→store, load→R-type, and R-type→I-type dependency chains, each spaced at the minimum-safe 3-NOP gap. Checks two things:
1. Final register values (x1, x2, x3, x4, x7, x8) — same style as the M1 testbench.
2. Stage-by-stage pipeline flow for the first instruction — confirms it appears in `if_id_reg`, `id_ex_reg`, `ex_mem_reg`, `mem_wb_reg`, and finally the regfile at exactly the expected cycle, directly verifying the 4-cycle IF→WB latency rather than only checking the end result.

Passed against real `control_unit.v`/`imem.v` plus minimal functional stand-ins for the other modules (sandbox elaboration check only — final confirmation is your own Vivado run).

Gotcha worth remembering for future testbenches: checking a registered signal (e.g. a pipeline register's output) immediately after `@(posedge clk)` reads the pre-update value, since nonblocking assignments don't settle until the NBA region, which runs after the testbench process resumes. Fix: add a small `#1;` delay after the edge before checking — same pattern the M1 testbench already used before its final checks block.

### Toolchain note

Project is now tracked in git (was not before M2). Remote: `git@github.com:NJK-05/risc-v.git` (SSH). `.gitignore` covers `sim/`, `vivado/`, `zip_files/`.

Update to the "completed" framing (naming OpenLane/SKY130 explicitly) once M7
and M8 are done — see `docs/riscv_pipeline_spec.md` §nothing needed, just
swap the wording as discussed previously in the project chat.

## M3 — Forwarding unit added

Status: ✅ Done. Update the milestone table (§6) and mark M4 as next up.

### Modules added

| Module | Purpose |
|---|---|
| `forwarding_unit.v` | Detects RAW hazards between the instruction currently in EX and the instructions in EX/MEM and MEM/WB; outputs 2-bit `forward_a`/`forward_b` selects |

`riscv_core_top.v` was updated: the EX stage now computes `fwd_rs1_data`/`fwd_rs2_data` muxes ahead of the ALU inputs, and `ex_mem_reg`'s `rs2_data_in` (the store write-data path) now takes the forwarded value instead of the raw `id_ex_rs2_data` — stores need forwarding too, since that value bypasses the ALU entirely on its way into EX/MEM.

### Design decisions made during M3

- **EX/MEM forwarding takes priority over MEM/WB.** If both stages happen to target the same register, EX/MEM holds the more recent write.
- **The MEM/WB forwarding source is `write_back_data`** (the already-muxed WB-stage output), not `mem_wb_alu_result` directly. This matters for loads: if the MEM/WB forwarding source were the raw ALU result, a forwarded load would supply its own address instead of the value it loaded.
- **Forwarding does not solve load-use.** When a load is the immediate producer (distance 1), EX/MEM still only holds the load's *address* at that point — the actual loaded data isn't ready until the MEM stage completes, one cycle later, when it lands in MEM/WB. Confirmed by a deliberate negative test: removing the required 1-instruction gap causes `forward_a` to source from EX/MEM anyway (since `rd_addr` matches and `reg_write` is set), silently forwarding the address as if it were data — same address happened to be `0`, so the dependent `add` came out `0` instead of the correct `30`. This is exactly the hazard M4's stall exists to close.

### Minimum spacing, updated from M2

With forwarding, the 3-NOP spacing M2 needed is gone for ALU-producer chains — back-to-back dependent instructions (including stores depending on the immediately preceding instruction) now resolve automatically. The one exception: a load followed immediately by a dependent instruction still needs exactly 1 NOP, until M4 replaces it with a real stall.

### Testbench

`tb/tb_core_top_m3.v` (module name `tb_core_top_m3`) reuses M2's instruction mix with the NOP padding stripped out, keeping only the single load-use NOP. All 6 final-register checks pass. Verified the test isn't trivially passing by temporarily removing the load-use NOP in a scratch build — `x7` came out `0` instead of `30`, confirming the hazard is real and the testbench is actually catching it.
