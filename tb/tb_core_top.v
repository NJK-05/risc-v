`timescale 1ns/1ps

// M4 testbench: identical to M3's, but the one remaining manual NOP
// (load-use gap) is removed. The hazard detection unit should insert
// that stall cycle automatically now.
//
// Program:
//   0: addi x1, x0, 5        x1 = 5
//   1: addi x2, x0, 10       x2 = 10
//   2: add  x3, x1, x2       x3 = 15
//   3: sw   x3, 0(x0)        mem[0] = 15
//   4: lw   x4, 0(x0)        x4 = 15
//   5: add  x7, x3, x4       x7 = 30   (immediately follows the load - no NOP)
//   6: addi x8, x7, 1        x8 = 31
//
// Expected: x1=5, x2=10, x3=15, x4=15, x7=30, x8=31

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

        dut.imem_inst.mem[0] = {12'd5,  5'd0, 3'b000, 5'd1, 7'b0010011}; // addi x1,x0,5
        dut.imem_inst.mem[1] = {12'd10, 5'd0, 3'b000, 5'd2, 7'b0010011}; // addi x2,x0,10
        dut.imem_inst.mem[2] = {7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011}; // add x3,x1,x2
        dut.imem_inst.mem[3] = {7'b0000000, 5'd3, 5'd0, 3'b010, 5'b00000, 7'b0100011}; // sw x3,0(x0)
        dut.imem_inst.mem[4] = {12'd0, 5'd0, 3'b010, 5'd4, 7'b0000011}; // lw x4,0(x0)
        dut.imem_inst.mem[5] = {7'b0000000, 5'd4, 5'd3, 3'b000, 5'd7, 7'b0110011}; // add x7,x3,x4 - no gap
        dut.imem_inst.mem[6] = {12'd1, 5'd7, 3'b000, 5'd8, 7'b0010011}; // addi x8,x7,1

        #12 rst_n = 1;

        repeat (14) @(posedge clk);
        #1;

        check(dut.regfile_inst.regs[1], 32'd5,  "x1 = 5 (addi)");
        check(dut.regfile_inst.regs[2], 32'd10, "x2 = 10 (addi)");
        check(dut.regfile_inst.regs[3], 32'd15, "x3 = 15 (add, forwarded)");
        check(dut.regfile_inst.regs[4], 32'd15, "x4 = 15 (loaded via lw)");
        check(dut.regfile_inst.regs[7], 32'd30, "x7 = 30 (add, load-use, no NOP - auto-stalled)");
        check(dut.regfile_inst.regs[8], 32'd31, "x8 = 31 (addi, forwarded)");

        #10;
        if (errors == 0) $display("\nALL TESTS PASSED");
        else $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end

endmodule // tb_core_top_m4
