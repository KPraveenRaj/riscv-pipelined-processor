`timescale 1ns/1ps
module tb_hazard_detection;
    reg  [4:0] if_id_rs1, if_id_rs2, id_ex_rd;
    reg        id_ex_mem_read;
    wire       stall;
    integer pass=0, fail=0;

    hazard_detection_unit dut(.if_id_rs1(if_id_rs1),.if_id_rs2(if_id_rs2),
                               .id_ex_rd(id_ex_rd),.id_ex_mem_read(id_ex_mem_read),
                               .stall(stall));

    task check;
        input exp_stall; input [7:0] id;
        begin #1;
        if (stall===exp_stall) begin
            $display("  PASS [%0d]: stall=%b",id,stall); pass=pass+1;
        end else begin
            $display("  FAIL [%0d]: stall=%b exp=%b",id,stall,exp_stall); fail=fail+1;
        end end
    endtask

    initial begin
        $dumpfile("sim/results/tb_hazard_detection.vcd");
        $dumpvars(0,tb_hazard_detection);
        $display("\n========== Hazard Detection Test ==========");

        // No hazard: mem_read=0
        if_id_rs1=1; if_id_rs2=2; id_ex_rd=1; id_ex_mem_read=0; check(0,0);

        // Load-use on rs1
        if_id_rs1=5; if_id_rs2=2; id_ex_rd=5; id_ex_mem_read=1; check(1,1);

        // Load-use on rs2
        if_id_rs1=1; if_id_rs2=5; id_ex_rd=5; id_ex_mem_read=1; check(1,2);

        // Load-use but rd=x0 (no stall - x0 never really written)
        if_id_rs1=0; if_id_rs2=0; id_ex_rd=0; id_ex_mem_read=1; check(0,3);

        // No match - different register
        if_id_rs1=3; if_id_rs2=4; id_ex_rd=7; id_ex_mem_read=1; check(0,4);

        // Both rs1 and rs2 match (still just 1 stall cycle)
        if_id_rs1=5; if_id_rs2=5; id_ex_rd=5; id_ex_mem_read=1; check(1,5);

        $display("\n========== HDU Results: %0d PASSED, %0d FAILED ==========\n",pass,fail);
        if (fail>0) $display("FAIL"); else $display("ALL PASS");
        $finish;
    end
endmodule
