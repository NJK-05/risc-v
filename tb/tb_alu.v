`timescale 1ns/1ps

module tb_alu;

    reg  [31:0] a, b;
    reg  [3:0]  alu_op;
    wire [31:0] result;
    wire        zero;

    integer errors = 0;

    alu dut (.a(a), .b(b), .alu_op(alu_op), .result(result), .zero(zero));

    task check(input [31:0] actual, input [31:0] expected, input [319:0] name);
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s - expected %0d (0x%0h), got %0d (0x%0h)",
                          name, expected, expected, actual, actual);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s", name);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu);

        // ADD
        a = 32'd10; b = 32'd15; alu_op = 4'b0000; #1;
        check(result, 32'd25, "ADD 10+15");

        // SUB
        a = 32'd20; b = 32'd8; alu_op = 4'b0001; #1;
        check(result, 32'd12, "SUB 20-8");

        // SUB producing negative (check two's complement wraps correctly)
        a = 32'd5; b = 32'd10; alu_op = 4'b0001; #1;
        check(result, -32'sd5, "SUB 5-10 (negative)");

        // AND / OR / XOR
        a = 32'hFF00FF00; b = 32'h0F0F0F0F; alu_op = 4'b0010; #1;
        check(result, 32'h0F000F00, "AND");
        a = 32'hFF00FF00; b = 32'h0F0F0F0F; alu_op = 4'b0011; #1;
        check(result, 32'hFF0FFF0F, "OR");
        a = 32'hFF00FF00; b = 32'h0F0F0F0F; alu_op = 4'b0100; #1;
        check(result, 32'hF00FF00F, "XOR");

        // Shifts
        a = 32'h00000001; b = 32'd4; alu_op = 4'b0101; #1;
        check(result, 32'h00000010, "SLL by 4");
        a = 32'h80000000; b = 32'd4; alu_op = 4'b0110; #1;
        check(result, 32'h08000000, "SRL by 4 (logical, no sign extend)");
        a = 32'h80000000; b = 32'd4; alu_op = 4'b0111; #1;
        check(result, 32'hF8000000, "SRA by 4 (arithmetic, sign extends)");

        // SLT / SLTU
        a = -32'sd5; b = 32'd3; alu_op = 4'b1000; #1;
        check(result, 32'd1, "SLT: -5 < 3 signed -> true");
        a = -32'sd5; b = 32'd3; alu_op = 4'b1001; #1;
        // -5 as unsigned is huge, so -5 < 3 unsigned is false
        check(result, 32'd0, "SLTU: -5 < 3 unsigned -> false");

        // Zero flag
        a = 32'd7; b = 32'd7; alu_op = 4'b0001; #1; // SUB -> 0
        check(zero, 1'b1, "zero flag asserted on 7-7");
        a = 32'd7; b = 32'd8; alu_op = 4'b0001; #1;
        check(zero, 1'b0, "zero flag deasserted on 7-8");

        #10;
        if (errors == 0)
            $display("\nALL TESTS PASSED");
        else
            $display("\n%0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule
