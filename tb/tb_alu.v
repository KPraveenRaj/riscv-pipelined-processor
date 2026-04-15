// =============================================================
// tb_alu.v - Testbench for ALU
// Tests all 10 operations with multiple operand combinations.
// =============================================================
`include "../rtl/defines.v"
`timescale 1ns/1ps

module tb_alu;
    reg  [31:0] a, b;
    reg  [3:0]  alu_control;
    wire [31:0] result;
    wire        zero;

    integer pass = 0, fail = 0;

    alu dut (.a(a), .b(b), .alu_control(alu_control), .result(result), .zero(zero));

    task check;
        input [31:0] expected;
        input [0:0]  exp_zero;
        input [63:0] test_id;
        begin
            #1;
            if (result === expected && zero === exp_zero) begin
                $display("  PASS [%0d]: result=%0d zero=%b", test_id, result, zero);
                pass = pass + 1;
            end else begin
                $display("  FAIL [%0d]: got result=%0d zero=%b | expected result=%0d zero=%b",
                         test_id, result, zero, expected, exp_zero);
                fail = fail + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("sim/results/tb_alu.vcd");
        $dumpvars(0, tb_alu);

        $display("\n========== ALU Unit Test ==========");

        // ADD
        $display("--- ADD ---");
        a=32'd10;   b=32'd20;  alu_control=`ALU_ADD; check(32'd30,   1'b0, 0);
        a=32'd0;    b=32'd0;   alu_control=`ALU_ADD; check(32'd0,    1'b1, 1);
        a=32'hFFFFFFFF; b=32'd1; alu_control=`ALU_ADD; check(32'd0,  1'b1, 2); // overflow wrap

        // SUB
        $display("--- SUB ---");
        a=32'd30;   b=32'd10; alu_control=`ALU_SUB; check(32'd20,   1'b0, 3);
        a=32'd10;   b=32'd10; alu_control=`ALU_SUB; check(32'd0,    1'b1, 4);
        a=32'd5;    b=32'd10; alu_control=`ALU_SUB; check(32'hFFFFFFFB, 1'b0, 5);

        // AND
        $display("--- AND ---");
        a=32'hFF00FF00; b=32'hF0F0F0F0; alu_control=`ALU_AND; check(32'hF000F000, 1'b0, 6);
        a=32'hAAAAAAAA;  b=32'h55555555; alu_control=`ALU_AND; check(32'd0, 1'b1, 7);

        // OR
        $display("--- OR ---");
        a=32'hFF000000; b=32'h00FF0000; alu_control=`ALU_OR; check(32'hFFFF0000, 1'b0, 8);
        a=32'hAAAAAAAA;  b=32'h55555555; alu_control=`ALU_OR; check(32'hFFFFFFFF, 1'b0, 9);

        // XOR
        $display("--- XOR ---");
        a=32'hFFFFFFFF; b=32'hFFFFFFFF; alu_control=`ALU_XOR; check(32'd0, 1'b1, 10);
        a=32'hA5A5A5A5; b=32'h5A5A5A5A; alu_control=`ALU_XOR; check(32'hFFFFFFFF, 1'b0, 11);

        // SLT (signed)
        $display("--- SLT ---");
        a=32'd5;                b=32'd10;              alu_control=`ALU_SLT; check(32'd1, 1'b0, 12);
        a=32'd10;               b=32'd5;               alu_control=`ALU_SLT; check(32'd0, 1'b1, 13);
        a=32'hFFFFFFFF;         b=32'd0;               alu_control=`ALU_SLT; check(32'd1, 1'b0, 14); // -1 < 0

        // SLL
        $display("--- SLL ---");
        a=32'd1; b=32'd4; alu_control=`ALU_SLL; check(32'd16,         1'b0, 15);
        a=32'd1; b=32'd31; alu_control=`ALU_SLL; check(32'h80000000,  1'b0, 16);

        // SRL
        $display("--- SRL ---");
        a=32'h80000000; b=32'd1; alu_control=`ALU_SRL; check(32'h40000000, 1'b0, 17);
        a=32'hFFFFFFFF; b=32'd4; alu_control=`ALU_SRL; check(32'h0FFFFFFF, 1'b0, 18);

        // SRA
        $display("--- SRA ---");
        a=32'h80000000; b=32'd1; alu_control=`ALU_SRA; check(32'hC0000000, 1'b0, 19); // sign preserved
        a=32'h00000010; b=32'd2; alu_control=`ALU_SRA; check(32'h00000004, 1'b0, 20);

        // PASSB (LUI)
        $display("--- PASSB ---");
        a=32'hDEADBEEF; b=32'hABCDE000; alu_control=`ALU_PASSB; check(32'hABCDE000, 1'b0, 21);

        $display("\n========== ALU Results: %0d PASSED, %0d FAILED ==========\n", pass, fail);
        if (fail > 0) $display("FAIL");
        else          $display("ALL PASS");
        $finish;
    end
endmodule
