`timescale 1ns/1ps
module tb_imm_gen;
    reg  [31:0] instruction;
    wire [31:0] imm_ext;
    integer pass=0, fail=0;

    imm_gen dut(.instruction(instruction),.imm_ext(imm_ext));

    task check;
        input [31:0] expected; input [7:0] id;
        begin #1;
        if (imm_ext===expected) begin
            $display("  PASS [%0d]: imm=0x%08h",id,imm_ext); pass=pass+1;
        end else begin
            $display("  FAIL [%0d]: got=0x%08h exp=0x%08h",id,imm_ext,expected); fail=fail+1;
        end end
    endtask

    initial begin
        $dumpfile("sim/results/tb_imm_gen.vcd");
        $dumpvars(0,tb_imm_gen);
        $display("\n========== Immediate Generator Test ==========");

        // I-type: addi x1, x0, 10  → imm=10
        instruction = 32'h00A00093; check(32'd10, 0);

        // I-type: addi x1, x0, -1  → imm=-1
        instruction = 32'hFFF00093; check(32'hFFFFFFFF, 1);

        // I-type: lw x7, 0(x0) → imm=0
        instruction = 32'h00002383; check(32'd0, 2);

        // S-type: sw x3, 4(x0) → imm=4
        // imm[11:5]=0000000, rs2=00011, rs1=00000, funct3=010, imm[4:0]=00100
        instruction = 32'h00302223; check(32'd4, 3);

        // S-type: sw x3, -4(x1) → imm=-4 = 0xFFFFFFFC
        // imm[11:5]=1111111, rs2=00011, rs1=00001, funct3=010, imm[4:0]=11100
        instruction = 32'hFE30AE23; check(32'hFFFFFFFC, 4);

        // B-type: beq x1,x1,8 → imm=8
        instruction = 32'h00108463; check(32'd8, 5);

        // B-type: beq x0,x0,-4 → imm=-4 = 0xFFFFFFFC
        // imm=-4: imm[12]=1,imm[11]=1,imm[10:5]=111111,imm[4:1]=1110
        instruction = 32'hFE000EE3; check(32'hFFFFFFFC, 6);

        // U-type: lui x1, 0xABCDE → imm=0xABCDE000
        instruction = 32'hABCDE0B7; check(32'hABCDE000, 7);

        // J-type: jal x11, 12 → imm=12
        instruction = 32'h00C005EF; check(32'd12, 8);

        // J-type: jal x0, -8 → imm=-8
        // imm=-8: imm[20]=1, imm[10:1]=1111111100, imm[11]=1, imm[19:12]=11111111
        instruction = 32'hFF9FF06F; check(32'hFFFFFFF8, 9);

        $display("\n========== ImmGen Results: %0d PASSED, %0d FAILED ==========\n",pass,fail);
        if (fail>0) $display("FAIL"); else $display("ALL PASS");
        $finish;
    end
endmodule
