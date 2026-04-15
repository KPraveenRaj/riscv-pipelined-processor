`timescale 1ns/1ps
module tb_register_file;
    reg        clk, reg_write;
    reg  [4:0] rs1, rs2, rd;
    reg  [31:0] write_data;
    wire [31:0] read_data1, read_data2;
    integer pass=0, fail=0;

    register_file dut(.clk(clk),.reg_write(reg_write),.rs1(rs1),.rs2(rs2),
                      .rd(rd),.write_data(write_data),
                      .read_data1(read_data1),.read_data2(read_data2));

    always #5 clk = ~clk;

    task check2;
        input [31:0] exp1, exp2; input [7:0] id;
        begin
            #1; // let combinational settle
            if (read_data1===exp1 && read_data2===exp2) begin
                $display("  PASS [%0d]",id); pass=pass+1;
            end else begin
                $display("  FAIL [%0d]: rd1=%0d(exp %0d) rd2=%0d(exp %0d)",
                         id,read_data1,exp1,read_data2,exp2); fail=fail+1;
            end
        end
    endtask

    // Helper: drive write before negedge so register_file sees stable signals
    task write_reg;
        input [4:0]  reg_addr;
        input [31:0] data;
        begin
            // Set up BEFORE negedge so no race with always @(negedge clk)
            @(posedge clk); #1;
            reg_write=1; rd=reg_addr; write_data=data;
            @(negedge clk); #1; // negedge fires, NB settles within this #1
            reg_write=0;
        end
    endtask

    initial begin
        $dumpfile("sim/results/tb_register_file.vcd");
        $dumpvars(0,tb_register_file);
        $display("\n========== Register File Test ==========");
        clk=0; reg_write=0; rs1=0; rs2=0; rd=0; write_data=0;
        #2;

        // x0 always reads 0
        rs1=5'd0; rs2=5'd0; check2(0,0,0);

        // Write x1=100, read back
        write_reg(5'd1, 32'd100);
        rs1=5'd1; rs2=5'd0; check2(100,0,1);

        // Write x5=0xDEAD, read back alongside x1
        write_reg(5'd5, 32'hDEAD);
        rs1=5'd5; rs2=5'd1; check2(32'hDEAD,100,2);

        // x0 cannot be written
        write_reg(5'd0, 32'hFFFFFFFF);
        rs1=5'd0; rs2=5'd0; check2(0,0,3);

        // Internal forwarding: write x2=42, READ WHILE reg_write=1
        @(posedge clk); #1;
        reg_write=1; rd=5'd2; write_data=32'd42;
        rs1=5'd2; rs2=5'd2;  // read same reg being written
        check2(42,42,4);     // forwarding path should return write_data
        @(negedge clk); #1; reg_write=0;

        // Write x31 (boundary register)
        write_reg(5'd31, 32'hCAFEBABE);
        rs1=5'd31; rs2=5'd31; check2(32'hCAFEBABE,32'hCAFEBABE,5);

        $display("\n========== RF Results: %0d PASSED, %0d FAILED ==========\n",pass,fail);
        if (fail>0) $display("FAIL"); else $display("ALL PASS");
        $finish;
    end
endmodule
