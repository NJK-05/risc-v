`timescale 1ns/1ps

// M5 testbench: a taken branch immediately followed by two real
// instructions that would corrupt state if NOT flushed. This is the
// actual test M2-M4 all avoided (M2/M3/M4 excluded branches on purpose).
//
// Each "must be squashed" instruction targets its OWN register (x9, x10)
// rather than sharing one with the branch target - if they instead shared
// a register, the correct branch-target write would land last in program
// order and silently overwrite a flush bug, hiding it. Using separate
// registers means a flush failure is directly visible: x9 or x10 would
// end up non-zero instead of staying untouched.
//
// Program:
//   0: addi x1, x0, 5        x1 = 5
//   1: addi x2, x0, 5        x2 = 5
//   2: beq  x1, x2, 12       taken (x1==x2), target = pc(8) + 12 = 20 -> word index 5
//   3: addi x9,  x0, 111     MUST be squashed - x9 must stay 0
//   4: addi x10, x0, 222     MUST be squashed - x10 must stay 0
//   5: addi x11, x0, 77      branch target - the only instruction that should execute
//
// Expected: x9 = 0, x10 = 0, x11 = 77.

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

        dut.imem_inst.mem[0] = {12'd5, 5'd0, 3'b000, 5'd1, 7'b0010011}; // addi x1,x0,5
        dut.imem_inst.mem[1] = {12'd5, 5'd0, 3'b000, 5'd2, 7'b0010011}; // addi x2,x0,5
        // beq x1,x2,12 : imm=12 (0000000_01100), split per B-type encoding
        dut.imem_inst.mem[2] = {1'b0, 6'b000000, 5'd2, 5'd1, 3'b000, 4'b0110, 1'b0, 7'b1100011};
        dut.imem_inst.mem[3] = {12'd111, 5'd0, 3'b000, 5'd9,  7'b0010011}; // addi x9,x0,111  (must be squashed)
        dut.imem_inst.mem[4] = {12'd222, 5'd0, 3'b000, 5'd10, 7'b0010011}; // addi x10,x0,222 (must be squashed)
        dut.imem_inst.mem[5] = {12'd77,  5'd0, 3'b000, 5'd11, 7'b0010011}; // addi x11,x0,77  (branch target)

        #12 rst_n = 1;

        repeat (14) @(posedge clk);
        #1;

        check(dut.regfile_inst.regs[1],  32'd5,  "x1 = 5");
        check(dut.regfile_inst.regs[2],  32'd5,  "x2 = 5");
        check(dut.regfile_inst.regs[9],  32'd0,  "x9 = 0 (squashed instruction never wrote)");
        check(dut.regfile_inst.regs[10], 32'd0,  "x10 = 0 (squashed instruction never wrote)");
        check(dut.regfile_inst.regs[11], 32'd77, "x11 = 77 (branch target executed)");

        #10;
        if (errors == 0) $display("\nALL TESTS PASSED");
        else $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end

endmodule // tb_core_top_m5
