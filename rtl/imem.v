// Instruction memory - simulation model
// Word-addressable (lower 2 bits of the byte address are ignored, RV32I
// instructions are always 4-byte aligned).

module imem #(
    parameter DEPTH = 1024   // words (4KB default)
) (
    input  wire [31:0] addr,   // byte address (PC)
    output wire [31:0] instr
);

    reg [31:0] mem [0:DEPTH-1];

    assign instr = mem[addr[$clog2(DEPTH)+1:2]];

endmodule
