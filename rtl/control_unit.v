// Main Control Unit
// Decodes the opcode field into all control signals needed to drive the
// single-cycle (and later pipelined) datapath. Combinational only.
//
// Output signal meanings:
//   reg_write  - write result into register file
//   alu_src    - ALU operand B select: 0 = rs2, 1 = immediate
//   alu_src_a  - ALU operand A select: 00 = rs1, 01 = PC, 10 = zero
//                (PC is used for AUIPC, zero is used for LUI so the ALU
//                 just computes 0 + imm = imm)
//   mem_read   - read from data memory (loads)
//   mem_write  - write to data memory (stores)
//   result_src - selects what gets written back to the register file:
//                00 = ALU result, 01 = memory read data, 10 = PC+4 (JAL/JALR)
//   branch     - this is a conditional branch instruction
//   jump       - this is an unconditional jump (JAL/JALR)
//   alu_op     - coarse op sent to alu_control.v (see alu_control.v header)

module control_unit (
    input  wire [6:0] opcode,

    output reg        reg_write,
    output reg        alu_src,
    output reg  [1:0] alu_src_a,
    output reg        mem_read,
    output reg        mem_write,
    output reg  [1:0] result_src,
    output reg        branch,
    output reg        jump,
    output reg  [1:0] alu_op
);

    localparam OPC_RTYPE  = 7'b0110011;
    localparam OPC_ITYPE  = 7'b0010011;
    localparam OPC_LOAD   = 7'b0000011;
    localparam OPC_STORE  = 7'b0100011;
    localparam OPC_BRANCH = 7'b1100011;
    localparam OPC_JAL    = 7'b1101111;
    localparam OPC_JALR   = 7'b1100111;
    localparam OPC_LUI    = 7'b0110111;
    localparam OPC_AUIPC  = 7'b0010111;

    always @(*) begin
        // Safe defaults - a NOP-like state, overridden per opcode below
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        alu_src_a  = 2'b00;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        result_src = 2'b00;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_op     = 2'b00;

        case (opcode)

            OPC_RTYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;      // rs2
                alu_src_a = 2'b00;     // rs1
                result_src = 2'b00;    // ALU result
                alu_op    = 2'b10;     // full funct decode
            end

            OPC_ITYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;      // immediate
                alu_src_a = 2'b00;     // rs1
                result_src = 2'b00;
                alu_op    = 2'b11;     // I-type funct decode
            end

            OPC_LOAD: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;      // immediate (address offset)
                alu_src_a = 2'b00;     // rs1
                mem_read  = 1'b1;
                result_src = 2'b01;    // memory data
                alu_op    = 2'b00;     // ADD for address calc
            end

            OPC_STORE: begin
                reg_write = 1'b0;
                alu_src   = 1'b1;      // immediate (address offset)
                alu_src_a = 2'b00;     // rs1
                mem_write = 1'b1;
                alu_op    = 2'b00;     // ADD for address calc
            end

            OPC_BRANCH: begin
                reg_write = 1'b0;
                alu_src   = 1'b0;      // rs2, for comparison against rs1
                alu_src_a = 2'b00;     // rs1
                branch    = 1'b1;
                alu_op    = 2'b01;     // branch comparison decode
            end

            OPC_JAL: begin
                reg_write  = 1'b1;
                jump       = 1'b1;
                result_src = 2'b10;    // PC+4 (return address)
                // ALU unused for JAL; target computed by dedicated PC adder
            end

            OPC_JALR: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;     // immediate
                alu_src_a  = 2'b00;    // rs1 (target = rs1 + imm)
                jump       = 1'b1;
                result_src = 2'b10;    // PC+4 (return address)
                alu_op     = 2'b00;    // ADD for target calc
            end

            OPC_LUI: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;     // immediate
                alu_src_a  = 2'b10;    // zero, so ALU computes 0+imm = imm
                result_src = 2'b00;
                alu_op     = 2'b00;    // ADD
            end

            OPC_AUIPC: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;     // immediate
                alu_src_a  = 2'b01;    // PC, so ALU computes PC+imm
                result_src = 2'b00;
                alu_op     = 2'b00;    // ADD
            end

            default: begin
                // Unrecognised opcode - defaults above act as a safe NOP
            end

        endcase
    end

endmodule
