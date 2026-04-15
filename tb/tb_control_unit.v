`timescale 1ns/1ps
`include "../rtl/defines.v"
module tb_control_unit;
    reg  [6:0] opcode;
    wire       reg_write, mem_read, mem_write, branch, jump, alu_src;
    wire [1:0] mem_to_reg, alu_op;
    integer pass=0, fail=0;

    control_unit dut(.opcode(opcode),.reg_write(reg_write),.mem_read(mem_read),
                     .mem_write(mem_write),.branch(branch),.jump(jump),
                     .alu_src(alu_src),.mem_to_reg(mem_to_reg),.alu_op(alu_op));

    task check;
        input rw,mr,mw,br,jmp,as; input [1:0] mtr,ao; input [7:0] id;
        begin #1;
        if (reg_write===rw && mem_read===mr && mem_write===mw &&
            branch===br && jump===jmp && alu_src===as &&
            mem_to_reg===mtr && alu_op===ao) begin
            $display("  PASS [%0d] opcode=%b",id,opcode); pass=pass+1;
        end else begin
            $display("  FAIL [%0d] opcode=%b",id,opcode);
            $display("    rw=%b mr=%b mw=%b br=%b jmp=%b as=%b mtr=%b ao=%b",
                     reg_write,mem_read,mem_write,branch,jump,alu_src,mem_to_reg,alu_op);
            $display("    exp: rw=%b mr=%b mw=%b br=%b jmp=%b as=%b mtr=%b ao=%b",
                     rw,mr,mw,br,jmp,as,mtr,ao); fail=fail+1;
        end end
    endtask

    initial begin
        $dumpfile("sim/results/tb_control_unit.vcd");
        $dumpvars(0,tb_control_unit);
        $display("\n========== Control Unit Test ==========");
        //              rw mr mw br jp as mtr      ao
        opcode=`OP_R;      check(1,0,0,0,0,0,`WB_ALU,`ALUOP_REG,0); // R-type
        opcode=`OP_I_ALU;  check(1,0,0,0,0,1,`WB_ALU,`ALUOP_REG,1); // ADDI
        opcode=`OP_LOAD;   check(1,1,0,0,0,1,`WB_MEM,`ALUOP_MEM,2); // LW
        opcode=`OP_STORE;  check(0,0,1,0,0,1,`WB_ALU,`ALUOP_MEM,3); // SW
        opcode=`OP_BRANCH; check(0,0,0,1,0,0,`WB_ALU,`ALUOP_BR, 4); // BEQ
        opcode=`OP_LUI;    check(1,0,0,0,0,1,`WB_ALU,`ALUOP_LUI,5); // LUI
        opcode=`OP_JAL;    check(1,0,0,0,1,0,`WB_PC4,`ALUOP_MEM,6); // JAL
        opcode=`OP_JALR;   check(1,0,0,0,1,1,`WB_PC4,`ALUOP_MEM,7); // JALR
        opcode=7'b0000000; check(0,0,0,0,0,0,`WB_ALU,`ALUOP_MEM,8); // unknown=NOP

        $display("\n========== Control Results: %0d PASSED, %0d FAILED ==========\n",pass,fail);
        if (fail>0) $display("FAIL"); else $display("ALL PASS");
        $finish;
    end
endmodule
