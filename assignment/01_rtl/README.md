# P0 RTL Baseline

## Target

- FPGA family: Zynq-7000
- Target part: xc7z020clg484-1
- Vivado version: 2019.1
- Board assumption: Avnet ZedBoard

## Target Selection Rationale

The assignment specifies a Zynq/SoC-class FPGA target but does not identify an exact board or FPGA part.

Vivado 2019.1 was inspected directly and provides both the ZedBoard and ZC702 board definitions. Both board definitions map to the same FPGA part: xc7z020clg484-1.

The ZedBoard is therefore used as the documented board assumption for the P0 baseline.

## Hardware Validation Limitation

A physical FPGA development board is not currently available.

Therefore:
- Vivado synthesis, implementation, and bitstream generation can be verified.
- Physical board programming and hardware I/O validation cannot currently be claimed.