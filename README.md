# RISC-V Pipelined Processor

A 5-stage pipelined 32-bit processor implementing a subset of the **RISC-V RV32I** ISA, written in Verilog RTL. Designed as part of the *High Performance Computing Architecture* course at **NIT Karnataka, Surathkal**.

## Features

- **5-stage pipeline**: IF → ID → EX → MEM → WB
- **Full data forwarding**: EX-EX and MEM-EX paths (eliminates RAW stalls)
- **Load-use hazard detection**: automatic 1-cycle stall insertion
- **Branch resolution in EX**: 1-cycle flush for BEQ, JAL, JALR
- **2-bit saturating counter branch predictor** (4-entry, trained by EX outcomes)
- **ISA subset**: ADD, SUB, AND, OR, XOR, SLT, SLL, SRL, SRA, ADDI, LW, SW, BEQ, LUI, JAL, JALR

## Repository Structure

```
riscv-pipelined-processor/
├── rtl/                          # RTL source files
│   ├── top.v                     # Top-level processor integration
│   ├── defines.v                 # Global constants (ALU ops, opcodes, etc.)
│   ├── alu.v                     # 32-bit ALU (10 operations)
│   ├── alu_control.v             # ALU control decoder
│   ├── control_unit.v            # Main control unit (opcode → control signals)
│   ├── register_file.v           # 32×32-bit register file (x0 hardwired to 0)
│   ├── imm_gen.v                 # Immediate generator (I/S/B/U/J formats)
│   ├── forwarding_unit.v         # Data forwarding unit
│   ├── hazard_detection_unit.v   # Load-use hazard detection
│   ├── branch_predictor.v        # 2-bit saturating counter predictor
│   └── pipeline_registers/
│       ├── if_id_reg.v           # IF/ID pipeline register
│       ├── id_ex_reg.v           # ID/EX pipeline register
│       ├── ex_mem_reg.v          # EX/MEM pipeline register
│       └── mem_wb_reg.v          # MEM/WB pipeline register
├── tb/                           # Testbenches
│   ├── tb_top.v                  # Full integration test (16 checks)
│   ├── tb_alu.v
│   ├── tb_alu_control.v
│   ├── tb_control_unit.v
│   ├── tb_register_file.v
│   ├── tb_imm_gen.v
│   ├── tb_forwarding_unit.v
│   ├── tb_hazard_detection.v
│   └── tb_branch_predictor.v
├── sim/
│   ├── run_all.sh                # Run all tests in one command
│   └── results/                  # Simulation logs (auto-generated)
└── docs/
    └── HPCA_Final_Report.md      # Full project report
```

## Prerequisites

You need **Icarus Verilog** to compile and simulate. Optionally, **GTKWave** to view waveforms.

**Ubuntu / Debian:**
```bash
sudo apt-get install iverilog gtkwave
```

**macOS (Homebrew):**
```bash
brew install icarus-verilog gtkwave
```

**Verify installation:**
```bash
iverilog -V
vvp -V
```

## Running the Tests

### Run all tests at once

```bash
cd riscv-pipelined-processor
bash sim/run_all.sh
```

Expected output:
```
============================================================
  RISC-V Pipelined Processor - Full Test Suite
============================================================

--- Unit Tests ---
  tb_alu                         PASS
  tb_alu_control                 PASS
  tb_register_file               PASS
  tb_control_unit                PASS
  tb_imm_gen                     PASS
  tb_forwarding_unit             PASS
  tb_hazard_detection            PASS
  tb_branch_predictor            PASS

--- Integration Test ---
  tb_top                         PASS

============================================================
  Results: 9 PASSED, 0 FAILED out of 9 tests
============================================================
```

### Run a single test manually

**Integration test (full processor):**
```bash
iverilog -g2005 -Irtl \
  rtl/alu.v rtl/alu_control.v rtl/register_file.v rtl/control_unit.v \
  rtl/imm_gen.v rtl/forwarding_unit.v rtl/hazard_detection_unit.v \
  rtl/branch_predictor.v \
  rtl/pipeline_registers/if_id_reg.v \
  rtl/pipeline_registers/id_ex_reg.v \
  rtl/pipeline_registers/ex_mem_reg.v \
  rtl/pipeline_registers/mem_wb_reg.v \
  rtl/top.v tb/tb_top.v \
  -o sim/results/tb_top.out

vvp sim/results/tb_top.out
```

**Any unit test (example: ALU):**
```bash
iverilog -g2005 -Irtl rtl/alu.v tb/tb_alu.v -o sim/results/tb_alu.out
vvp sim/results/tb_alu.out
```

## Viewing Waveforms

All testbenches dump VCD files to `sim/results/`. After running:

```bash
gtkwave sim/results/tb_top.vcd &
```

The integration test VCD contains every pipeline signal — PC, instruction, stall, pc_src, forwarding mux selects, register file writes, and memory accesses — useful for tracing execution cycle by cycle.

## Integration Test Program

The integration test (`tb/tb_top.v`) runs a 16-instruction program covering every hazard type:

| Address | Instruction | Expected | Tests |
|---------|-------------|----------|-------|
| 0x00 | `addi x1, x0, 10` | x1=10 | — |
| 0x04 | `addi x2, x0, 20` | x2=20 | — |
| 0x08 | `add  x3, x1, x2` | x3=30 | EX-EX forwarding |
| 0x0C | `sub  x4, x3, x1` | x4=20 | Forwarding chain |
| 0x10 | `and  x5, x1, x2` | x5=0  | — |
| 0x14 | `or   x6, x1, x2` | x6=30 | — |
| 0x18 | `sw   x3, 0(x0)`  | dmem[0]=30 | Store |
| 0x1C | `lw   x7, 0(x0)`  | x7=30 | Load |
| 0x20 | `add  x8, x7, x1` | x8=40 | Load-use stall |
| 0x24 | `beq  x1, x1, 8`  | taken → 0x2C | Branch flush |
| 0x28 | `addi x9, x0, 99` | x9=0 (skipped) | Branch flush check |
| 0x2C | `addi x10, x0, 55`| x10=55 | — |
| 0x30 | `jal  x11, 12`    | x11=52, → 0x3C | JAL flush |
| 0x34 | `addi x12, x0, 77`| x12=0 (skipped) | JAL flush check |
| 0x38 | `addi x13, x0, 88`| x13=0 (skipped) | JAL flush check |
| 0x3C | `addi x14, x0, 42`| x14=42 | — |

Result: **16/16 checks pass in 79 cycles**.

## Authors

- Rishabh Barwe (252SP025)
- Konatham Praveen Raj (252SP014)

*NIT Karnataka, Surathkal — High Performance Computing Architecture*
