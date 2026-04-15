// =============================================================
// imm_gen.v - Immediate Generator (Sign Extender)
// Decodes all RV32I immediate formats: I, S, B, U, J
// =============================================================

module imm_gen (
    input  [31:0] instruction,
    output reg [31:0] imm_ext
);
    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            // I-type: ADDI, LW, JALR
            7'b0010011, 7'b0000011, 7'b1100111:
                imm_ext = {{20{instruction[31]}}, instruction[31:20]};

            // S-type: SW
            7'b0100011:
                imm_ext = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

            // B-type: BEQ
            // Immediate is: [12|10:5|4:1|11], bit 0 always 0
            7'b1100011:
                imm_ext = {{19{instruction[31]}},
                            instruction[31],
                            instruction[7],
                            instruction[30:25],
                            instruction[11:8],
                            1'b0};

            // U-type: LUI
            7'b0110111:
                imm_ext = {instruction[31:12], 12'b0};

            // J-type: JAL
            // Immediate is: [20|10:1|11|19:12], bit 0 always 0
            7'b1101111:
                imm_ext = {{11{instruction[31]}},
                            instruction[31],
                            instruction[19:12],
                            instruction[20],
                            instruction[30:21],
                            1'b0};

            default: imm_ext = 32'b0;
        endcase
    end
endmodule
