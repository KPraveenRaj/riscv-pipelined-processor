// =============================================================
// control_unit.v - Main Control Unit
// Decodes opcode and generates pipeline control signals.
//
// Supported instructions:
//   R-type : ADD, SUB, AND, OR (opcode=0110011)
//   I-type : ADDI              (opcode=0010011)
//   Load   : LW                (opcode=0000011)
//   Store  : SW                (opcode=0100011)
//   Branch : BEQ               (opcode=1100011)
//   U-type : LUI               (opcode=0110111)
//   J-type : JAL               (opcode=1101111)
//   Jump   : JALR              (opcode=1100111)
// =============================================================
`include "defines.v"

module control_unit (
    input  [6:0] opcode,
    output reg        reg_write,    // 1 = write to rd in WB
    output reg        mem_read,     // 1 = read from data memory
    output reg        mem_write,    // 1 = write to data memory
    output reg        branch,       // 1 = BEQ instruction
    output reg        jump,         // 1 = JAL or JALR
    output reg        alu_src,      // 0 = rs2, 1 = immediate
    output reg [1:0]  mem_to_reg,   // WB mux select (WB_ALU/WB_MEM/WB_PC4)
    output reg [1:0]  alu_op        // ALU operation class
);
    always @(*) begin
        // Safe defaults (NOP behaviour)
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_src    = 1'b0;
        mem_to_reg = `WB_ALU;
        alu_op     = `ALUOP_MEM;

        case (opcode)
            `OP_R: begin                       // ADD, SUB, AND, OR
                reg_write  = 1'b1;
                alu_op     = `ALUOP_REG;
            end

            `OP_I_ALU: begin                   // ADDI
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                alu_op     = `ALUOP_REG;
            end

            `OP_LOAD: begin                    // LW
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                alu_src    = 1'b1;
                mem_to_reg = `WB_MEM;
                alu_op     = `ALUOP_MEM;
            end

            `OP_STORE: begin                   // SW
                mem_write  = 1'b1;
                alu_src    = 1'b1;
                alu_op     = `ALUOP_MEM;
            end

            `OP_BRANCH: begin                  // BEQ
                branch     = 1'b1;
                alu_op     = `ALUOP_BR;
            end

            `OP_LUI: begin                     // LUI
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                alu_op     = `ALUOP_LUI;
            end

            `OP_JAL: begin                     // JAL
                reg_write  = 1'b1;
                jump       = 1'b1;
                mem_to_reg = `WB_PC4;
            end

            `OP_JALR: begin                    // JALR
                reg_write  = 1'b1;
                jump       = 1'b1;
                alu_src    = 1'b1;
                mem_to_reg = `WB_PC4;
                alu_op     = `ALUOP_MEM;       // rs1 + imm for target
            end

            default: begin end                 // NOP / unknown
        endcase
    end
endmodule
