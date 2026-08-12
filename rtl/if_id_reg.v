// IF/ID Pipeline Register

module if_id_reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,
    input  wire        flush,

    input  wire [31:0] pc_in,
    input  wire [31:0] pc_plus4_in,
    input  wire [31:0] instr_in,

    output reg  [31:0] pc_out,
    output reg  [31:0] pc_plus4_out,
    output reg  [31:0] instr_out
);

    // All-zero instruction word (0x00000000) decodes to opcode 7'b0000000,
    // which falls into control_unit.v's default case -> safe NOP.
    localparam NOP_INSTR = 32'h0000_0000;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out       <= 32'd0;
            pc_plus4_out <= 32'd0;
            instr_out    <= NOP_INSTR;
        end else if (flush) begin
            pc_out       <= 32'd0;
            pc_plus4_out <= 32'd0;
            instr_out    <= NOP_INSTR;
        end else if (!stall) begin
            pc_out       <= pc_in;
            pc_plus4_out <= pc_plus4_in;
            instr_out    <= instr_in;
        end
        // else: stall with no flush -> hold current values
    end

endmodule
