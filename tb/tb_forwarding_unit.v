`timescale 1ns/1ps
`include "../rtl/defines.v"
module tb_forwarding_unit;
    reg  [4:0] id_ex_rs1, id_ex_rs2, ex_mem_rd, mem_wb_rd;
    reg        ex_mem_reg_write, mem_wb_reg_write;
    wire [1:0] forward_a, forward_b;
    integer pass=0, fail=0;

    forwarding_unit dut(.id_ex_rs1(id_ex_rs1),.id_ex_rs2(id_ex_rs2),
                        .ex_mem_rd(ex_mem_rd),.ex_mem_reg_write(ex_mem_reg_write),
                        .mem_wb_rd(mem_wb_rd),.mem_wb_reg_write(mem_wb_reg_write),
                        .forward_a(forward_a),.forward_b(forward_b));

    task check;
        input [1:0] exp_a, exp_b; input [7:0] id;
        begin #1;
        if (forward_a===exp_a && forward_b===exp_b) begin
            $display("  PASS [%0d]: fwd_a=%b fwd_b=%b",id,forward_a,forward_b); pass=pass+1;
        end else begin
            $display("  FAIL [%0d]: fwd_a=%b(exp %b) fwd_b=%b(exp %b)",
                     id,forward_a,exp_a,forward_b,exp_b); fail=fail+1;
        end end
    endtask

    initial begin
        $dumpfile("sim/results/tb_forwarding_unit.vcd");
        $dumpvars(0,tb_forwarding_unit);
        $display("\n========== Forwarding Unit Test ==========");

        // No hazard
        id_ex_rs1=1; id_ex_rs2=2; ex_mem_rd=5; mem_wb_rd=6;
        ex_mem_reg_write=1; mem_wb_reg_write=1;
        check(`FWD_NONE,`FWD_NONE,0);

        // EX-EX forward for A (rs1 matches EX/MEM rd)
        id_ex_rs1=3; id_ex_rs2=4; ex_mem_rd=3; mem_wb_rd=6;
        ex_mem_reg_write=1; mem_wb_reg_write=1;
        check(`FWD_MEM,`FWD_NONE,1);

        // EX-EX forward for B
        id_ex_rs1=1; id_ex_rs2=3; ex_mem_rd=3; mem_wb_rd=6;
        ex_mem_reg_write=1; mem_wb_reg_write=1;
        check(`FWD_NONE,`FWD_MEM,2);

        // MEM-EX forward for A (rs1 matches MEM/WB rd, not EX/MEM)
        id_ex_rs1=6; id_ex_rs2=4; ex_mem_rd=5; mem_wb_rd=6;
        ex_mem_reg_write=1; mem_wb_reg_write=1;
        check(`FWD_WB,`FWD_NONE,3);

        // MEM-EX forward for B
        id_ex_rs1=1; id_ex_rs2=6; ex_mem_rd=5; mem_wb_rd=6;
        ex_mem_reg_write=1; mem_wb_reg_write=1;
        check(`FWD_NONE,`FWD_WB,4);

        // EX/MEM takes priority over MEM/WB for same rd
        id_ex_rs1=3; id_ex_rs2=3; ex_mem_rd=3; mem_wb_rd=3;
        ex_mem_reg_write=1; mem_wb_reg_write=1;
        check(`FWD_MEM,`FWD_MEM,5);

        // No forward if reg_write=0 even if rd matches
        id_ex_rs1=3; id_ex_rs2=3; ex_mem_rd=3; mem_wb_rd=3;
        ex_mem_reg_write=0; mem_wb_reg_write=0;
        check(`FWD_NONE,`FWD_NONE,6);

        // No forward to x0
        id_ex_rs1=0; id_ex_rs2=0; ex_mem_rd=0; mem_wb_rd=0;
        ex_mem_reg_write=1; mem_wb_reg_write=1;
        check(`FWD_NONE,`FWD_NONE,7);

        // Forward both A and B from different sources
        id_ex_rs1=5; id_ex_rs2=6; ex_mem_rd=5; mem_wb_rd=6;
        ex_mem_reg_write=1; mem_wb_reg_write=1;
        check(`FWD_MEM,`FWD_WB,8);

        $display("\n========== FWD Results: %0d PASSED, %0d FAILED ==========\n",pass,fail);
        if (fail>0) $display("FAIL"); else $display("ALL PASS");
        $finish;
    end
endmodule
