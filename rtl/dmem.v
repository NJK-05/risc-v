// Data memory - simulation model
// Byte-addressable, little-endian, supports LB/LH/LW/LBU/LHU and SB/SH/SW sizing via funct3 

module dmem #(
    parameter DEPTH = 4096   // bytes (4KB default)
) (
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    input  wire [2:0]  funct3,
    output reg  [31:0] read_data
);

    reg [7:0] mem [0:DEPTH-1];

    // Synchronous write - real memory behaviour, and matches the
    // single-cycle datapath committing all state on the same clock edge
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: begin // SB
                    mem[addr] <= write_data[7:0];
                end
                3'b001: begin // SH
                    mem[addr]   <= write_data[7:0];
                    mem[addr+1] <= write_data[15:8];
                end
                3'b010: begin // SW
                    mem[addr]   <= write_data[7:0];
                    mem[addr+1] <= write_data[15:8];
                    mem[addr+2] <= write_data[23:16];
                    mem[addr+3] <= write_data[31:24];
                end
                default: ; // no-op for unrecognised funct3
            endcase
        end
    end

    // Combinational read - real hardware would gate this behind mem_read,
    // but since this is a sim model and result_src already ignores
    // read_data when not a load, always computing it is harmless
    always @(*) begin
        case (funct3)
            3'b000:  read_data = {{24{mem[addr][7]}}, mem[addr]};                          // LB (sign-extend)
            3'b001:  read_data = {{16{mem[addr+1][7]}}, mem[addr+1], mem[addr]};           // LH (sign-extend)
            3'b010:  read_data = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};       // LW
            3'b100:  read_data = {24'b0, mem[addr]};                                       // LBU (zero-extend)
            3'b101:  read_data = {16'b0, mem[addr+1], mem[addr]};                          // LHU (zero-extend)
            default: read_data = 32'd0;
        endcase
    end

endmodule
