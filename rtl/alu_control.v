// ALU Control
// Takes the coarse ALUOp from the main control unit plus the instruction's
// funct3/funct7 fields, and produces the 4-bit alu_op that alu.v expects.
//
// ALUOp meaning (set by control_unit.v, not built yet):
//   2'b00 - memory address calc (loads/stores) or AUIPC -> always ADD
//   2'b01 - branch -> depends on funct3 (SUB for eq/ne, SLT/SLTU for others)
//   2'b10 - R-type -> full decode via funct3 + funct7[5]
//   2'b11 - I-type arithmetic -> decode via funct3, funct7[5] only for shifts

module alu_control (
    input  wire [1:0] alu_op,     // coarse op from main control unit
    input  wire [2:0] funct3,
    input  wire        funct7_5,   // instr[30], distinguishes ADD/SUB, SRL/SRA
    output reg  [3:0]  alu_ctrl
);

    // Must match the encoding defined in alu.v
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLL  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_SLT  = 4'b1000;
    localparam ALU_SLTU = 4'b1001;

    always @(*) begin
        case (alu_op)

            2'b00: alu_ctrl = ALU_ADD; // loads/stores/AUIPC address calc

            2'b01: begin // branches
                case (funct3)
                    3'b000, 3'b001: alu_ctrl = ALU_SUB;  // BEQ/BNE -> check zero flag outside
                    3'b100, 3'b101: alu_ctrl = ALU_SLT;  // BLT/BGE -> check result bit
                    3'b110, 3'b111: alu_ctrl = ALU_SLTU; // BLTU/BGEU
                    default:        alu_ctrl = ALU_SUB;
                endcase
            end

            2'b10: begin // R-type
                case (funct3)
                    3'b000:  alu_ctrl = funct7_5 ? ALU_SUB : ALU_ADD; // ADD/SUB
                    3'b001:  alu_ctrl = ALU_SLL;
                    3'b010:  alu_ctrl = ALU_SLT;
                    3'b011:  alu_ctrl = ALU_SLTU;
                    3'b100:  alu_ctrl = ALU_XOR;
                    3'b101:  alu_ctrl = funct7_5 ? ALU_SRA : ALU_SRL; // SRL/SRA
                    3'b110:  alu_ctrl = ALU_OR;
                    3'b111:  alu_ctrl = ALU_AND;
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            2'b11: begin // I-type arithmetic
                case (funct3)
                    3'b000:  alu_ctrl = ALU_ADD;  // ADDI
                    3'b001:  alu_ctrl = ALU_SLL;  // SLLI
                    3'b010:  alu_ctrl = ALU_SLT;  // SLTI
                    3'b011:  alu_ctrl = ALU_SLTU; // SLTIU
                    3'b100:  alu_ctrl = ALU_XOR;  // XORI
                    3'b101:  alu_ctrl = funct7_5 ? ALU_SRA : ALU_SRL; // SRAI/SRLI
                    3'b110:  alu_ctrl = ALU_OR;   // ORI
                    3'b111:  alu_ctrl = ALU_AND;  // ANDI
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            default: alu_ctrl = ALU_ADD;
        endcase
    end

endmodule
