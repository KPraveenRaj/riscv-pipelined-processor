`timescale 1ns/1ps
module tb_branch_predictor;
    reg        clk, reset;
    reg  [31:0] pc, ex_pc;
    reg         ex_is_branch, ex_branch_taken;
    wire        predict_taken;
    integer pass=0, fail=0;

    branch_predictor dut(.clk(clk),.reset(reset),.pc(pc),.ex_pc(ex_pc),
                          .ex_is_branch(ex_is_branch),.ex_branch_taken(ex_branch_taken),
                          .predict_taken(predict_taken));

    always #5 clk = ~clk;

    task check_pred;
        input exp; input [7:0] id;
        begin #1;
        if (predict_taken===exp) begin
            $display("  PASS [%0d]: predict_taken=%b",id,predict_taken); pass=pass+1;
        end else begin
            $display("  FAIL [%0d]: predict=%b exp=%b",id,predict_taken,exp); fail=fail+1;
        end end
    endtask

    initial begin
        $dumpfile("sim/results/tb_branch_predictor.vcd");
        $dumpvars(0,tb_branch_predictor);
        $display("\n========== Branch Predictor Test ==========");
        clk=0; reset=1; ex_is_branch=0; ex_branch_taken=0;
        pc=32'h10; ex_pc=32'h10;
        @(posedge clk); @(posedge clk);
        reset=0;

        // After reset: counter=01 (weakly not taken) → predict=0
        pc=32'h10; #1; check_pred(0,0);

        // Train TAKEN once → counter goes 01→10 (weakly taken) → predict=1
        @(posedge clk); ex_is_branch=1; ex_branch_taken=1; ex_pc=32'h10;
        @(posedge clk); ex_is_branch=0;
        pc=32'h10; #1; check_pred(1,1);

        // Train TAKEN again → 10→11 (strongly taken)
        @(posedge clk); ex_is_branch=1; ex_branch_taken=1; ex_pc=32'h10;
        @(posedge clk); ex_is_branch=0;
        pc=32'h10; #1; check_pred(1,2);

        // Train NOT TAKEN once → 11→10 (still predict taken)
        @(posedge clk); ex_is_branch=1; ex_branch_taken=0; ex_pc=32'h10;
        @(posedge clk); ex_is_branch=0;
        pc=32'h10; #1; check_pred(1,3);

        // Train NOT TAKEN again → 10→01 (weakly not taken)
        @(posedge clk); ex_is_branch=1; ex_branch_taken=0; ex_pc=32'h10;
        @(posedge clk); ex_is_branch=0;
        pc=32'h10; #1; check_pred(0,4);

        // Saturate NOT TAKEN → 01→00 → predict=0
        @(posedge clk); ex_is_branch=1; ex_branch_taken=0; ex_pc=32'h10;
        @(posedge clk); ex_is_branch=0;
        pc=32'h10; #1; check_pred(0,5);

        // Saturate at 00 (should stay 00)
        @(posedge clk); ex_is_branch=1; ex_branch_taken=0; ex_pc=32'h10;
        @(posedge clk); ex_is_branch=0;
        pc=32'h10; #1; check_pred(0,6);

        // Different PC (different index) should be independent (starts at 01 → predict=0)
        pc=32'h20; #1; check_pred(0,7);

        // Reset restores default
        @(posedge clk); reset=1;
        @(posedge clk); reset=0;
        pc=32'h10; #1; check_pred(0,8);

        $display("\n========== BP Results: %0d PASSED, %0d FAILED ==========\n",pass,fail);
        if (fail>0) $display("FAIL"); else $display("ALL PASS");
        $finish;
    end
endmodule
