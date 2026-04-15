// =============================================================
// branch_predictor.v - 2-bit Saturating Counter Branch Predictor
//
// 4-entry direct-mapped table, indexed by PC[3:2].
// Each entry is a 2-bit saturating counter:
//   00 = Strongly Not Taken
//   01 = Weakly   Not Taken  (initial state)
//   10 = Weakly   Taken
//   11 = Strongly Taken
//
// predict_taken is asserted when MSB of counter = 1.
//
// NOTE: In this design the predictor is trained by EX-stage
// branch outcomes. The predict_taken output is available for
// future integration with speculative PC redirection.
// Currently the processor resolves branches in EX (1-cycle flush).
// =============================================================

module branch_predictor (
    input         clk,
    input         reset,
    input  [31:0] pc,               // PC of instruction being fetched
    input  [31:0] ex_pc,            // PC of branch currently in EX stage
    input         ex_is_branch,     // High if EX-stage instruction is a branch
    input         ex_branch_taken,  // Actual branch outcome from EX
    output        predict_taken     // Prediction for current fetch PC
);
    reg [1:0] counter [0:3];        // 4 x 2-bit saturating counters
    integer i;

    initial begin
        for (i = 0; i < 4; i = i + 1)
            counter[i] = 2'b01;    // Start weakly not-taken
    end

    wire [1:0] fetch_idx  = pc[3:2];
    wire [1:0] update_idx = ex_pc[3:2];

    // Prediction: high when counter MSB = 1
    assign predict_taken = counter[fetch_idx][1];

    // Update counter on each resolved branch
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 4; i = i + 1)
                counter[i] <= 2'b01;
        end else if (ex_is_branch) begin
            if (ex_branch_taken)
                counter[update_idx] <= (counter[update_idx] == 2'b11) ?
                                        2'b11 : counter[update_idx] + 1;
            else
                counter[update_idx] <= (counter[update_idx] == 2'b00) ?
                                        2'b00 : counter[update_idx] - 1;
        end
    end
endmodule
