// RV32I Immediate Generator
// Decodes the correct sign-extended immediate for each instruction format
// based on opcode. Combinational only - this just rearranges instruction bits.

module imm_gen (
    input  wire [31:0] instr,
    output reg  [31:0] imm
);

    // Opcode field is always instr[6:0] regardless of format
    localparam OPC_RTYPE  = 7'b0110011; // R-type: no immediate (imm unused)
    localparam OPC_ITYPE  = 7'b0010011; // I-type arithmetic (ADDI, ANDI, etc.)
    localparam OPC_LOAD   = 7'b0000011; // I-type loads
    localparam OPC_JALR   = 7'b1100111; // I-type jalr
    localparam OPC_STORE  = 7'b0100011; // S-type
    localparam OPC_BRANCH = 7'b1100011; // B-type
    localparam OPC_LUI    = 7'b0110111; // U-type
    localparam OPC_AUIPC  = 7'b0010111; // U-type
    localparam OPC_JAL    = 7'b1101111; // J-type

    always @(*) begin
        case (instr[6:0])
            OPC_ITYPE, OPC_LOAD, OPC_JALR:
                // I-type: imm[11:0] = instr[31:20], sign-extended
                imm = {{20{instr[31]}}, instr[31:20]};

            OPC_STORE:
                // S-type: imm[11:5] = instr[31:25], imm[4:0] = instr[11:7]
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            OPC_BRANCH:
                // B-type: imm[12|10:5|4:1|11], always even (bit 0 = 0)
                imm = {{19{instr[31]}}, instr[31], instr[7],
                       instr[30:25], instr[11:8], 1'b0};

            OPC_LUI, OPC_AUIPC:
                // U-type: imm[31:12] = instr[31:12], lower 12 bits zero
                imm = {instr[31:12], 12'b0};

            OPC_JAL:
                // J-type: imm[20|10:1|11|19:12], always even (bit 0 = 0)
                imm = {{11{instr[31]}}, instr[31], instr[19:12],
                       instr[20], instr[30:21], 1'b0};

            default:
                imm = 32'd0; // R-type or unrecognised - immediate unused
        endcase
    end

endmodule
