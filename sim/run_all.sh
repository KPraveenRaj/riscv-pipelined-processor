#!/bin/bash
# =============================================================
# run_all.sh - Compile and simulate all testbenches
# Usage: cd ~/Desktop/riscv_processor && bash sim/run_all.sh
# =============================================================

set -e
cd "$(dirname "$0")/.."  # Always run from project root

RESULTS=sim/results
mkdir -p $RESULTS

RTL=rtl
TB=tb
PASS=0
FAIL=0
TOTAL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

run_test() {
    local name=$1
    shift
    local files="$@"
    TOTAL=$((TOTAL+1))

    printf "  %-30s " "$name"

    # Compile
    if ! iverilog -g2005 -I$RTL -o $RESULTS/${name}.out $files \
         > $RESULTS/${name}_compile.log 2>&1; then
        echo -e "${RED}COMPILE ERROR${NC}"
        cat $RESULTS/${name}_compile.log
        FAIL=$((FAIL+1))
        return
    fi

    # Simulate (run from project root so VCD paths resolve)
    vvp $RESULTS/${name}.out > $RESULTS/${name}_sim.log 2>&1
    local sim_out=$(cat $RESULTS/${name}_sim.log)

    if echo "$sim_out" | grep -q "^FAIL"; then
        echo -e "${RED}FAIL${NC}"
        echo "$sim_out" | grep -E "FAIL|fail" | head -5
        FAIL=$((FAIL+1))
    elif echo "$sim_out" | grep -q "ALL PASS"; then
        echo -e "${GREEN}PASS${NC}"
        PASS=$((PASS+1))
    else
        echo -e "${RED}UNKNOWN (check $RESULTS/${name}_sim.log)${NC}"
        FAIL=$((FAIL+1))
    fi
}

echo ""
echo "============================================================"
echo "  RISC-V Pipelined Processor - Full Test Suite"
echo "============================================================"
echo ""

# ---- Unit Tests ----
echo "--- Unit Tests ---"

run_test "tb_alu" \
    $RTL/alu.v \
    $TB/tb_alu.v

run_test "tb_alu_control" \
    $RTL/alu_control.v \
    $TB/tb_alu_control.v

run_test "tb_register_file" \
    $RTL/register_file.v \
    $TB/tb_register_file.v

run_test "tb_control_unit" \
    $RTL/control_unit.v \
    $TB/tb_control_unit.v

run_test "tb_imm_gen" \
    $RTL/imm_gen.v \
    $TB/tb_imm_gen.v

run_test "tb_forwarding_unit" \
    $RTL/forwarding_unit.v \
    $TB/tb_forwarding_unit.v

run_test "tb_hazard_detection" \
    $RTL/hazard_detection_unit.v \
    $TB/tb_hazard_detection.v

run_test "tb_branch_predictor" \
    $RTL/branch_predictor.v \
    $TB/tb_branch_predictor.v

echo ""
echo "--- Integration Test ---"

run_test "tb_top" \
    $RTL/alu.v \
    $RTL/alu_control.v \
    $RTL/register_file.v \
    $RTL/control_unit.v \
    $RTL/imm_gen.v \
    $RTL/forwarding_unit.v \
    $RTL/hazard_detection_unit.v \
    $RTL/branch_predictor.v \
    $RTL/pipeline_registers/if_id_reg.v \
    $RTL/pipeline_registers/id_ex_reg.v \
    $RTL/pipeline_registers/ex_mem_reg.v \
    $RTL/pipeline_registers/mem_wb_reg.v \
    $RTL/top.v \
    $TB/tb_top.v

echo ""
echo "============================================================"
printf "  Results: ${GREEN}%d PASSED${NC}, ${RED}%d FAILED${NC} out of %d tests\n" \
       $PASS $FAIL $TOTAL
echo "============================================================"
echo ""
echo "VCD files saved to: $RESULTS/"
echo "Open waveforms: gtkwave $RESULTS/tb_top.vcd &"
echo ""

[ $FAIL -eq 0 ] && exit 0 || exit 1
