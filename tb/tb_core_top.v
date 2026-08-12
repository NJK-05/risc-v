`timescale 1ns/1ps

// Test program (byte addresses shown, word index = addr/4):
//   0:  addi x1, x0, 5      x1 = 5
//   4:  addi x2, x0, 10     x2 = 10
//   8:  add  x3, x1, x2     x3 = 15
//   12: sw   x3, 0(x0)      mem[0..3] = 15
//   16: lw   x4, 0(x0)      x4 = 15
//   20: beq  x3, x4, 8      x3==x4 (15==15) -> branch taken, target = 20+8 = 28
//   24: addi x5, x0, 99     SKIPPED by the branch
//   28: addi x6, x0, 42     x6 = 42
//
// Expected final state: x1=5, x2=10, x3=15, x4=15, x5=0 (never executed), x6=42

module tb_core_top;

    reg clk = 0;
    reg rst_n;
    integer errors = 0;

    riscv_core_top dut (.clk(clk), .rst_n(rst_n));

    always #5 clk = ~clk;

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

        // Load the program directly into instruction memory
        dut.imem_inst.mem[0] = {12'd5,  5'd0, 3'b000, 5'd1, 7'b0010011}; // addi x1,x0,5
        dut.imem_inst.mem[1] = {12'd10, 5'd0, 3'b000, 5'd2, 7'b0010011}; // addi x2,x0,10
        dut.imem_inst.mem[2] = {7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011}; // add x3,x1,x2
        dut.imem_inst.mem[3] = {7'b0000000, 5'd3, 5'd0, 3'b010, 5'b00000, 7'b0100011}; // sw x3,0(x0)
        dut.imem_inst.mem[4] = {12'd0, 5'd0, 3'b010, 5'd4, 7'b0000011}; // lw x4,0(x0)
        dut.imem_inst.mem[5] = {1'b0, 6'b000000, 5'd4, 5'd3, 3'b000, 4'b0100, 1'b0, 7'b1100011}; // beq x3,x4,8
        dut.imem_inst.mem[6] = {12'd99, 5'd0, 3'b000, 5'd5, 7'b0010011}; // addi x5,x0,99 (skipped)
        dut.imem_inst.mem[7] = {12'd42, 5'd0, 3'b000, 5'd6, 7'b0010011}; // addi x6,x0,42

        #12 rst_n = 1;

        // 8 instruction slots max in program order + margin
        repeat (10) @(posedge clk);
        #1;

        check(dut.regfile_inst.regs[1], 32'd5,  "x1 = 5 (addi)");
        check(dut.regfile_inst.regs[2], 32'd10, "x2 = 10 (addi)");
        check(dut.regfile_inst.regs[3], 32'd15, "x3 = 15 (add)");
        check(dut.regfile_inst.regs[4], 32'd15, "x4 = 15 (loaded via lw)");
        check(dut.regfile_inst.regs[5], 32'd0,  "x5 = 0 (skipped by taken branch)");
        check(dut.regfile_inst.regs[6], 32'd42, "x6 = 42 (executed after branch)");

        #10;
        if (errors == 0) $display("\nALL TESTS PASSED");
        else $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end

endmodule
