`timescale 1ns/1ps

// Sweeps producer->consumer distance 1..4 for both ALU and load producers,
// and checks a load-use stall that also has an older producer feeding the
// stalled consumer (the stall pushes that older producer out of forwarding
// range, so only a WB->ID bypass can save it).
//
// Each case uses its own registers so a failure points at exactly one case.
// NOP = addi x0,x0,0 (32'h00000013).
//
// ALU producer, consumer = addi rd, rsrc, 100:
//   dist 1:  addi x1,x0,11 ; addi x11,x1,100        -> x11 = 111
//   dist 2:  addi x2,x0,12 ; nop ; addi x12,x2,100  -> x12 = 112
//   dist 3:  addi x3,x0,13 ; nop ; nop ; addi x13,x3,100 -> x13 = 113
//   dist 4:  addi x4,x0,14 ; nop x3 ; addi x14,x4,100    -> x14 = 114
//
// Load producer (mem[0] preset by sw of 50): lw x5,0(x0) then consumer
//   dist 1 (stall): lw x5 ; addi x15,x5,100  -> x15 = 150
//   dist 2:         lw x6 ; nop ; addi x16,x6,100 -> x16 = 150
//   dist 3:         lw x7 ; nop ; nop ; addi x17,x7,100 -> x17 = 150
//   dist 4:         lw x8 ; nop x3 ; addi x18,x8,100 -> x18 = 150
//
// Stall + older producer: addi x20,x0,7 ; lw x21,0(x0) ; add x22,x20,x21
//   x20 is distance 2 from the add, but the load-use stall on x21 delays
//   the add by one cycle -> x22 = 7 + 50 = 57

module tb_core_top_hazards;
    localparam NOP = 32'h0000_0013;

    reg clk = 0;
    reg rst_n;
    integer errors = 0;
    integer n = 0;

    riscv_core_top dut (.clk(clk), .rst_n(rst_n));
    always #5 clk = ~clk;

    function [31:0] addi(input [11:0] imm, input [4:0] rs1, input [4:0] rd);
        addi = {imm, rs1, 3'b000, rd, 7'b0010011};
    endfunction
    function [31:0] lw(input [11:0] imm, input [4:0] rs1, input [4:0] rd);
        lw = {imm, rs1, 3'b010, rd, 7'b0000011};
    endfunction
    function [31:0] sw(input [11:0] imm, input [4:0] rs2, input [4:0] rs1);
        sw = {imm[11:5], rs2, rs1, 3'b010, imm[4:0], 7'b0100011};
    endfunction
    function [31:0] add(input [4:0] rs2, input [4:0] rs1, input [4:0] rd);
        add = {7'b0000000, rs2, rs1, 3'b000, rd, 7'b0110011};
    endfunction

    task emit(input [31:0] w);
        begin dut.imem_inst.mem[n] = w; n = n + 1; end
    endtask

    task check(input [31:0] actual, input [31:0] expected, input [319:0] name);
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s - expected %0d, got %0d", name, expected, actual);
                errors = errors + 1;
            end else $display("PASS: %0s", name);
        end
    endtask

    initial begin
        rst_n = 0;

        // preset mem[0] = 50, with plenty of NOP spacing so setup is not under test
        emit(addi(12'd50, 5'd0, 5'd30));  emit(NOP); emit(NOP); emit(NOP); emit(NOP);
        emit(sw(12'd0, 5'd30, 5'd0));     emit(NOP); emit(NOP); emit(NOP); emit(NOP);

        // ALU producers, distance 1..4
        emit(addi(12'd11, 5'd0, 5'd1));  emit(addi(12'd100, 5'd1, 5'd11));
        emit(NOP); emit(NOP); emit(NOP); emit(NOP);
        emit(addi(12'd12, 5'd0, 5'd2));  emit(NOP); emit(addi(12'd100, 5'd2, 5'd12));
        emit(NOP); emit(NOP); emit(NOP); emit(NOP);
        emit(addi(12'd13, 5'd0, 5'd3));  emit(NOP); emit(NOP); emit(addi(12'd100, 5'd3, 5'd13));
        emit(NOP); emit(NOP); emit(NOP); emit(NOP);
        emit(addi(12'd14, 5'd0, 5'd4));  emit(NOP); emit(NOP); emit(NOP); emit(addi(12'd100, 5'd4, 5'd14));
        emit(NOP); emit(NOP); emit(NOP); emit(NOP);

        // Load producers, distance 1..4
        emit(lw(12'd0, 5'd0, 5'd5));  emit(addi(12'd100, 5'd5, 5'd15));
        emit(NOP); emit(NOP); emit(NOP); emit(NOP);
        emit(lw(12'd0, 5'd0, 5'd6));  emit(NOP); emit(addi(12'd100, 5'd6, 5'd16));
        emit(NOP); emit(NOP); emit(NOP); emit(NOP);
        emit(lw(12'd0, 5'd0, 5'd7));  emit(NOP); emit(NOP); emit(addi(12'd100, 5'd7, 5'd17));
        emit(NOP); emit(NOP); emit(NOP); emit(NOP);
        emit(lw(12'd0, 5'd0, 5'd8));  emit(NOP); emit(NOP); emit(NOP); emit(addi(12'd100, 5'd8, 5'd18));
        emit(NOP); emit(NOP); emit(NOP); emit(NOP);

        // Load-use stall with an older producer on the other operand
        emit(addi(12'd7, 5'd0, 5'd20));
        emit(lw(12'd0, 5'd0, 5'd21));
        emit(add(5'd21, 5'd20, 5'd22));
        emit(NOP); emit(NOP); emit(NOP); emit(NOP);

        #12 rst_n = 1;
        repeat (140) @(posedge clk);
        #1;

        check(dut.regfile_inst.regs[11], 32'd111, "ALU producer, distance 1");
        check(dut.regfile_inst.regs[12], 32'd112, "ALU producer, distance 2");
        check(dut.regfile_inst.regs[13], 32'd113, "ALU producer, distance 3");
        check(dut.regfile_inst.regs[14], 32'd114, "ALU producer, distance 4");
        check(dut.regfile_inst.regs[15], 32'd150, "load producer, distance 1 (stall)");
        check(dut.regfile_inst.regs[16], 32'd150, "load producer, distance 2");
        check(dut.regfile_inst.regs[17], 32'd150, "load producer, distance 3");
        check(dut.regfile_inst.regs[18], 32'd150, "load producer, distance 4");
        check(dut.regfile_inst.regs[22], 32'd57,  "load-use stall + older producer");

        #10;
        if (errors == 0) $display("\nALL TESTS PASSED");
        else $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule // tb_core_top_hazards
