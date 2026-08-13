module hazard_detection_unit (
    input  wire       id_ex_mem_read,
    input  wire [4:0] id_ex_rd_addr,

    input  wire [4:0] rs1_addr_id,
    input  wire [4:0] rs2_addr_id,

    output wire stall
);
    // Load currently in EX, its destination matches a source register of
    // the instruction currently in ID -> stall for 1 cycle. Forwarding
    // alone can't resolve this: EX/MEM only holds the load's address at
    // that point, not the data it's fetching.
    assign stall = id_ex_mem_read && (id_ex_rd_addr != 5'd0) &&
                   ((id_ex_rd_addr == rs1_addr_id) || (id_ex_rd_addr == rs2_addr_id));
endmodule
