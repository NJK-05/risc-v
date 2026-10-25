`timescale 1ns/1ps

// M6 testbench: loads a real compiled program (sw/program.hex, built by
// sw/build.sh) instead of hand-encoded instructions. The program (sw/main.c)
// sums 1..10 in a real C for-loop and stores the result (55) to address
// 0x100 - that's how we observe it, since this design has no UART.
//
// Point this at your generated program.hex before running:
//   $readmemh("sw/program.hex", dut.imem_inst.mem);
// (path is relative to the simulator's working directory - adjust if your
// Vivado project runs from somewhere other than the project root)
//
// dmem is byte-addressable (mem[0:4095][7:0]) - the stored 32-bit result
// is checked one byte at a time, not as a single word read.

module tb_core_top_m6;

    localparam RESULT_BYTE_ADDR = 12'd256; // 0x100 - dmem is byte-addressable

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

        $readmemh("program.hex", dut.imem_inst.mem);

        #12 rst_n = 1;

        // Generous margin: a real compiled loop is much longer than the
        // hand-written test programs in M2-M5. Increase this if the
        // program doesn't finish in time (check via waveform - the halt
        // loop in start.s keeps re-fetching the same jump instruction
        // once done, which is a good "are we there yet" signal).
        repeat (200) @(posedge clk);
        #1;

        // 55 fits in one byte, so only the low byte needs to be 55 - the
        // upper 3 bytes of the stored word should be 0.
        check(dut.dmem_inst.mem[RESULT_BYTE_ADDR],     8'd55, "sum(1..10), byte 0 at 0x100");
        check(dut.dmem_inst.mem[RESULT_BYTE_ADDR + 1], 8'd0,  "0x101 byte 1 (upper byte of word)");
        check(dut.dmem_inst.mem[RESULT_BYTE_ADDR + 2], 8'd0,  "0x102 byte 2 (upper byte of word)");
        check(dut.dmem_inst.mem[RESULT_BYTE_ADDR + 3], 8'd0,  "0x103 byte 3 (upper byte of word)");

        #10;
        if (errors == 0) $display("\nALL TESTS PASSED");
        else $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end

endmodule // tb_core_top_m6
