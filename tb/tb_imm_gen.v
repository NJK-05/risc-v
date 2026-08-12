`timescale 1ns/1ps

module tb_imm_gen;

    reg  [31:0] instr;
    wire [31:0] imm;

    integer errors = 0;

    imm_gen dut (.instr(instr), .imm(imm));

    task check(input [31:0] actual, input [31:0] expected, input [319:0] name);
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s - expected 0x%0h, got 0x%0h", name, expected, actual);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s", name);
            end
        end
    endtask

    initial begin
        // ADDI x1, x2, 5   -> I-type, imm = 5
        // encoding: imm[11:0]=000000000101, rs1=00010, funct3=000, rd=00001, opcode=0010011
        instr = {12'd5, 5'd2, 3'b000, 5'd1, 7'b0010011}; #1;
        check(imm, 32'd5, "I-type ADDI positive imm");

        // ADDI x1, x2, -8  -> I-type, imm = -8 (negative, tests sign extension)
        instr = {-12'sd8, 5'd2, 3'b000, 5'd1, 7'b0010011}; #1;
        check(imm, -32'sd8, "I-type ADDI negative imm (sign extend)");

        // SW x3, 20(x4)    -> S-type, imm = 20
        // imm[11:5]=instr[31:25], imm[4:0]=instr[11:7]
        // 20 = 0000000_10100 -> imm[11:5]=0000000, imm[4:0]=10100
        instr = {7'b0000000, 5'd3, 5'd4, 3'b010, 5'b10100, 7'b0100011}; #1;
        check(imm, 32'd20, "S-type SW positive imm");

        // BEQ x1, x2, 8    -> B-type, imm = 8 (branch forward 8 bytes)
        // imm = 12|10:5|4:1|11 encoding, imm=8 = 0000000001000
        // bit12=0, bit11=0, bits10:5=000000, bits4:1=0100, bit0=0(implicit)
        instr = {1'b0, 6'b000000, 5'd2, 5'd1, 3'b000, 4'b0100, 1'b0, 7'b1100011}; #1;
        check(imm, 32'd8, "B-type BEQ forward imm");

        // LUI x1, 0x12345  -> U-type, imm = 0x12345000
        instr = {20'h12345, 5'd1, 7'b0110111}; #1;
        check(imm, 32'h12345000, "U-type LUI imm");

        // JAL x1, 16       -> J-type, imm = 16
        // imm = 20|10:1|11|19:12, imm=16 = bits4:1=1000, rest 0
        instr = {1'b0, 10'b0000001000, 1'b0, 8'b00000000, 5'd1, 7'b1101111}; #1;
        check(imm, 32'd16, "J-type JAL forward imm");

        #10;
        if (errors == 0) $display("\nALL TESTS PASSED");
        else $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end

endmodule
