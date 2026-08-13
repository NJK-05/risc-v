// 5-stage pipelined RV32I core.
// IF -> ID -> EX -> MEM -> WB via if_id_reg, id_ex_reg, ex_mem_reg, mem_wb_reg.
// Forwarding resolves EX-stage RAW hazards from EX/MEM and MEM/WB.
// Not yet handled: load-use stall, branch/jump flush (stale in-flight
// instructions on a taken branch aren't squashed yet).

module riscv_core_top (
    input wire clk,
    input wire rst_n
);

    // ================= IF stage =================
    wire [31:0] pc, pc_next, pc_plus4_if, instr_if;

    pc_reg pc_reg_inst (
        .clk(clk), .rst_n(rst_n), .pc_next(pc_next), .pc(pc)
    );

    imem imem_inst (
        .addr(pc), .instr(instr_if)
    );

    assign pc_plus4_if = pc + 32'd4;

    // Redirected by EX-stage branch/jump resolution (see below); flush
    // not yet applied to in-flight instructions.
    wire        pc_src_ex;
    wire [31:0] pc_target_ex;
    assign pc_next = pc_src_ex ? pc_target_ex : pc_plus4_if;

    // ---- IF/ID ----
    wire [31:0] if_id_pc, if_id_pc_plus4, if_id_instr;

    if_id_reg if_id_reg_inst (
        .clk(clk), .rst_n(rst_n),
        .stall(1'b0), .flush(1'b0),
        .pc_in(pc), .pc_plus4_in(pc_plus4_if), .instr_in(instr_if),
        .pc_out(if_id_pc), .pc_plus4_out(if_id_pc_plus4), .instr_out(if_id_instr)
    );

    // ================= ID stage =================
    wire [6:0] opcode_id   = if_id_instr[6:0];
    wire [4:0] rd_addr_id  = if_id_instr[11:7];
    wire [2:0] funct3_id   = if_id_instr[14:12];
    wire [4:0] rs1_addr_id = if_id_instr[19:15];
    wire [4:0] rs2_addr_id = if_id_instr[24:20];
    wire       funct7_5_id = if_id_instr[30];

    wire       reg_write_id, alu_src_id, mem_read_id, mem_write_id, branch_id, jump_id;
    wire [1:0] alu_src_a_id, result_src_id, alu_op_id;

    control_unit control_inst (
        .opcode(opcode_id),
        .reg_write(reg_write_id), .alu_src(alu_src_id), .alu_src_a(alu_src_a_id),
        .mem_read(mem_read_id), .mem_write(mem_write_id), .result_src(result_src_id),
        .branch(branch_id), .jump(jump_id), .alu_op(alu_op_id)
    );

    wire [31:0] imm_id;
    imm_gen imm_gen_inst (
        .instr(if_id_instr), .imm(imm_id)
    );

    wire [31:0] rs1_data_id, rs2_data_id;

    // Write port driven by WB stage (see bottom of module).
    wire        mem_wb_reg_write;
    wire [4:0]  mem_wb_rd_addr;
    wire [31:0] write_back_data;

    regfile regfile_inst (
        .clk(clk), .rst_n(rst_n),
        .we(mem_wb_reg_write), .rs1_addr(rs1_addr_id), .rs2_addr(rs2_addr_id),
        .rd_addr(mem_wb_rd_addr), .rd_data(write_back_data),
        .rs1_data(rs1_data_id), .rs2_data(rs2_data_id)
    );

    // ---- ID/EX ----
    wire [31:0] id_ex_pc, id_ex_pc_plus4, id_ex_rs1_data, id_ex_rs2_data, id_ex_imm;
    wire [4:0]  id_ex_rs1_addr, id_ex_rs2_addr, id_ex_rd_addr;
    wire [2:0]  id_ex_funct3;
    wire        id_ex_funct7_5;
    wire        id_ex_reg_write, id_ex_alu_src, id_ex_mem_read, id_ex_mem_write, id_ex_branch, id_ex_jump;
    wire [1:0]  id_ex_alu_src_a, id_ex_result_src, id_ex_alu_op;

    id_ex_reg id_ex_reg_inst (
        .clk(clk), .rst_n(rst_n),
        .stall(1'b0), .flush(1'b0),
        .pc_in(if_id_pc), .pc_plus4_in(if_id_pc_plus4),
        .rs1_data_in(rs1_data_id), .rs2_data_in(rs2_data_id), .imm_in(imm_id),
        .rs1_addr_in(rs1_addr_id), .rs2_addr_in(rs2_addr_id), .rd_addr_in(rd_addr_id),
        .funct3_in(funct3_id), .funct7_5_in(funct7_5_id),
        .reg_write_in(reg_write_id), .alu_src_in(alu_src_id), .alu_src_a_in(alu_src_a_id),
        .mem_read_in(mem_read_id), .mem_write_in(mem_write_id), .result_src_in(result_src_id),
        .branch_in(branch_id), .jump_in(jump_id), .alu_op_in(alu_op_id),

        .pc_out(id_ex_pc), .pc_plus4_out(id_ex_pc_plus4),
        .rs1_data_out(id_ex_rs1_data), .rs2_data_out(id_ex_rs2_data), .imm_out(id_ex_imm),
        .rs1_addr_out(id_ex_rs1_addr), .rs2_addr_out(id_ex_rs2_addr), .rd_addr_out(id_ex_rd_addr),
        .funct3_out(id_ex_funct3), .funct7_5_out(id_ex_funct7_5),
        .reg_write_out(id_ex_reg_write), .alu_src_out(id_ex_alu_src), .alu_src_a_out(id_ex_alu_src_a),
        .mem_read_out(id_ex_mem_read), .mem_write_out(id_ex_mem_write), .result_src_out(id_ex_result_src),
        .branch_out(id_ex_branch), .jump_out(id_ex_jump), .alu_op_out(id_ex_alu_op)
    );

    // ================= EX stage =================
    wire [3:0]  alu_ctrl;
    alu_control alu_control_inst (
        .alu_op(id_ex_alu_op), .funct3(id_ex_funct3), .funct7_5(id_ex_funct7_5),
        .alu_ctrl(alu_ctrl)
    );

    // Forwarding resolves RAW hazards from EX/MEM and MEM/WB. Load-use
    // (producer is a load, consumer immediately after) still needs a
    // stall or 1 manual NOP - EX/MEM only holds a load's address, not
    // its data, until MEM completes.
    wire [1:0] forward_a, forward_b;
    forwarding_unit forwarding_unit_inst (
        .id_ex_rs1_addr(id_ex_rs1_addr), .id_ex_rs2_addr(id_ex_rs2_addr),
        .ex_mem_rd_addr(ex_mem_rd_addr), .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd_addr(mem_wb_rd_addr), .mem_wb_reg_write(mem_wb_reg_write),
        .forward_a(forward_a), .forward_b(forward_b)
    );

    wire [31:0] fwd_rs1_data = (forward_a == 2'b10) ? ex_mem_alu_result :
                                (forward_a == 2'b01) ? write_back_data :
                                id_ex_rs1_data;

    wire [31:0] fwd_rs2_data = (forward_b == 2'b10) ? ex_mem_alu_result :
                                (forward_b == 2'b01) ? write_back_data :
                                id_ex_rs2_data;

    wire [31:0] alu_a, alu_b, alu_result;
    wire        alu_zero;

    // ALU operand A: rs1 (default, forwarded), PC (AUIPC), or zero (LUI)
    assign alu_a = (id_ex_alu_src_a == 2'b01) ? id_ex_pc :
                   (id_ex_alu_src_a == 2'b10) ? 32'd0 :
                   fwd_rs1_data;

    // ALU operand B: rs2 (R-type/branch, forwarded) or immediate (everything else)
    assign alu_b = id_ex_alu_src ? id_ex_imm : fwd_rs2_data;

    alu alu_inst (
        .a(alu_a), .b(alu_b), .alu_op(alu_ctrl),
        .result(alu_result), .zero(alu_zero)
    );

    // JALR target: rs1 + imm (already computed by the ALU above), LSB cleared
    wire [31:0] jalr_target = {alu_result[31:1], 1'b0};

    // Branch/JAL target: shared adder using the EX-stage PC + imm
    wire [31:0] branch_target_ex = id_ex_pc + id_ex_imm;

    // Branch condition evaluation - reuses the ALU result computed above
    reg branch_taken_r;
    always @(*) begin
        case (id_ex_funct3)
            3'b000:  branch_taken_r = alu_zero;       // BEQ
            3'b001:  branch_taken_r = ~alu_zero;      // BNE
            3'b100:  branch_taken_r = alu_result[0];  // BLT  (SLT result)
            3'b101:  branch_taken_r = ~alu_result[0]; // BGE
            3'b110:  branch_taken_r = alu_result[0];  // BLTU (SLTU result)
            3'b111:  branch_taken_r = ~alu_result[0]; // BGEU
            default: branch_taken_r = 1'b0;
        endcase
    end

    wire ex_branch_taken = id_ex_branch & branch_taken_r;
    // JAL: jump=1, alu_src=0 (control_unit.v never sets alu_src for JAL)
    // JALR: jump=1, alu_src=1 (control_unit.v sets alu_src for JALR)
    wire ex_jump_jal  = id_ex_jump & ~id_ex_alu_src;
    wire ex_jump_jalr = id_ex_jump &  id_ex_alu_src;

    assign pc_src_ex    = ex_jump_jal | ex_jump_jalr | ex_branch_taken;
    assign pc_target_ex = ex_jump_jalr ? jalr_target : branch_target_ex;

    // ---- EX/MEM ----
    wire [31:0] ex_mem_alu_result, ex_mem_rs2_data, ex_mem_pc_plus4;
    wire [4:0]  ex_mem_rd_addr;
    wire [2:0]  ex_mem_funct3;
    wire [31:0] ex_mem_branch_target;
    wire        ex_mem_branch_taken;
    wire        ex_mem_reg_write, ex_mem_mem_read, ex_mem_mem_write;
    wire [1:0]  ex_mem_result_src;

    ex_mem_reg ex_mem_reg_inst (
        .clk(clk), .rst_n(rst_n),
        .stall(1'b0), .flush(1'b0),
        .alu_result_in(alu_result), .rs2_data_in(fwd_rs2_data),
        .pc_plus4_in(id_ex_pc_plus4), .rd_addr_in(id_ex_rd_addr),
        .funct3_in(id_ex_funct3),
        .branch_target_in(branch_target_ex), .branch_taken_in(ex_branch_taken),
        .reg_write_in(id_ex_reg_write), .mem_read_in(id_ex_mem_read),
        .mem_write_in(id_ex_mem_write), .result_src_in(id_ex_result_src),

        .alu_result_out(ex_mem_alu_result), .rs2_data_out(ex_mem_rs2_data),
        .pc_plus4_out(ex_mem_pc_plus4), .rd_addr_out(ex_mem_rd_addr),
        .funct3_out(ex_mem_funct3),
        .branch_target_out(ex_mem_branch_target), .branch_taken_out(ex_mem_branch_taken),
        .reg_write_out(ex_mem_reg_write), .mem_read_out(ex_mem_mem_read),
        .mem_write_out(ex_mem_mem_write), .result_src_out(ex_mem_result_src)
    );

    // ================= MEM stage =================
    wire [31:0] mem_read_data;

    dmem dmem_inst (
        .clk(clk), .mem_read(ex_mem_mem_read), .mem_write(ex_mem_mem_write),
        .addr(ex_mem_alu_result), .write_data(ex_mem_rs2_data), .funct3(ex_mem_funct3),
        .read_data(mem_read_data)
    );

    // ---- MEM/WB ----
    wire [31:0] mem_wb_mem_read_data, mem_wb_alu_result, mem_wb_pc_plus4;
    wire [1:0]  mem_wb_result_src;

    mem_wb_reg mem_wb_reg_inst (
        .clk(clk), .rst_n(rst_n),
        .stall(1'b0), .flush(1'b0),
        .mem_read_data_in(mem_read_data), .alu_result_in(ex_mem_alu_result),
        .pc_plus4_in(ex_mem_pc_plus4), .rd_addr_in(ex_mem_rd_addr),
        .reg_write_in(ex_mem_reg_write), .result_src_in(ex_mem_result_src),

        .mem_read_data_out(mem_wb_mem_read_data), .alu_result_out(mem_wb_alu_result),
        .pc_plus4_out(mem_wb_pc_plus4), .rd_addr_out(mem_wb_rd_addr),
        .reg_write_out(mem_wb_reg_write), .result_src_out(mem_wb_result_src)
    );

    // ================= WB stage =================
    assign write_back_data = (mem_wb_result_src == 2'b01) ? mem_wb_mem_read_data :
                              (mem_wb_result_src == 2'b10) ? mem_wb_pc_plus4 :
                              mem_wb_alu_result; // result_src == 2'b00

endmodule
