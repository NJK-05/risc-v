// ID/EX Pipeline Register

module id_ex_reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,
    input  wire        flush,

    // Datapath values
    input  wire [31:0] pc_in,
    input  wire [31:0] pc_plus4_in,
    input  wire [31:0] rs1_data_in,
    input  wire [31:0] rs2_data_in,
    input  wire [31:0] imm_in,
    input  wire [4:0]  rs1_addr_in,
    input  wire [4:0]  rs2_addr_in,
    input  wire [4:0]  rd_addr_in,
    input  wire [2:0]  funct3_in,
    input  wire        funct7_5_in,

    // Control signals (names match control_unit.v exactly)
    input  wire        reg_write_in,
    input  wire        alu_src_in,
    input  wire [1:0]  alu_src_a_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire [1:0]  result_src_in,
    input  wire        branch_in,
    input  wire        jump_in,
    input  wire [1:0]  alu_op_in,

    output reg  [31:0] pc_out,
    output reg  [31:0] pc_plus4_out,
    output reg  [31:0] rs1_data_out,
    output reg  [31:0] rs2_data_out,
    output reg  [31:0] imm_out,
    output reg  [4:0]  rs1_addr_out,
    output reg  [4:0]  rs2_addr_out,
    output reg  [4:0]  rd_addr_out,
    output reg  [2:0]  funct3_out,
    output reg         funct7_5_out,

    output reg         reg_write_out,
    output reg         alu_src_out,
    output reg  [1:0]  alu_src_a_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg  [1:0]  result_src_out,
    output reg         branch_out,
    output reg         jump_out,
    output reg  [1:0]  alu_op_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out         <= 32'd0;
            pc_plus4_out   <= 32'd0;
            rs1_data_out   <= 32'd0;
            rs2_data_out   <= 32'd0;
            imm_out        <= 32'd0;
            rs1_addr_out   <= 5'd0;
            rs2_addr_out   <= 5'd0;
            rd_addr_out    <= 5'd0;
            funct3_out     <= 3'd0;
            funct7_5_out   <= 1'b0;

            reg_write_out  <= 1'b0;
            alu_src_out    <= 1'b0;
            alu_src_a_out  <= 2'b00;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            result_src_out <= 2'b00;
            branch_out     <= 1'b0;
            jump_out       <= 1'b0;
            alu_op_out     <= 2'b00;
        end else if (flush) begin
            // Datapath values don't matter for a bubble, but zero them for
            // clean waveforms; only the control signals actually matter for
            // correctness (they must all read as the safe-NOP state).
            pc_out         <= 32'd0;
            pc_plus4_out   <= 32'd0;
            rs1_data_out   <= 32'd0;
            rs2_data_out   <= 32'd0;
            imm_out        <= 32'd0;
            rs1_addr_out   <= 5'd0;
            rs2_addr_out   <= 5'd0;
            rd_addr_out    <= 5'd0;
            funct3_out     <= 3'd0;
            funct7_5_out   <= 1'b0;

            reg_write_out  <= 1'b0;
            alu_src_out    <= 1'b0;
            alu_src_a_out  <= 2'b00;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            result_src_out <= 2'b00;
            branch_out     <= 1'b0;
            jump_out       <= 1'b0;
            alu_op_out     <= 2'b00;
        end else if (!stall) begin
            pc_out         <= pc_in;
            pc_plus4_out   <= pc_plus4_in;
            rs1_data_out   <= rs1_data_in;
            rs2_data_out   <= rs2_data_in;
            imm_out        <= imm_in;
            rs1_addr_out   <= rs1_addr_in;
            rs2_addr_out   <= rs2_addr_in;
            rd_addr_out    <= rd_addr_in;
            funct3_out     <= funct3_in;
            funct7_5_out   <= funct7_5_in;

            reg_write_out  <= reg_write_in;
            alu_src_out    <= alu_src_in;
            alu_src_a_out  <= alu_src_a_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            result_src_out <= result_src_in;
            branch_out     <= branch_in;
            jump_out       <= jump_in;
            alu_op_out     <= alu_op_in;
        end
        // else: stall with no flush -> hold current values
    end

endmodule
