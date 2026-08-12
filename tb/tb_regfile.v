`timescale 1ns/1ps

module tb_regfile;

    reg clk = 0;
    reg rst_n;
    reg we;
    reg [4:0] rs1_addr, rs2_addr, rd_addr;
    reg [31:0] rd_data;
    wire [31:0] rs1_data, rs2_data;

    integer errors = 0;

    regfile dut (
        .clk(clk), .rst_n(rst_n),
        .we(we), .rs1_addr(rs1_addr), .rs2_addr(rs2_addr),
        .rd_addr(rd_addr), .rd_data(rd_data),
        .rs1_data(rs1_data), .rs2_data(rs2_data)
    );

    always #5 clk = ~clk; // 10ns period

    task check(input [31:0] actual, input [31:0] expected, input [255:0] name);
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
        $dumpfile("tb_regfile.vcd");
        $dumpvars(0, tb_regfile);

        // Reset
        rst_n = 0; we = 0; rs1_addr = 0; rs2_addr = 0; rd_addr = 0; rd_data = 0;
        #12 rst_n = 1;

        // Test 1: write to x5, then read it back on rs1
        @(negedge clk);
        we = 1; rd_addr = 5; rd_data = 32'hDEADBEEF;
        @(negedge clk);
        we = 0; rs1_addr = 5;
        #1 check(rs1_data, 32'hDEADBEEF, "write then read x5");

        // Test 2: x0 always reads zero, even after attempted write
        @(negedge clk);
        we = 1; rd_addr = 0; rd_data = 32'hFFFFFFFF;
        @(negedge clk);
        we = 0; rs1_addr = 0;
        #1 check(rs1_data, 32'd0, "x0 hardwired to zero");

        // Test 3: two independent registers, read simultaneously on rs1/rs2
        @(negedge clk);
        we = 1; rd_addr = 10; rd_data = 32'h11111111;
        @(negedge clk);
        rd_addr = 20; rd_data = 32'h22222222;
        @(negedge clk);
        we = 0; rs1_addr = 10; rs2_addr = 20;
        #1 check(rs1_data, 32'h11111111, "dual read rs1 (x10)");
        check(rs2_data, 32'h22222222, "dual read rs2 (x20)");

        // Test 4: reset clears all registers
        @(negedge clk);
        rst_n = 0;
        @(negedge clk);
        rst_n = 1;
        rs1_addr = 10;
        #1 check(rs1_data, 32'd0, "reset clears x10");

        #10;
        if (errors == 0)
            $display("\nALL TESTS PASSED");
        else
            $display("\n%0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule
