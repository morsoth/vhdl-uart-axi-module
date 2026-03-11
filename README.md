# VHDL UART AXI Module
FPGA-based UART core featuring FIFO buffering and AXI4-Lite register access, with a minimal C driver for deterministic and low-level control.

## Overview
This repository contains a compact UART peripheral written in VHDL and designed to be integrated into FPGA-based systems through an AXI4-Lite memory-mapped interface. The design targets simple and predictable software control while keeping the hardware architecture modular and easy to verify.

The current implementation is intentionally simple and focused on clarity, deterministic behavior, and straightforward integration into embedded SoC-style designs.

## File structure
```
vhdl-uart-axi-module
    ├─ docs/        --> documentation
    ├─ rtl/         --> rtl source files
    ├─ sw/          --> high-level c driver
    ├─ tb/          --> rtl testbench files
    ├─ waves/       --> config files for GTKwave
    │
    ├─ .gitignore
    ├─ Makefile
    ├─ README.md
    └─ vhdl_ls.toml
```

## Project requirements
More info about this section in [`docs/00_requirements.md`](docs/00_requirements.md).

## IP architecture
More info about this section in [`docs/01_architecture.md`](docs/01_architecture.md).

## Register Map
More info about this section in [`docs/02_register_map.md`](docs/02_register_map.md).