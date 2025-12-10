# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import logging
import cocotb
import random
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer

from vip import UART

async def reset_dut(dut):
    dut._log.info("Resetting DUT")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)
    dut._log.info("DUT Reset complete")

async def trigger_byte_frame(dut, data=256):
    if data >= 256:
        data = random.randint(0, 255)
       
    data_byte = data & 0xFF 
    dut._log.info(f"Requesting DUT to send byte: {format(hex(data_byte))}")

    dut.tx_data.value = data_byte
    await ClockCycles(dut.clk, 1)
    dut.tx_start.value = 1
    await ClockCycles(dut.clk, 1)
    dut.tx_start.value = 0

    return data_byte

def calc_parity(data_byte, parity_bit, parity_type='odd'):
    """ Check odd parity for the given data byte """
    calculated_parity = 0
    for i in range(8):
        calculated_parity ^= (data_byte >> i) & 0x1

    if parity_type == 'odd':
        calculated_parity ^= 0x1  # Invert for odd parity

    return calculated_parity

@cocotb.test()
async def test_dut_tx(dut):
    
    num_tests = 100
    
    # Connect to tx UART VIP
    # Automatically set to 9600 baud and odd parity
    rx_Uart = UART.UartVIP(dut, dut_tx_pin="tx")
    rx_Uart.is_active = False  # Set to monitor mode
    rx_Uart.log.setLevel(logging.INFO)

    # Set the clock period to 1042 ns 
    dut._log.info("Starting clock")
    clock = Clock(dut.clk, 33.33, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset DUT
    await reset_dut(dut)

    # Test UART TX by sending random bytes from DUT and monitoring them with the VIP
    for i in range(num_tests):
        
        await Timer(random.randint(10, 500), unit='us')  # Random delay between sending frames
        
        data_byte            = await trigger_byte_frame(dut)
        monitored_uart_trans = await rx_Uart.serial_read_byte()

        # Check received transaction
        assert monitored_uart_trans.parity_bit == calc_parity(data_byte, monitored_uart_trans.parity_bit), "Incorrect Parity Bit Detected"
        assert monitored_uart_trans.data == data_byte, f"TX Data Mismatch: Expected {format(hex(data_byte))}"
        assert monitored_uart_trans.start_bit == 0, "High Start Bit Detected"
        assert monitored_uart_trans.stop_bit == 1, "Low Stop Bit Detected"

        dut._log.info(f"Scoreboard Correctly Received Byte: {format(hex(data_byte))}. Frame {i+1}/{num_tests} Passed.")