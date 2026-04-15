// =============================================================
// register_file.v - 32x32-bit Register File
// x0 is hardwired to 0. Write on negedge, read combinationally.
// Internal forwarding: if WB is writing to same reg being read,
// return the new value (handles WB->ID same-cycle case).
// =============================================================

module register_file (
    input         clk,
    input         reg_write,      // Write enable (from WB stage)
    input  [4:0]  rs1, rs2,       // Read addresses
    input  [4:0]  rd,             // Write address
    input  [31:0] write_data,     // Write data (from WB)
    output [31:0] read_data1,     // rs1 data
    output [31:0] read_data2      // rs2 data
);
    reg [31:0] regs [31:0];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end

    // Write on falling edge to avoid read-write conflict in same cycle
    always @(negedge clk) begin
        if (reg_write && rd != 5'b0)
            regs[rd] <= write_data;
    end

    // Combinational read with internal forwarding for WB->ID path
    assign read_data1 = (rs1 == 5'b0)                    ? 32'b0       :
                        (reg_write && rd == rs1)          ? write_data  :
                        regs[rs1];

    assign read_data2 = (rs2 == 5'b0)                    ? 32'b0       :
                        (reg_write && rd == rs2)          ? write_data  :
                        regs[rs2];
endmodule
