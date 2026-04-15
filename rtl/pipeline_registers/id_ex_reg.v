// =============================================================
// id_ex_reg.v - ID/EX Pipeline Register
// Clocked buffer between Decode and Execute stages.
// flush: insert NOP bubble (load-use stall inserts bubble here)
// =============================================================

module id_ex_reg (
    input         clk,
    input         reset,
    input         flush,          // Insert NOP (load-use stall)
    // --- Data inputs ---
    input  [31:0] pc_in,
    input  [31:0] pc4_in,
    input  [31:0] read_data1_in,
    input  [31:0] read_data2_in,
    input  [31:0] imm_ext_in,
    input  [4:0]  rs1_in,
    input  [4:0]  rs2_in,
    input  [4:0]  rd_in,
    input  [2:0]  funct3_in,
    input         funct7_5_in,
    // --- Control inputs ---
    input         reg_write_in,
    input         mem_read_in,
    input         mem_write_in,
    input         branch_in,
    input         jump_in,
    input         alu_src_in,
    input  [1:0]  mem_to_reg_in,
    input  [1:0]  alu_op_in,
    // --- Data outputs ---
    output reg [31:0] pc_out,
    output reg [31:0] pc4_out,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] imm_ext_out,
    output reg [4:0]  rs1_out,
    output reg [4:0]  rs2_out,
    output reg [4:0]  rd_out,
    output reg [2:0]  funct3_out,
    output reg        funct7_5_out,
    // --- Control outputs ---
    output reg        reg_write_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg        branch_out,
    output reg        jump_out,
    output reg        alu_src_out,
    output reg [1:0]  mem_to_reg_out,
    output reg [1:0]  alu_op_out
);
    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            pc_out <= 0; pc4_out <= 0;
            read_data1_out <= 0; read_data2_out <= 0;
            imm_ext_out <= 0;
            rs1_out <= 0; rs2_out <= 0; rd_out <= 0;
            funct3_out <= 0; funct7_5_out <= 0;
            // Zero all control signals = NOP
            reg_write_out <= 0; mem_read_out <= 0; mem_write_out <= 0;
            branch_out <= 0; jump_out <= 0; alu_src_out <= 0;
            mem_to_reg_out <= 0; alu_op_out <= 0;
        end else begin
            pc_out <= pc_in; pc4_out <= pc4_in;
            read_data1_out <= read_data1_in;
            read_data2_out <= read_data2_in;
            imm_ext_out <= imm_ext_in;
            rs1_out <= rs1_in; rs2_out <= rs2_in; rd_out <= rd_in;
            funct3_out <= funct3_in; funct7_5_out <= funct7_5_in;
            reg_write_out <= reg_write_in; mem_read_out <= mem_read_in;
            mem_write_out <= mem_write_in; branch_out <= branch_in;
            jump_out <= jump_in; alu_src_out <= alu_src_in;
            mem_to_reg_out <= mem_to_reg_in; alu_op_out <= alu_op_in;
        end
    end
endmodule
