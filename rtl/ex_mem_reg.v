// EX/MEM Pipeline Register

module ex_mem_reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,
    input  wire        flush,

    // Datapath values
    input  wire [31:0] alu_result_in,
    input  wire [31:0] rs2_data_in,     // store write-data
    input  wire [31:0] pc_plus4_in,     // return address for JAL/JALR
    input  wire [4:0]  rd_addr_in,
    input  wire [2:0]  funct3_in,       // load/store size, passed to dmem
    input  wire [31:0] branch_target_in,
    input  wire        branch_taken_in,

    // Control signals (names match control_unit.v exactly)
    input  wire        reg_write_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire [1:0]  result_src_in,

    output reg  [31:0] alu_result_out,
    output reg  [31:0] rs2_data_out,
    output reg  [31:0] pc_plus4_out,
    output reg  [4:0]  rd_addr_out,
    output reg  [2:0]  funct3_out,
    output reg  [31:0] branch_target_out,
    output reg         branch_taken_out,

    output reg         reg_write_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg  [1:0]  result_src_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_result_out    <= 32'd0;
            rs2_data_out      <= 32'd0;
            pc_plus4_out      <= 32'd0;
            rd_addr_out       <= 5'd0;
            funct3_out        <= 3'd0;
            branch_target_out <= 32'd0;
            branch_taken_out  <= 1'b0;

            reg_write_out     <= 1'b0;
            mem_read_out      <= 1'b0;
            mem_write_out     <= 1'b0;
            result_src_out    <= 2'b00;
        end else if (flush) begin
            alu_result_out    <= 32'd0;
            rs2_data_out      <= 32'd0;
            pc_plus4_out      <= 32'd0;
            rd_addr_out       <= 5'd0;
            funct3_out        <= 3'd0;
            branch_target_out <= 32'd0;
            branch_taken_out  <= 1'b0;

            reg_write_out     <= 1'b0;
            mem_read_out      <= 1'b0;
            mem_write_out     <= 1'b0;
            result_src_out    <= 2'b00;
        end else if (!stall) begin
            alu_result_out    <= alu_result_in;
            rs2_data_out      <= rs2_data_in;
            pc_plus4_out      <= pc_plus4_in;
            rd_addr_out       <= rd_addr_in;
            funct3_out        <= funct3_in;
            branch_target_out <= branch_target_in;
            branch_taken_out  <= branch_taken_in;

            reg_write_out     <= reg_write_in;
            mem_read_out      <= mem_read_in;
            mem_write_out     <= mem_write_in;
            result_src_out    <= result_src_in;
        end
        // else: stall with no flush -> hold current values
    end

endmodule
