`timescale 1ns/1ps

module tb_control_unit;

    reg  [6:0] opcode;
    wire       reg_write, alu_src, mem_read, mem_write, branch, jump;
    wire [1:0] alu_src_a, result_src, alu_op;

    integer errors = 0;

    control_unit dut (
        .opcode(opcode),
        .reg_write(reg_write), .alu_src(alu_src), .alu_src_a(alu_src_a),
        .mem_read(mem_read), .mem_write(mem_write), .result_src(result_src),
        .branch(branch), .jump(jump), .alu_op(alu_op)
    );

    task check1(input actual, input expected, input [319:0] name);
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s - expected %0b, got %0b", name, expected, actual);
                errors = errors + 1;
            end else $display("PASS: %0s", name);
        end
    endtask

    task check2(input [1:0] actual, input [1:0] expected, input [319:0] name);
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s - expected %0b, got %0b", name, expected, actual);
                errors = errors + 1;
            end else $display("PASS: %0s", name);
        end
    endtask

    initial begin
        // R-type
        opcode = 7'b0110011; #1;
        check1(reg_write, 1'b1, "R-type reg_write");
        check1(alu_src, 1'b0, "R-type alu_src=rs2");
        check2(alu_op, 2'b10, "R-type alu_op");
        check1(branch, 1'b0, "R-type branch=0");

        // I-type arithmetic
        opcode = 7'b0010011; #1;
        check1(reg_write, 1'b1, "I-type reg_write");
        check1(alu_src, 1'b1, "I-type alu_src=imm");
        check2(alu_op, 2'b11, "I-type alu_op");

        // Load
        opcode = 7'b0000011; #1;
        check1(reg_write, 1'b1, "Load reg_write");
        check1(mem_read, 1'b1, "Load mem_read");
        check2(result_src, 2'b01, "Load result_src=mem");
        check2(alu_op, 2'b00, "Load alu_op=ADD");

        // Store
        opcode = 7'b0100011; #1;
        check1(reg_write, 1'b0, "Store reg_write=0");
        check1(mem_write, 1'b1, "Store mem_write");
        check1(alu_src, 1'b1, "Store alu_src=imm");

        // Branch
        opcode = 7'b1100011; #1;
        check1(reg_write, 1'b0, "Branch reg_write=0");
        check1(branch, 1'b1, "Branch branch=1");
        check2(alu_op, 2'b01, "Branch alu_op");

        // JAL
        opcode = 7'b1101111; #1;
        check1(reg_write, 1'b1, "JAL reg_write");
        check1(jump, 1'b1, "JAL jump=1");
        check2(result_src, 2'b10, "JAL result_src=PC+4");

        // JALR
        opcode = 7'b1100111; #1;
        check1(jump, 1'b1, "JALR jump=1");
        check1(alu_src, 1'b1, "JALR alu_src=imm");
        check2(result_src, 2'b10, "JALR result_src=PC+4");

        // LUI
        opcode = 7'b0110111; #1;
        check1(reg_write, 1'b1, "LUI reg_write");
        check2(alu_src_a, 2'b10, "LUI alu_src_a=zero");
        check1(alu_src, 1'b1, "LUI alu_src=imm");

        // AUIPC
        opcode = 7'b0010111; #1;
        check1(reg_write, 1'b1, "AUIPC reg_write");
        check2(alu_src_a, 2'b01, "AUIPC alu_src_a=PC");

        #10;
        if (errors == 0) $display("\nALL TESTS PASSED");
        else $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end

endmodule
