// =============================================================
// tb_alu_control.v - Testbench for ALU Control Decoder
// =============================================================
`include "../rtl/defines.v"
`timescale 1ns/1ps

module tb_alu_control;
    reg  [1:0] alu_op;
    reg  [2:0] funct3;
    reg        funct7_5;
    wire [3:0] alu_ctrl;

    integer pass = 0, fail = 0;

    alu_control dut (.alu_op(alu_op), .funct3(funct3), .funct7_5(funct7_5), .alu_ctrl(alu_ctrl));

    task check;
        input [3:0] expected;
        input [7:0] id;
        begin
            #1;
            if (alu_ctrl === expected) begin
                $display("  PASS [%0d]: alu_ctrl=%b", id, alu_ctrl);
                pass = pass + 1;
            end else begin
                $display("  FAIL [%0d]: got=%b expected=%b (alu_op=%b funct3=%b funct7_5=%b)",
                         id, alu_ctrl, expected, alu_op, funct3, funct7_5);
                fail = fail + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("sim/results/tb_alu_control.vcd");
        $dumpvars(0, tb_alu_control);
        $display("\n========== ALU Control Unit Test ==========");

        // LW/SW → ADD
        alu_op=`ALUOP_MEM; funct3=3'b000; funct7_5=0; check(`ALU_ADD, 0);
        // BEQ → SUB
        alu_op=`ALUOP_BR;  funct3=3'b000; funct7_5=0; check(`ALU_SUB, 1);
        // LUI → PASSB
        alu_op=`ALUOP_LUI; funct3=3'b000; funct7_5=0; check(`ALU_PASSB, 2);

        // R-type ADD (funct7_5=0, funct3=000)
        alu_op=`ALUOP_REG; funct3=3'b000; funct7_5=0; check(`ALU_ADD, 3);
        // R-type SUB (funct7_5=1, funct3=000)
        alu_op=`ALUOP_REG; funct3=3'b000; funct7_5=1; check(`ALU_SUB, 4);
        // AND
        alu_op=`ALUOP_REG; funct3=3'b111; funct7_5=0; check(`ALU_AND, 5);
        // OR
        alu_op=`ALUOP_REG; funct3=3'b110; funct7_5=0; check(`ALU_OR,  6);
        // XOR
        alu_op=`ALUOP_REG; funct3=3'b100; funct7_5=0; check(`ALU_XOR, 7);
        // SLT
        alu_op=`ALUOP_REG; funct3=3'b010; funct7_5=0; check(`ALU_SLT, 8);
        // SLL
        alu_op=`ALUOP_REG; funct3=3'b001; funct7_5=0; check(`ALU_SLL, 9);
        // SRL
        alu_op=`ALUOP_REG; funct3=3'b101; funct7_5=0; check(`ALU_SRL, 10);
        // SRA
        alu_op=`ALUOP_REG; funct3=3'b101; funct7_5=1; check(`ALU_SRA, 11);
        // ADDI (I-type, alu_op=REG, funct3=000, funct7_5=0) → ADD
        alu_op=`ALUOP_REG; funct3=3'b000; funct7_5=0; check(`ALU_ADD, 12);

        $display("\n========== ALU Control Results: %0d PASSED, %0d FAILED ==========\n", pass, fail);
        if (fail > 0) $display("FAIL");
        else          $display("ALL PASS");
        $finish;
    end
endmodule
