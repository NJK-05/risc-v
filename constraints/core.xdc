# 100 MHz starting point; tighten until timing fails to find Fmax
create_clock -period 14.000 -name clk [get_ports clk]
