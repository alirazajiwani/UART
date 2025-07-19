# UART
This repository contains resources and (if applicable, code/hardware designs) related to Universal Asynchronous Receiver/Transmitter (UART) communication. This project aims to provide a clear understanding and practical implementation examples of UART.

## What is UART?
UART is a fundamental serial communication protocol widely used for short-distance, low-speed data exchange between microcontrollers, computers, and peripheral devices

**UART** is a hardware communication protocol that enables **asynchronous serial data transfer** between two devices, typically using just two lines:
**TX**: Transmit data
**RX**: Receive data

It sends data **bit-by-bit** without using a shared clock, making it simple and effective for short-distance communication.

## Features

- Full-duplex serial communication
- Configurable **baud rate**, **data bits**, **stop bits**, and **parity**
- Error detection (parity, framing)
- Easy integration with microcontrollers, FPGAs, and PCs

## Getting Started
To get a local copy up and running, follow these simple steps.

### Prerequisites

- Modelsim or any other IDE (VS code, sublime text, Gowin EDA etc)
- Quartus

## UART Simulation

After cloning the repository, open **'\Modelsim\UART.mpf'** in modelsim or add all the **'.sv'** files in your IDE project folder. Upon running the testbench, the terminal should show:

<img width="221" height="91" alt="Results" src="https://github.com/user-attachments/assets/65cc31be-35af-465d-917c-e1c8e5a76d0e" />

And, the waveforms:


<img width="792" height="228" alt="Timing Signals" src="https://github.com/user-attachments/assets/8303d06d-7289-4d4c-ae89-2c23e168d04e" />


---

**NOTE:** For Further knowledge, please check '/UART_documentation.docx'
