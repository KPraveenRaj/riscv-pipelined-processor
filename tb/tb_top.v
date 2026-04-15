// =============================================================
// tb_top.v - Full Integration Test for 5-Stage RISC-V Pipeline
//
// Test Program (hand-assembled):
//   0x00: addi x1,  x0, 10    x1=10
//   0x04: addi x2,  x0, 20    x2=20
//   0x08: add  x3,  x1, x2    x3=30   (tests EX-EX & MEM-EX forwarding)
//   0x0C: sub  x4,  x3, x1    x4=20   (tests forwarding chain)
//   0x10: and  x5,  x1, x2    x5=0    (10 & 20 = 0)
//   0x14: or   x6,  x1, x2    x6=30   (10 | 20 = 30)
//   0x18: sw   x3,  0(x0)     mem[0]=30
//   0x1C: lw   x7,  0(x0)     x7=30
//   0x20: add  x8,  x7, x1    x8=40   (tests load-use stall)
//   0x24: beq  x1,  x1, 8     taken → PC=0x2C  (tests branch flush)
//   0x28: addi x9,  x0, 99    SKIPPED → x9=0
//   0x2C: addi x10, x0, 55    x10=55
//   0x30: jal  x11, 12        x11=0x34=52, PC→0x3C (tests JAL flush)
//   0x34: addi x12, x0, 77    SKIPPED → x12=0
//   0x38: addi x13, x0, 88    SKIPPED → x13=0
//   0x3C: addi x14, x0, 42    x14=42
// =============================================================
`timescale 1ns/1ps

module tb_top;
    reg clk, reset;
    integer pass=0, fail=0, cyc=0;

    top dut(.clk(clk), .reset(reset));

    always #5 clk = ~clk;

    // Count cycles
    always @(posedge clk) cyc = cyc + 1;

    task check_reg;
        input [4:0]  reg_num;
        input [31:0] expected;
        input [7:0]  id;
        begin
            if (dut.rf.regs[reg_num] === expected) begin
                $display("  PASS [%0d]: x%0d = %0d (0x%08h)", id, reg_num,
                         dut.rf.regs[reg_num], dut.rf.regs[reg_num]);
                pass = pass + 1;
            end else begin
                $display("  FAIL [%0d]: x%0d = %0d (0x%08h)  expected %0d (0x%08h)",
                         id, reg_num,
                         dut.rf.regs[reg_num], dut.rf.regs[reg_num],
                         expected, expected);
                fail = fail + 1;
            end
        end
    endtask

    task check_mem;
        input [7:0]  addr;
        input [31:0] expected;
        input [7:0]  id;
        begin
            if (dut.dmem[addr] === expected) begin
                $display("  PASS [%0d]: dmem[%0d] = %0d", id, addr, dut.dmem[addr]);
                pass = pass + 1;
            end else begin
                $display("  FAIL [%0d]: dmem[%0d] = %0d  expected %0d",
                         id, addr, dut.dmem[addr], expected);
                fail = fail + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("sim/results/tb_top.vcd");
        $dumpvars(0, tb_top);

        // --- Load instruction memory ---
        dut.imem[0]  = 32'h00A00093; // addi x1,  x0, 10
        dut.imem[1]  = 32'h01400113; // addi x2,  x0, 20
        dut.imem[2]  = 32'h002081B3; // add  x3,  x1, x2
        dut.imem[3]  = 32'h40118233; // sub  x4,  x3, x1
        dut.imem[4]  = 32'h0020F2B3; // and  x5,  x1, x2
        dut.imem[5]  = 32'h0020E333; // or   x6,  x1, x2
        dut.imem[6]  = 32'h00302023; // sw   x3,  0(x0)
        dut.imem[7]  = 32'h00002383; // lw   x7,  0(x0)
        dut.imem[8]  = 32'h00138433; // add  x8,  x7, x1
        dut.imem[9]  = 32'h00108463; // beq  x1,  x1, 8
        dut.imem[10] = 32'h06300493; // addi x9,  x0, 99  (SKIPPED)
        dut.imem[11] = 32'h03700513; // addi x10, x0, 55
        dut.imem[12] = 32'h00C005EF; // jal  x11, 12
        dut.imem[13] = 32'h04D00613; // addi x12, x0, 77  (SKIPPED)
        dut.imem[14] = 32'h05800693; // addi x13, x0, 88  (SKIPPED)
        dut.imem[15] = 32'h02A00713; // addi x14, x0, 42
        // rest are NOP (initialized in top.v)

        // --- Reset ---
        clk = 0; reset = 1;
        repeat(4) @(posedge clk);
        reset = 0;

        // --- Run for enough cycles ---
        // 16 instructions + 5 pipeline stages + 1 load-use stall
        // + 1 branch flush + 2 JAL flushes = ~28+ cycles. Run 70 to be safe.
        repeat(70) @(posedge clk);

        // Allow WB to complete
        repeat(5) @(posedge clk);

        // ============================================================
        // CHECK RESULTS
        // ============================================================
        $display("\n========== Integration Test: Register Check ==========");
        check_reg(0,  32'd0,  0);  // x0 always 0
        check_reg(1,  32'd10, 1);  // addi x1, x0, 10
        check_reg(2,  32'd20, 2);  // addi x2, x0, 20
        check_reg(3,  32'd30, 3);  // add  x3 = x1+x2 = 30  [EX-EX forward]
        check_reg(4,  32'd20, 4);  // sub  x4 = x3-x1 = 20  [forwarding chain]
        check_reg(5,  32'd0,  5);  // and  x5 = 10&20 = 0
        check_reg(6,  32'd30, 6);  // or   x6 = 10|20 = 30
        check_reg(7,  32'd30, 7);  // lw   x7 = mem[0] = 30
        check_reg(8,  32'd40, 8);  // add  x8 = x7+x1 = 40  [load-use stall]
        check_reg(9,  32'd0,  9);  // addi x9 SKIPPED by BEQ
        check_reg(10, 32'd55, 10); // addi x10 = 55
        check_reg(11, 32'd52, 11); // jal  x11 = PC+4 = 0x34 = 52
        check_reg(12, 32'd0,  12); // addi x12 SKIPPED by JAL
        check_reg(13, 32'd0,  13); // addi x13 SKIPPED by JAL
        check_reg(14, 32'd42, 14); // addi x14 = 42

        $display("\n========== Integration Test: Memory Check ==========");
        check_mem(0, 32'd30, 15);  // sw x3, 0(x0) → dmem[0] = 30

        $display("\n========== Integration Test: %0d cycles, %0d PASSED, %0d FAILED ==========\n",
                 cyc, pass, fail);
        if (fail > 0) $display("FAIL");
        else          $display("ALL PASS");
        $finish;
    end

    // Optional: print pipeline state every few cycles for debugging
    // Uncomment to trace:
    // initial begin
    //     $monitor("clk=%0t pc=%0h instr=%h stall=%b pc_src=%b",
    //              $time, dut.pc, dut.if_instr, dut.stall, dut.pc_src);
    // end
endmodule
