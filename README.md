# Universal Asynchronous Receiver-Transmitter (UART) IP Core

A fully functional, configurable UART IP core implemented in SystemVerilog with comprehensive verification using a layered testbench architecture.

## 🎯 Overview

This project implements a synthesis-ready UART IP core capable of full-duplex serial communication. The design features programmable baud rates, configurable data width, and flexible parity options, making it suitable for various serial communication applications.

## ✨ Features

- **Full-Duplex Communication**: Simultaneous transmit and receive operations
- **Configurable Parameters**:
  - System clock frequency
  - Baud rate
  - Data width (default 8 bits)
  - Parity enable/disable
  - Even/Odd parity selection
- **Robust Error Detection**:
  - Parity error checking
  - Stop bit (frame) error detection
- **16x Oversampling**: Enhanced noise immunity on the receiver
- **Modular Design**: Clean separation of transmitter, receiver, and baud generator
- **Comprehensive Verification**: Layered SystemVerilog testbench with UVM-style architecture

## 🏗️ Architecture

The UART core consists of three primary components:

### 1. Baud Rate Generator (`baud_gen`)
- Generates timing pulses for data synchronization
- **baud_tick**: 1x baud rate for transmitter
- **tick_16x**: 16x baud rate for receiver oversampling

### 2. UART Transmitter (`uart_tx.sv`)
- FSM-based parallel-to-serial converter
- **States**: Idle → Start → Data → Parity (optional) → Stop
- LSB-first transmission
- Automatic parity bit calculation (XOR reduction)

### 3. UART Receiver (`uart_rx.sv`)
- FSM with 16x oversampling for robust data recovery
- Mid-bit sampling for maximum data validity
- Automatic start bit detection
- Comprehensive error checking

## Diagrams
### RTL Diagram
<img width="1050" height="484" alt="image" src="https://github.com/user-attachments/assets/0c69e1bb-6137-40ef-af64-1df28d875a28" />

### State Diagram
<img width="845" height="309" alt="image" src="https://github.com/user-attachments/assets/47fbbd02-a050-4974-adcb-699cbc03f1d3" />

## ⚙️ Parameters

| Parameter | Default Value | Description |
|-----------|--------------|-------------|
| `SYS_FREQ` | 50,000,000 Hz | System clock frequency |
| `BAUD_RATE` | 9600 | Target baud rate |
| `DATABITS` | 8 | Width of data packet |
| `PARITY_EN` | 1 | 1 = Enabled, 0 = Disabled |
| `PARITY_TYPE` | 0 | 0 = Even Parity, 1 = Odd Parity |

## 🚀 Getting Started

### Prerequisites

- SystemVerilog simulator (ModelSim, QuestaSim, VCS, or Xcelium)
- Basic understanding of UART protocol
- Synthesis tool (optional, for FPGA implementation)

## 🧪 Verification

The design employs a sophisticated layered testbench architecture inspired by UVM methodology:

### Testbench Components

1. **Transaction Object** (`class trans`)
   - Randomized data generation
   - Error injection capabilities
   - Constraint-based testing (80% normal, 20% error cases)

2. **Generator** (`class gener`)
   - Creates randomized transactions
   - Controls test stimulus generation

3. **Driver** (`class driv`)
   - Drives physical interface signals
   - Implements protocol timing

4. **Monitor** (`class montr`)
   - Observes interface activity
   - Captures output data

5. **Scoreboard** (`class scrboard`)
   - Compares expected vs. actual results
   - Tracks pass/fail statistics
   - Provides test summary

6. **Coverage** (`class coverage`)
   - Functional coverage collection
   - Ensures all data patterns (0x00 to 0xFF) are tested
   - Verifies control path coverage

### Test Scenarios

- ✅ Standard random data transmission
- ✅ Even/Odd parity verification
- ✅ Parity error injection and detection
- ✅ Stop bit (frame) error injection and detection
- ✅ Back-to-back transmission stress testing
- ✅ Full data pattern coverage (0x00 - 0xFF)

## 📊 Simulation Results

The design has been thoroughly verified with:
- **100% functional coverage** across all data patterns
- **Zero defects** in protocol compliance
- **Robust error detection** for parity and frame errors
- **Successful back-to-back transmission** without data loss

Sample test output shows comprehensive pass/fail tracking with detailed transaction logging.
<img width="586" height="480" alt="image" src="https://github.com/user-attachments/assets/2063d343-f147-4e27-b7c6-071713051145" />
Simulation Log

<img width="1095" height="915" alt="image" src="https://github.com/user-attachments/assets/1588c842-ba89-47e7-8bde-f838333afbcb" />
Waveform

## 📁 File Structure

```
src/
  ├──uart_top.sv              # Top-level module
  ├── uart_tx.sv              # UART Transmitter
  ├── uart_rx.sv              # UART Receiver
testbench/
  ├── uart_tb.sv              # Main testbench file
  ├── uart_tb_package.sv      # Testbench class definitions
README.md               
```

## 🎓 Key Concepts Demonstrated

- **FSM Design**: Clean state machine implementations
- **Protocol Timing**: Precise baud rate generation and sampling
- **Error Handling**: Comprehensive error detection mechanisms
- **Verification**: Advanced testbench with constrained randomization
- **Modular Design**: Reusable, parameterized components
- **SystemVerilog OOP**: Class-based verification environment

## 🔧 Synthesis Considerations

- The design is **synthesis-ready** for FPGA implementation
- All FSMs use registered outputs for timing closure
- Clock domain considerations handled appropriately
- Resource usage scales with `DATABITS` parameter
## 📧 Contact

For questions or suggestions, please open an issue on GitHub.

---

**Note**: For detailed design specifications, waveform analysis, and verification methodology, please refer to the included `Documentation.pdf`.
