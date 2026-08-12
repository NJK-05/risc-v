`timescale 1ns/1ps

module tb_alu_control;

    reg  [1:0] alu_op;
    reg  [2:0] funct3;
    reg        funct7_5;
    wire [3:0] alu_ctrl;

    integer errors = 0;

    alu_control dut (.alu_op(alu_op), .funct3(funct3), .funct7_5(funct7_5), .alu_ctrl(alu_ctrl));

    task check(input [3:0] actual, input [3:0] expected, input [319:0] name);
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s - expected %0b, got %0b", name, expected, actual);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s", name);
            end
        end
    endtask

    initial begin
        // Memory ref / AUIPC -> always ADD
        alu_op = 2'b00; funct3 = 3'b000; funct7_5 = 0; #1;
        check(alu_ctrl, 4'b0000, "ALUOp=00 -> ADD (load/store addr)");

        // Branches
        alu_op = 2'b01; funct3 = 3'b000; funct7_5 = 0; #1; // BEQ
        check(alu_ctrl, 4'b0001, "BEQ -> SUB");
        alu_op = 2'b01; funct3 = 3'b100; funct7_5 = 0; #1; // BLT
        check(alu_ctrl, 4'b1000, "BLT -> SLT");
        alu_op = 2'b01; funct3 = 3'b110; funct7_5 = 0; #1; // BLTU
        check(alu_ctrl, 4'b1001, "BLTU -> SLTU");

        // R-type
        alu_op = 2'b10; funct3 = 3'b000; funct7_5 = 0; #1; // ADD
        check(alu_ctrl, 4'b0000, "R-type funct3=000 funct7_5=0 -> ADD");
        alu_op = 2'b10; funct3 = 3'b000; funct7_5 = 1; #1; // SUB
        check(alu_ctrl, 4'b0001, "R-type funct3=000 funct7_5=1 -> SUB");
        alu_op = 2'b10; funct3 = 3'b101; funct7_5 = 0; #1; // SRL
        check(alu_ctrl, 4'b0110, "R-type funct3=101 funct7_5=0 -> SRL");
        alu_op = 2'b10; funct3 = 3'b101; funct7_5 = 1; #1; // SRA
        check(alu_ctrl, 4'b0111, "R-type funct3=101 funct7_5=1 -> SRA");
        alu_op = 2'b10; funct3 = 3'b111; funct7_5 = 0; #1; // AND
        check(alu_ctrl, 4'b0010, "R-type funct3=111 -> AND");

        // I-type arithmetic
        alu_op = 2'b11; funct3 = 3'b000; funct7_5 = 0; #1; // ADDI
        check(alu_ctrl, 4'b0000, "I-type ADDI -> ADD");
        alu_op = 2'b11; funct3 = 3'b101; funct7_5 = 0; #1; // SRLI
        check(alu_ctrl, 4'b0110, "I-type SRLI -> SRL");
        alu_op = 2'b11; funct3 = 3'b101; funct7_5 = 1; #1; // SRAI
        check(alu_ctrl, 4'b0111, "I-type SRAI -> SRA");
        alu_op = 2'b11; funct3 = 3'b010; funct7_5 = 0; #1; // SLTI
        check(alu_ctrl, 4'b1000, "I-type SLTI -> SLT");

        #10;
        if (errors == 0) $display("\nALL TESTS PASSED");
        else $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end

endmodule
