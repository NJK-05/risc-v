`timescale 1ns/1ps

module tb_core_top;

    localparam NOP = 32'h0000_0013; // addi x0, x0, 0

    reg clk = 0;
    reg rst_n;
    integer errors = 0;
    integer edge_count = 0;

    riscv_core_top dut (.clk(clk), .rst_n(rst_n));

    always #5 clk = ~clk;
    always @(posedge clk) if (rst_n) edge_count = edge_count + 1;

    task check(input [31:0] actual, input [31:0] expected, input [319:0] name);
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s - expected %0d, got %0d", name, expected, actual);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s", name);
            end
        end
    endtask

    initial begin
        rst_n = 0;

        dut.imem_inst.mem[0]  = {12'd5,  5'd0, 3'b000, 5'd1, 7'b0010011}; // addi x1,x0,5
        dut.imem_inst.mem[1]  = {12'd10, 5'd0, 3'b000, 5'd2, 7'b0010011}; // addi x2,x0,10
        dut.imem_inst.mem[2]  = NOP;
        dut.imem_inst.mem[3]  = NOP;
        dut.imem_inst.mem[4]  = NOP;
        dut.imem_inst.mem[5]  = {7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011}; // add x3,x1,x2
        dut.imem_inst.mem[6]  = NOP;
        dut.imem_inst.mem[7]  = NOP;
        dut.imem_inst.mem[8]  = NOP;
        dut.imem_inst.mem[9]  = {7'b0000000, 5'd3, 5'd0, 3'b010, 5'b00000, 7'b0100011}; // sw x3,0(x0)
        dut.imem_inst.mem[10] = {12'd0, 5'd0, 3'b010, 5'd4, 7'b0000011}; // lw x4,0(x0)
        dut.imem_inst.mem[11] = NOP;
        dut.imem_inst.mem[12] = NOP;
        dut.imem_inst.mem[13] = NOP;
        dut.imem_inst.mem[14] = {7'b0000000, 5'd4, 5'd3, 3'b000, 5'd7, 7'b0110011}; // add x7,x3,x4
        dut.imem_inst.mem[15] = NOP;
        dut.imem_inst.mem[16] = NOP;
        dut.imem_inst.mem[17] = NOP;
        dut.imem_inst.mem[18] = {12'd1, 5'd7, 3'b000, 5'd8, 7'b0010011}; // addi x8,x7,1

        #12 rst_n = 1;

        // ---- Stage-by-stage flow check for instruction 0 (addi x1,x0,5) ----
        // Confirms the 4-cycle IF->WB latency directly against the pipeline
        // registers, not just the final regfile value.
        @(posedge clk); #1; // edge 0: instr0 latched into if_id_reg (now in ID)
        check(dut.if_id_reg_inst.instr_out, {12'd5, 5'd0, 3'b000, 5'd1, 7'b0010011},
              "edge0: instr0 present in if_id_reg");

        @(posedge clk); #1; // edge 1: instr0 latched into id_ex_reg (now in EX)
        check(dut.id_ex_reg_inst.rd_addr_out, 5'd1, "edge1: instr0 rd_addr in id_ex_reg");
        check(dut.id_ex_reg_inst.reg_write_out, 1'b1, "edge1: instr0 reg_write in id_ex_reg");

        @(posedge clk); #1; // edge 2: instr0 latched into ex_mem_reg (now in MEM)
        check(dut.ex_mem_reg_inst.rd_addr_out, 5'd1, "edge2: instr0 rd_addr in ex_mem_reg");
        check(dut.ex_mem_reg_inst.alu_result_out, 32'd5, "edge2: instr0 alu_result in ex_mem_reg");

        @(posedge clk); #1; // edge 3: instr0 latched into mem_wb_reg (now in WB)
        check(dut.mem_wb_reg_inst.rd_addr_out, 5'd1, "edge3: instr0 rd_addr in mem_wb_reg");
        check(dut.mem_wb_reg_inst.alu_result_out, 32'd5, "edge3: instr0 alu_result in mem_wb_reg");

        @(posedge clk); #1; // edge 4: instr0's result committed to regfile
        check(dut.regfile_inst.regs[1], 32'd5, "edge4: x1 = 5 written back");

        // ---- Let the rest of the program run to completion ----
        repeat (22) @(posedge clk);
        #1;

        check(dut.regfile_inst.regs[1], 32'd5,  "x1 = 5 (addi)");
        check(dut.regfile_inst.regs[2], 32'd10, "x2 = 10 (addi)");
        check(dut.regfile_inst.regs[3], 32'd15, "x3 = 15 (add, 3-NOP gap)");
        check(dut.regfile_inst.regs[4], 32'd15, "x4 = 15 (loaded via lw)");
        check(dut.regfile_inst.regs[7], 32'd30, "x7 = 30 (add, depends on x3 and x4)");
        check(dut.regfile_inst.regs[8], 32'd31, "x8 = 31 (addi, depends on x7)");

        #10;
        if (errors == 0) $display("\nALL TESTS PASSED");
        else $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end

endmodule
