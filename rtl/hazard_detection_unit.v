// =============================================================
// hazard_detection_unit.v - Load-Use Hazard Detection
//
// Detects when a LOAD instruction is immediately followed by
// an instruction that uses the loaded register (Load-Use hazard).
//
// When stall=1:
//   - PC is held (PCWrite disabled)
//   - IF/ID register is frozen
//   - A NOP bubble is inserted into ID/EX
// =============================================================

module hazard_detection_unit (
    input  [4:0] if_id_rs1,        // rs1 of instruction in ID
    input  [4:0] if_id_rs2,        // rs2 of instruction in ID
    input  [4:0] id_ex_rd,         // rd of instruction in EX
    input        id_ex_mem_read,   // EX instruction is a load?
    output reg   stall             // 1 = insert stall cycle
);
    always @(*) begin
        if (id_ex_mem_read &&
            ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2)) &&
            (id_ex_rd != 5'b0))
            stall = 1'b1;
        else
            stall = 1'b0;
    end
endmodule
