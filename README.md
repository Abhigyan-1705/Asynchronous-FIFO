# Asynchronous FIFO

A parameterizable dual-clock asynchronous FIFO written in Verilog, using Gray-coded pointers and 2-flip-flop synchronizers for safe clock-domain crossing (CDC). Verified with a SystemVerilog testbench in Vivado.

## Features

- Configurable `DATA_WIDTH` and `FIFO_DEPTH` (depth must be a power of 2)
- Gray-code read/write pointers to avoid multi-bit synchronization errors
- 2-FF synchronizers for safe CDC of pointers between write and read clock domains
- Combinational (zero-latency) read port
- Registered `full` / `empty` flag generation

## Repository Structure

```
Asynchronous-FIFO/
├── rtl/
│   ├── async_fifo.v     
│   ├── write_ptr.v      
│   ├── read_ptr.v        
│   ├── fifo_mem.v         
│   ├── sync_2ff.v        
│   └── bin2gray.v        
├── tb/
│   └── tb_async_fifo.sv 
└── results/
    ├── async_fifo_full.png   
    └── async_fifo_empty.png  
```

## Module Overview

| Module | Description |
|---|---|
| `async_fifo` | Top level; wires together the write pointer, read pointer, and memory |
| `write_ptr` | Generates binary/Gray write pointer, synchronizes the read pointer into `wr_clk`, and asserts `full` |
| `read_ptr` | Generates binary/Gray read pointer, synchronizes the write pointer into `rd_clk`, and asserts `empty` |
| `fifo_mem` | Synchronous-write / asynchronous-read dual-port memory |
| `sync_2ff` | Generic 2-flop synchronizer for crossing clock domains |
| `bin2gray` | Combinational binary-to-Gray code converter |

## How It Works

- Write and read pointers are kept as both binary (for memory addressing) and Gray code (for safe CDC), since Gray code changes only one bit per increment.
- Each pointer is synchronized into the *other* clock domain through a 2-FF synchronizer before being compared.
- **Full**: asserted when the next write pointer (Gray) equals the synchronized read pointer with its two MSBs inverted.
- **Empty**: asserted when the next read pointer (Gray) exactly equals the synchronized write pointer.

## Testbench

`tb/tb_async_fifo.sv` drives independent write (100 MHz) and read (~71 MHz) clocks and checks DUT output against a reference queue model. It runs:

1. **Fill test** — writes until full, checks the `full` flag asserts correctly.
2. **Drain test** — reads until empty, checks the `empty` flag asserts correctly.
3. **Stress test** — 200 concurrent randomized writes and reads, checking every read against the reference model for order and data integrity.

## Simulation Results

Waveforms captured in Vivado (see `results/`) confirm:
- `full` and `empty` assert/de-assert correctly across the two clock domains, with the expected pointer-synchronization latency.
- Data written on `wr_clk` is read back in-order and unmodified on `rd_clk`, verified against the testbench's reference queue.
