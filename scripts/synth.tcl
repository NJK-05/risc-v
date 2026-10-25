# Run from the project root:
#   vivado -mode batch -source scripts/synth.tcl
# Out-of-context synthesis of the core only (no memories, no I/O pins).

set part xc7a100tcsg324-1   ;# change to any 7-series part installed on your machine
set top  riscv_core

file mkdir reports

read_verilog {
    rtl/alu.v
    rtl/alu_control.v
    rtl/control_unit.v
    rtl/ex_mem_reg.v
    rtl/forwarding_unit.v
    rtl/hazard_detection_unit.v
    rtl/id_ex_reg.v
    rtl/if_id_reg.v
    rtl/imm_gen.v
    rtl/mem_wb_reg.v
    rtl/pc_reg.v
    rtl/regfile.v
    rtl/riscv_core.v
}

read_xdc constraints/core.xdc

synth_design -top $top -part $part -mode out_of_context

report_timing_summary -file reports/timing_summary.rpt
report_timing -max_paths 5 -nworst 1 -file reports/critical_paths.rpt
report_utilization    -file reports/utilization.rpt

write_checkpoint -force reports/riscv_core_synth.dcp
