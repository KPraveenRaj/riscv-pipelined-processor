// =============================================================
// defines.v - Global constants for RISC-V Pipelined Processor
// =============================================================

// ALU Control Codes
`define ALU_ADD   4'b0000   // Addition
`define ALU_SUB   4'b0001   // Subtraction
`define ALU_AND   4'b0010   // Bitwise AND
`define ALU_OR    4'b0011   // Bitwise OR
`define ALU_XOR   4'b0100   // Bitwise XOR
`define ALU_SLT   4'b0101   // Set Less Than (signed)
`define ALU_SLL   4'b0110   // Shift Left Logical
`define ALU_SRL   4'b0111   // Shift Right Logical
`define ALU_SRA   4'b1000   // Shift Right Arithmetic
`define ALU_PASSB 4'b1001   // Pass B through (LUI)

// RV32I Opcodes
`define OP_R      7'b0110011  // R-type
`define OP_I_ALU  7'b0010011  // I-type ALU (ADDI, etc.)
`define OP_LOAD   7'b0000011  // Load (LW)
`define OP_STORE  7'b0100011  // Store (SW)
`define OP_BRANCH 7'b1100011  // Branch (BEQ)
`define OP_LUI    7'b0110111  // Load Upper Immediate
`define OP_JAL    7'b1101111  // Jump and Link
`define OP_JALR   7'b1100111  // Jump and Link Register

// ALUOp encoding (from Control Unit to ALU Control)
`define ALUOP_MEM  2'b00   // LW/SW: force ADD
`define ALUOP_BR   2'b01   // BEQ:   force SUB
`define ALUOP_REG  2'b10   // R/I-type: decode from funct
`define ALUOP_LUI  2'b11   // LUI:   force PASSB

// WB mux select
`define WB_ALU  2'b00   // Write ALU result
`define WB_MEM  2'b01   // Write memory read data
`define WB_PC4  2'b10   // Write PC+4 (JAL/JALR link)

// Forwarding codes
`define FWD_NONE  2'b00  // No forwarding - use register file
`define FWD_WB    2'b01  // Forward from MEM/WB
`define FWD_MEM   2'b10  // Forward from EX/MEM
