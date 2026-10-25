## M7 — Vivado synthesis + timing report

Status: 🔶 Setup complete and the RTL change verified in simulation; the Vivado synthesis run itself is pending on your machine. Mark ✅ once `reports/timing_summary.rpt` exists and you've recorded the numbers below.

### Design change: core / wrapper split

`riscv_core_top` had only `clk` and `rst_n` as ports and held the behavioral `imem`/`dmem` inside it. Synthesizing that as-is would be meaningless: with no outputs the tool removes all logic, the never-written `imem` becomes a ROM of constants that collapses the datapath, and a 4 KB behavioral `dmem` would dominate the area numbers instead of the core.

- **`rtl/riscv_core.v`** — the synthesizable design: the full pipeline with an explicit memory interface (`imem_addr`/`imem_instr`; `dmem_mem_read`/`dmem_mem_write`/`dmem_addr`/`dmem_write_data`/`dmem_funct3`/`dmem_read_data`).
- **`rtl/riscv_core_top.v`** — now a thin simulation wrapper: instantiates `riscv_core` as `core_inst`, plus `imem_inst` and `dmem_inst`. Same module name as before, so Vivado's simulation top setup is unchanged.
- Testbench hierarchy paths changed accordingly: pipeline internals are now `dut.core_inst.regfile_inst…`, `dut.core_inst.if_id_reg_inst…` etc. `dut.imem_inst` and `dut.dmem_inst` are unchanged. All six testbenches (`m2`–`m6`, `hazards`) were updated and re-verified.

This is also the shape M8 needs: for OpenLane the memories will be macros or separate blocks, not flops inside the core.

### Synthesis setup

- `constraints/core.xdc` — single `create_clock`, 10 ns (100 MHz) as the starting point.
- `scripts/synth.tcl` — non-project-mode batch script: reads the 13 core RTL files (not `riscv_core_top`, `imem`, `dmem`), applies the constraint, runs `synth_design -mode out_of_context`, and writes `reports/timing_summary.rpt`, `critical_paths.rpt`, `utilization.rpt` and a checkpoint. Run from the project root: `vivado -mode batch -source scripts/synth.tcl`. The `part` variable at the top may need changing to a 7-series part installed on your machine.
- Out-of-context mode means no I/O buffers and no pin constraints: the memory-interface ports are internal-style boundaries, which is the right view of the core.

### What was verified here (without Vivado)

- Simulation: all six testbenches pass against the split design (full-fidelity behavioral models for the modules not available outside Vivado).
- Open-source synthesis sanity check (Yosys) on `riscv_core` standalone: 0 latches inferred, 0 problems found, ~8,600 generic cells of which ~1,500 flip-flops (register file 1,024 + pipeline registers + PC). Indicative only: it used stand-in ALU/regfile models, not your real modules, and generic cells, not Xilinx primitives.
- The Vivado script itself has **not** been run — treat any error from it as something to report back, not as a design failure.

### Reading the results

- **WNS (worst negative slack)** in `timing_summary.rpt`: positive means the 10 ns target is met. Fmax ≈ 1 / (period − WNS). Tighten the period in `core.xdc` until WNS goes negative to find the real limit.
- **Critical path** in `critical_paths.rpt`: the report lists the path stage by stage. Likely suspects in this design are the EX-stage chain forwarding mux → ALU → branch-taken → `pc_src_ex` → `pc_next`, because branch resolution feeds back into the PC in the same cycle. Whatever it actually is, being able to name the critical path and explain why it's long is the interview takeaway.
- **Post-synthesis timing is an estimate**: net delays are modeled before placement and routing. Real numbers need implementation (place and route).
- Utilization report: LUT/FF counts. FF count should land near the ~1,500 above; LUT RAM is expected for the register file.

### Numbers to record once you run it

| Metric | Value |
|---|---|
| Part | |
| Target period | 10 ns |
| WNS at 10 ns | |
| Estimated Fmax | |
| Critical path (start → end) | |
| LUTs / FFs | |
