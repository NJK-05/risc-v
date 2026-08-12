// MEM/WB Pipeline Register
// Latches memory-stage outputs for use in write-back.

module mem_wb_reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,
    input  wire        flush,

    // Datapath values
    input  wire [31:0] mem_read_data_in,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] pc_plus4_in,     // return address for JAL/JALR
    input  wire [4:0]  rd_addr_in,

    // Control signals (names match control_unit.v exactly)
    input  wire        reg_write_in,
    input  wire [1:0]  result_src_in,

    output reg  [31:0] mem_read_data_out,
    output reg  [31:0] alu_result_out,
    output reg  [31:0] pc_plus4_out,
    output reg  [4:0]  rd_addr_out,

    output reg         reg_write_out,
    output reg  [1:0]  result_src_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_read_data_out <= 32'd0;
            alu_result_out    <= 32'd0;
            pc_plus4_out      <= 32'd0;
            rd_addr_out       <= 5'd0;

            reg_write_out     <= 1'b0;
            result_src_out    <= 2'b00;
        end else if (flush) begin
            mem_read_data_out <= 32'd0;
            alu_result_out    <= 32'd0;
            pc_plus4_out      <= 32'd0;
            rd_addr_out       <= 5'd0;

            reg_write_out     <= 1'b0;
            result_src_out    <= 2'b00;
        end else if (!stall) begin
            mem_read_data_out <= mem_read_data_in;
            alu_result_out    <= alu_result_in;
            pc_plus4_out      <= pc_plus4_in;
            rd_addr_out       <= rd_addr_in;

            reg_write_out     <= reg_write_in;
            result_src_out    <= result_src_in;
        end
        // else: stall with no flush -> hold current values
    end

endmodule
