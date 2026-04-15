// =============================================================
// forwarding_unit.v - Data Forwarding Unit
//
// Resolves EX-EX and MEM-EX RAW (Read After Write) hazards
// by selecting the most recent value for ALU inputs.
//
// Priority: EX/MEM forwarding > MEM/WB forwarding > register file
//
// forward_a / forward_b encoding:
//   00 = no forward  -> use ID/EX register file value
//   01 = MEM-EX fwd  -> use MEM/WB stage result (WB)
//   10 = EX-EX  fwd  -> use EX/MEM stage result (MEM)
// =============================================================
`include "defines.v"

module forwarding_unit (
    input  [4:0] id_ex_rs1,          // rs1 of instruction in EX
    input  [4:0] id_ex_rs2,          // rs2 of instruction in EX
    input  [4:0] ex_mem_rd,          // rd of instruction in MEM
    input        ex_mem_reg_write,   // MEM stage writes a register?
    input  [4:0] mem_wb_rd,          // rd of instruction in WB
    input        mem_wb_reg_write,   // WB stage writes a register?
    output reg [1:0] forward_a,      // Mux select for ALU operand A
    output reg [1:0] forward_b       // Mux select for ALU operand B
);
    always @(*) begin
        // ---------- Operand A (rs1) ----------
        if (ex_mem_reg_write &&
            (ex_mem_rd != 5'b0) &&
            (ex_mem_rd == id_ex_rs1))
            forward_a = `FWD_MEM;                   // EX-EX forward
        else if (mem_wb_reg_write &&
                 (mem_wb_rd != 5'b0) &&
                 (mem_wb_rd == id_ex_rs1))
            forward_a = `FWD_WB;                    // MEM-EX forward
        else
            forward_a = `FWD_NONE;

        // ---------- Operand B (rs2) ----------
        if (ex_mem_reg_write &&
            (ex_mem_rd != 5'b0) &&
            (ex_mem_rd == id_ex_rs2))
            forward_b = `FWD_MEM;
        else if (mem_wb_reg_write &&
                 (mem_wb_rd != 5'b0) &&
                 (mem_wb_rd == id_ex_rs2))
            forward_b = `FWD_WB;
        else
            forward_b = `FWD_NONE;
    end
endmodule
