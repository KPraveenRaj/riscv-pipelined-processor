// =============================================================
// alu_control.v - ALU Control Decoder
// Translates ALUOp + funct3 + funct7[5] -> 4-bit alu_control
// =============================================================
`include "defines.v"

module alu_control (
    input  [1:0] alu_op,       // From main control unit
    input  [2:0] funct3,       // From instruction[14:12]
    input        funct7_5,     // From instruction[30] (SUB/SRA distinguish)
    output reg [3:0] alu_ctrl  // To ALU
);
    always @(*) begin
        case (alu_op)
            `ALUOP_MEM: alu_ctrl = `ALU_ADD;   // LW/SW always ADD
            `ALUOP_BR:  alu_ctrl = `ALU_SUB;   // BEQ always SUB (check zero)
            `ALUOP_LUI: alu_ctrl = `ALU_PASSB; // LUI passes immediate unchanged

            `ALUOP_REG: begin  // R-type or I-type ALU
                case (funct3)
                    3'b000: alu_ctrl = funct7_5 ? `ALU_SUB : `ALU_ADD; // SUB or ADD/ADDI
                    3'b111: alu_ctrl = `ALU_AND;
                    3'b110: alu_ctrl = `ALU_OR;
                    3'b100: alu_ctrl = `ALU_XOR;
                    3'b010: alu_ctrl = `ALU_SLT;
                    3'b001: alu_ctrl = `ALU_SLL;
                    3'b101: alu_ctrl = funct7_5 ? `ALU_SRA : `ALU_SRL;
                    default: alu_ctrl = `ALU_ADD;
                endcase
            end

            default: alu_ctrl = `ALU_ADD;
        endcase
    end
endmodule
