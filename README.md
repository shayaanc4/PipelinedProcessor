# 🧠 Pipelined RISC-V Processor

This project implements a multistage pipelined processor in Verilog based on the RISC-V ISA. 

## 📁 Repository Structure

The repository contains the following key files:

- `alu.v`: Arithmetic Logic Unit.
- `control_unit.v`: Control unit for generating processor control signals.
- `forwarding_unit.v`: Handles data forwarding to resolve hazards.
- `imm_gen.v`: Immediate value generator.
- `pc_updater.v`: Program counter update logic.
- `pll_shifted.v`: Phase-Locked Loop module for clock management.
- `processor.v`: Top-level processor module integrating all components.
- `ram_ip.v`: RAM module for data memory.
- `reg_write_date_selector.v`: Logic for selecting data to write back to register file.
- `register_file.v`: Register file implementation with internal register forwarding.
- `rom.v`: Read-Only Memory module for instruction memory.
- `instruction_mem.txt`: Text file for storing machine code to run on processor.
- `README.md`: Project overview and documentation.

## 🔧 Architecture

The processor is organized into **three pipeline stages**:

1. **IF-ID (Instruction Fetch / Decode)**  
   - Fetches instruction from memory and decodes it.
   - Includes PC, instruction memory, and register file.

2. **EX (Execute)**  
   - ALU execution, including multiplication.
   - Computes branches and flushes pipeline if necessary.

3. **MEM-WB (Memory Access / Write Back)**  
   - Reads/writes data memory.
   - Handles register write-back.

## 🧪 Programs and Performance

Two programs were run to test measure performance and compare with single-cycle processor:

| Program         | Single-Cycle Runtime | Pipelined Runtime | Speedup    |
|----------------|----------------------|-------------------|------------|
| Factorial       | 486.7 ns @150 MHz    | 281.3 ns @320 MHz | +42.2%     |
| Custom Program | 126.7 ns @150 MHz    | 68.8 ns @320 MHz  | +45.7%     |

## ⚙️ Timing and Synthesis

- **Max frequency (Fmax):** ~320 MHz on hardware (tested).
- **Pipeline balancing:**
  - IF-ID: ~30% of critical path
  - EX: Multiplier-dominated, ~50% of critical path
  - MEM-WB: ~20% of critical path

## 🧼 Branch Handling

- Branch resolution occurs in the **EX** stage.
- If a branch is taken, the instruction in IF-ID is flushed (replaced with no-op instruction: `0x00000033`) and all control signals are nulled.

## 🧮 FPGA Resource Utilization

| Resource        | Usage  |
|----------------|--------|
| ALMs           | 1148   |
| DSP Blocks     | 2      |
| PLLs           | 1      |
| BRAM Bits      | 8192   |

## 📥 Running on FPGA

1. Place compiled machine code in `instruction_mem.txt`.
2. Ensure `rom.v` correctly references this file.
3. Compile and flash to your FPGA using Quartus.
4. Verify output via hardware or simulation testbench.
