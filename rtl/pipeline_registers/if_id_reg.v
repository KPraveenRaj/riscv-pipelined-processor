// =============================================================
// if_id_reg.v - IF/ID Pipeline Register
// Clocked buffer between Instruction Fetch and Decode stages.
// flush: insert NOP (on branch/jump)
// stall: hold current value (on load-use hazard)
// =============================================================

module if_id_reg (
    input         clk,
    input         reset,
    input         flush,        // 1 = clear to NOP (branch taken)
    input         stall,        // 1 = hold current value (load-use)
    input  [31:0] pc_in,        // Current PC
    input  [31:0] pc4_in,       // PC + 4
    input  [31:0] instr_in,     // Fetched instruction
    output reg [31:0] pc_out,
    output reg [31:0] pc4_out,
    output reg [31:0] instr_out
);
    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            pc_out    <= 32'b0;
            pc4_out   <= 32'b0;
            instr_out <= 32'h00000013; // NOP = addi x0, x0, 0
        end else if (!stall) begin
            pc_out    <= pc_in;
            pc4_out   <= pc4_in;
            instr_out <= instr_in;
        end
        // stall: outputs hold their previous values implicitly
    end
endmodule
