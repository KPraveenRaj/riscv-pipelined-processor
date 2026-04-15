// =============================================================
// alu.v - 32-bit Arithmetic Logic Unit
// Supports: ADD, SUB, AND, OR, XOR, SLT, SLL, SRL, SRA, PASSB
// =============================================================
`include "defines.v"

module alu (
    input  [31:0] a,            // Operand A
    input  [31:0] b,            // Operand B
    input  [3:0]  alu_control,  // Operation select
    output reg [31:0] result,   // ALU output
    output             zero     // High when result == 0 (used by BEQ)
);
    always @(*) begin
        case (alu_control)
            `ALU_ADD:   result = a + b;
            `ALU_SUB:   result = a - b;
            `ALU_AND:   result = a & b;
            `ALU_OR:    result = a | b;
            `ALU_XOR:   result = a ^ b;
            `ALU_SLT:   result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            `ALU_SLL:   result = a << b[4:0];
            `ALU_SRL:   result = a >> b[4:0];
            `ALU_SRA:   result = $signed(a) >>> b[4:0];
            `ALU_PASSB: result = b;
            default:    result = 32'b0;
        endcase
    end

    assign zero = (result == 32'b0);
endmodule
