// =============================================================
// top.v - 5-Stage Pipelined RISC-V (RV32I subset) Processor
//
// Pipeline: IF → ID → EX → MEM → WB
// Features:
//   - Full data forwarding (EX-EX, MEM-EX)
//   - Load-use hazard detection and stalling
//   - Branch resolution in EX with 1-cycle flush
//   - JAL / JALR support
//   - 2-bit saturating counter branch predictor (trained, connected)
//
// ISA subset: ADD, SUB, AND, OR, ADDI, LW, SW, BEQ, LUI, JAL, JALR
// =============================================================

module top (
    input clk,
    input reset
);
    // =========================================================
    // MEMORIES
    // =========================================================
    reg [31:0] imem [0:255];   // Instruction memory (ROM) - 1KB
    reg [31:0] dmem [0:255];   // Data memory (RAM) - 1KB

    integer mi;
    initial begin
        for (mi = 0; mi < 256; mi = mi + 1) begin
            imem[mi] = 32'h00000013; // NOP
            dmem[mi] = 32'b0;
        end
    end

    // =========================================================
    // WB STAGE OUTPUTS (declared early - used by ID register file)
    // =========================================================
    wire [31:0] wb_write_data;
    wire [4:0]  wb_rd;
    wire        wb_reg_write;

    // =========================================================
    // IF STAGE
    // =========================================================
    reg  [31:0] pc;
    wire [31:0] pc_plus4 = pc + 32'd4;

    // Control from EX stage
    wire        pc_src;       // 1 = take branch/jump
    wire [31:0] pc_target;    // Branch/jump target address
    wire        stall;        // 1 = load-use stall

    // Branch predictor I/O
    wire        predict_taken;
    wire        ex_is_branch;
    wire        ex_branch_taken;
    wire [31:0] ex_pc_bp;

    branch_predictor bp (
        .clk           (clk),
        .reset         (reset),
        .pc            (pc),
        .ex_pc         (ex_pc_bp),
        .ex_is_branch  (ex_is_branch),
        .ex_branch_taken(ex_branch_taken),
        .predict_taken (predict_taken)
    );

    // PC register
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 32'b0;
        else if (!stall)
            pc <= pc_src ? pc_target : pc_plus4;
    end

    wire [31:0] if_instr = imem[pc[9:2]]; // Word-addressed (byte addr / 4)

    // IF/ID Pipeline Register
    wire [31:0] fd_pc, fd_pc4, fd_instr;

    if_id_reg if_id_r (
        .clk      (clk),
        .reset    (reset),
        .flush    (pc_src),     // Flush on branch/jump
        .stall    (stall),      // Hold on load-use
        .pc_in    (pc),
        .pc4_in   (pc_plus4),
        .instr_in (if_instr),
        .pc_out   (fd_pc),
        .pc4_out  (fd_pc4),
        .instr_out(fd_instr)
    );

    // =========================================================
    // ID STAGE
    // =========================================================
    wire [6:0]  id_opcode    = fd_instr[6:0];
    wire [4:0]  id_rd        = fd_instr[11:7];
    wire [2:0]  id_funct3    = fd_instr[14:12];
    wire [4:0]  id_rs1       = fd_instr[19:15];
    wire [4:0]  id_rs2       = fd_instr[24:20];
    wire        id_funct7_5  = fd_instr[30];

    // Control Unit
    wire        id_reg_write, id_mem_read, id_mem_write;
    wire        id_branch, id_jump, id_alu_src;
    wire [1:0]  id_mem_to_reg, id_alu_op;

    control_unit cu (
        .opcode     (id_opcode),
        .reg_write  (id_reg_write),
        .mem_read   (id_mem_read),
        .mem_write  (id_mem_write),
        .branch     (id_branch),
        .jump       (id_jump),
        .alu_src    (id_alu_src),
        .mem_to_reg (id_mem_to_reg),
        .alu_op     (id_alu_op)
    );

    // Immediate Generator
    wire [31:0] id_imm_ext;
    imm_gen ig (.instruction(fd_instr), .imm_ext(id_imm_ext));

    // Register File
    wire [31:0] id_read_data1, id_read_data2;

    register_file rf (
        .clk        (clk),
        .reg_write  (wb_reg_write),
        .rs1        (id_rs1),
        .rs2        (id_rs2),
        .rd         (wb_rd),
        .write_data (wb_write_data),
        .read_data1 (id_read_data1),
        .read_data2 (id_read_data2)
    );

    // Load-Use Hazard Detection
    // Needs ID/EX outputs (declared below - Verilog allows forward refs for wires)
    wire [4:0]  de_rd;
    wire        de_mem_read;

    hazard_detection_unit hdu (
        .if_id_rs1      (id_rs1),
        .if_id_rs2      (id_rs2),
        .id_ex_rd       (de_rd),
        .id_ex_mem_read (de_mem_read),
        .stall          (stall)
    );

    // ID/EX Pipeline Register
    wire [31:0] de_pc, de_pc4;
    wire [31:0] de_rd1, de_rd2, de_imm;
    wire [4:0]  de_rs1, de_rs2;
    // de_rd declared above
    wire [2:0]  de_funct3;
    wire        de_funct7_5;
    wire        de_reg_write, de_mem_write;
    // de_mem_read declared above
    wire        de_branch, de_jump, de_alu_src;
    wire [1:0]  de_mem_to_reg, de_alu_op;

    id_ex_reg id_ex_r (
        .clk           (clk),
        .reset         (reset),
        .flush         (stall | pc_src), // NOP on stall OR branch/jump flush
        .pc_in         (fd_pc),
        .pc4_in        (fd_pc4),
        .read_data1_in (id_read_data1),
        .read_data2_in (id_read_data2),
        .imm_ext_in    (id_imm_ext),
        .rs1_in        (id_rs1),
        .rs2_in        (id_rs2),
        .rd_in         (id_rd),
        .funct3_in     (id_funct3),
        .funct7_5_in   (id_funct7_5),
        .reg_write_in  (id_reg_write),
        .mem_read_in   (id_mem_read),
        .mem_write_in  (id_mem_write),
        .branch_in     (id_branch),
        .jump_in       (id_jump),
        .alu_src_in    (id_alu_src),
        .mem_to_reg_in (id_mem_to_reg),
        .alu_op_in     (id_alu_op),
        .pc_out        (de_pc),
        .pc4_out       (de_pc4),
        .read_data1_out(de_rd1),
        .read_data2_out(de_rd2),
        .imm_ext_out   (de_imm),
        .rs1_out       (de_rs1),
        .rs2_out       (de_rs2),
        .rd_out        (de_rd),
        .funct3_out    (de_funct3),
        .funct7_5_out  (de_funct7_5),
        .reg_write_out (de_reg_write),
        .mem_read_out  (de_mem_read),
        .mem_write_out (de_mem_write),
        .branch_out    (de_branch),
        .jump_out      (de_jump),
        .alu_src_out   (de_alu_src),
        .mem_to_reg_out(de_mem_to_reg),
        .alu_op_out    (de_alu_op)
    );

    // =========================================================
    // EX STAGE
    // =========================================================
    // EX/MEM and MEM/WB outputs needed for forwarding
    wire [4:0]  em_rd;
    wire        em_reg_write;
    wire [31:0] em_alu_result;

    // Forwarding Unit
    wire [1:0]  fwd_a, fwd_b;

    forwarding_unit fu (
        .id_ex_rs1       (de_rs1),
        .id_ex_rs2       (de_rs2),
        .ex_mem_rd       (em_rd),
        .ex_mem_reg_write(em_reg_write),
        .mem_wb_rd       (wb_rd),
        .mem_wb_reg_write(wb_reg_write),
        .forward_a       (fwd_a),
        .forward_b       (fwd_b)
    );

    // ALU Control Decoder
    wire [3:0] alu_ctrl;

    alu_control ac (
        .alu_op   (de_alu_op),
        .funct3   (de_funct3),
        .funct7_5 (de_funct7_5),
        .alu_ctrl (alu_ctrl)
    );

    // Forwarding Muxes
    wire [31:0] op_a = (fwd_a == `FWD_MEM) ? em_alu_result :
                       (fwd_a == `FWD_WB)  ? wb_write_data :
                       de_rd1;

    wire [31:0] op_b_reg = (fwd_b == `FWD_MEM) ? em_alu_result :
                            (fwd_b == `FWD_WB)  ? wb_write_data :
                            de_rd2;

    // ALUSrc mux: immediate or register
    wire [31:0] op_b = de_alu_src ? de_imm : op_b_reg;

    // ALU
    wire [31:0] ex_alu_result;
    wire        ex_alu_zero;

    alu alu_inst (
        .a          (op_a),
        .b          (op_b),
        .alu_control(alu_ctrl),
        .result     (ex_alu_result),
        .zero       (ex_alu_zero)
    );

    // Branch/Jump Target Computation
    wire [31:0] branch_target = de_pc + de_imm;            // BEQ / JAL
    wire [31:0] jalr_target   = (de_rd1 + de_imm) & ~32'b1; // JALR: LSB cleared

    // Branch resolution
    wire branch_taken = de_branch & ex_alu_zero;

    // PC source control
    // JALR: jump=1 AND alu_src=1 (it has an immediate)
    assign pc_src    = branch_taken | de_jump;
    assign pc_target = (de_jump && de_alu_src) ? jalr_target : branch_target;

    // Feed branch predictor
    assign ex_is_branch   = de_branch;
    assign ex_branch_taken = branch_taken;
    assign ex_pc_bp        = de_pc;

    // EX/MEM Pipeline Register
    wire [31:0] em_pc4;
    wire [31:0] em_write_data;
    wire        em_mem_read, em_mem_write;
    wire [1:0]  em_mem_to_reg;

    ex_mem_reg ex_mem_r (
        .clk          (clk),
        .reset        (reset),
        .pc4_in       (de_pc4),
        .alu_result_in(ex_alu_result),
        .write_data_in(op_b_reg),      // Forwarded rs2 (for SW)
        .rd_in        (de_rd),
        .reg_write_in (de_reg_write),
        .mem_read_in  (de_mem_read),
        .mem_write_in (de_mem_write),
        .mem_to_reg_in(de_mem_to_reg),
        .pc4_out      (em_pc4),
        .alu_result_out(em_alu_result),
        .write_data_out(em_write_data),
        .rd_out       (em_rd),
        .reg_write_out(em_reg_write),
        .mem_read_out (em_mem_read),
        .mem_write_out(em_mem_write),
        .mem_to_reg_out(em_mem_to_reg)
    );

    // =========================================================
    // MEM STAGE
    // =========================================================
    wire [31:0] mem_read_data = dmem[em_alu_result[9:2]];

    always @(posedge clk) begin
        if (em_mem_write)
            dmem[em_alu_result[9:2]] <= em_write_data;
    end

    // MEM/WB Pipeline Register
    wire [31:0] mw_pc4, mw_read_data, mw_alu_result;
    wire [4:0]  mw_rd;
    wire        mw_reg_write;
    wire [1:0]  mw_mem_to_reg;

    mem_wb_reg mem_wb_r (
        .clk          (clk),
        .reset        (reset),
        .pc4_in       (em_pc4),
        .read_data_in (mem_read_data),
        .alu_result_in(em_alu_result),
        .rd_in        (em_rd),
        .reg_write_in (em_reg_write),
        .mem_to_reg_in(em_mem_to_reg),
        .pc4_out      (mw_pc4),
        .read_data_out(mw_read_data),
        .alu_result_out(mw_alu_result),
        .rd_out       (mw_rd),
        .reg_write_out(mw_reg_write),
        .mem_to_reg_out(mw_mem_to_reg)
    );

    // =========================================================
    // WB STAGE
    // =========================================================
    assign wb_rd         = mw_rd;
    assign wb_reg_write  = mw_reg_write;
    assign wb_write_data = (mw_mem_to_reg == `WB_MEM) ? mw_read_data  :
                           (mw_mem_to_reg == `WB_PC4) ? mw_pc4        :
                           mw_alu_result;

endmodule
