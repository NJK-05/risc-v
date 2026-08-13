module forwarding_unit (
    input  wire [4:0] id_ex_rs1_addr,
    input  wire [4:0] id_ex_rs2_addr,

    input  wire [4:0] ex_mem_rd_addr,
    input  wire       ex_mem_reg_write,

    input  wire [4:0] mem_wb_rd_addr,
    input  wire       mem_wb_reg_write,

    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);
    // 00 = no forward, 10 = forward from EX/MEM, 01 = forward from MEM/WB
    // EX/MEM takes priority - it's the more recent write.

    always @(*) begin
        if (ex_mem_reg_write && ex_mem_rd_addr != 5'd0 && ex_mem_rd_addr == id_ex_rs1_addr)
            forward_a = 2'b10;
        else if (mem_wb_reg_write && mem_wb_rd_addr != 5'd0 && mem_wb_rd_addr == id_ex_rs1_addr)
            forward_a = 2'b01;
        else
            forward_a = 2'b00;

        if (ex_mem_reg_write && ex_mem_rd_addr != 5'd0 && ex_mem_rd_addr == id_ex_rs2_addr)
            forward_b = 2'b10;
        else if (mem_wb_reg_write && mem_wb_rd_addr != 5'd0 && mem_wb_rd_addr == id_ex_rs2_addr)
            forward_b = 2'b01;
        else
            forward_b = 2'b00;
    end
endmodule
