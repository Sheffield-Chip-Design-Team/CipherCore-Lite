# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

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

@cocotb.test()
async def test_dut_rx(dut):
    
    total_tests = 100

    # Connect to tx UART VIP
    tx_Uart = UART.UartVIP( dut, is_active=True, dut_rx_pin="rx")

    # Set the clock period to        1042 ns 
    dut._log.info("Starting clock")
    clock = Clock(dut.clk, 33.332, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset DUT
    await reset_dut(dut)
    
    for i in range(total_tests):

        # Random delay between frame transmissions
        await Timer(random.randint(1, 10000), unit='us')  

        # Send random byte to DUT rx bus
        byte = random.randint(0, 255)
        await tx_Uart.serial_write_byte(byte)
        tx_Uart.log.info(f"Sent Byte {format(hex(byte))} to DUT rx bus.")
       
        await ClockCycles(dut.clk, random.randint(0, 10))  # Wait for some cycles to before checking
        
        # checks for received byte and status signals
        assert dut.rx_valid.value == 1, "frame not receieved correctly - rx_valid not asserted"
        assert dut.rx_data.value.to_unsigned() == byte, f"RX Data Mismatch: Expected {format(hex(byte))}, Got {format(hex(dut.rx_valid.value))}"
        
        dut._log.info(f"Byte: {format(hex(byte))} received correctly! Frame {i+1}/{total_tests} Passed.")

