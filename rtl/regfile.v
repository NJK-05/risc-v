// 32 x 32-bit register file
// - 2 combinational read ports (rs1, rs2)
// - 1 synchronous write port (rd), write-first so same-cycle read-after-write
//   in a later stage sees the new value once forwarding is added
// - x0 is hardwired to zero, writes to x0 are ignored

module regfile (
    input  wire        clk,
    input  wire        rst_n,

    input  wire         we,          // write enable
    input  wire [4:0]   rs1_addr,
    input  wire [4:0]   rs2_addr,
    input  wire [4:0]   rd_addr,
    input  wire [31:0]  rd_data,

    output wire [31:0]  rs1_data,
    output wire [31:0]  rs2_data
);

    reg [31:0] regs [0:31];
    integer i;

    // Combinational reads, with x0 forced to zero
    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : regs[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : regs[rs2_addr];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;
        end else if (we && rd_addr != 5'd0) begin
            regs[rd_addr] <= rd_data;
        end
    end

endmodule
