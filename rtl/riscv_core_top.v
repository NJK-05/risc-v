// Simulation wrapper: pipeline core + behavioral instruction/data memories.
// The synthesizable design is riscv_core.

module riscv_core_top (
    input wire clk,
    input wire rst_n
);

    wire [31:0] imem_addr, imem_instr;
    wire        dmem_mem_read, dmem_mem_write;
    wire [31:0] dmem_addr, dmem_write_data, dmem_read_data;
    wire [2:0]  dmem_funct3;

    riscv_core core_inst (
        .clk(clk), .rst_n(rst_n),
        .imem_addr(imem_addr), .imem_instr(imem_instr),
        .dmem_mem_read(dmem_mem_read), .dmem_mem_write(dmem_mem_write),
        .dmem_addr(dmem_addr), .dmem_write_data(dmem_write_data),
        .dmem_funct3(dmem_funct3), .dmem_read_data(dmem_read_data)
    );

    imem imem_inst (
        .addr(imem_addr), .instr(imem_instr)
    );

    dmem dmem_inst (
        .clk(clk), .mem_read(dmem_mem_read), .mem_write(dmem_mem_write),
        .addr(dmem_addr), .write_data(dmem_write_data), .funct3(dmem_funct3),
        .read_data(dmem_read_data)
    );

endmodule
