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
async def test_dut_tx(dut):
    
    # Connect to tx UART VIP
    # Automatically set to 9600 baud and odd parity
    tx_Uart = UART.UartVIP(dut, dut_tx_pin="tx")

    # Set the clock period to 1042 ns 
    dut._log.info("Starting clock")
    clock = Clock(dut.clk, 33.33, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset DUT
    await reset_dut(dut)
    
    # Test UART TX by sending random bytes from DUT and monitoring them with the VIP
    for i in range(10):
        data_byte = random.randint(0, 255)
        dut._log.info(f"Requesting DUT to send byte: {format(hex(data_byte))}")
        
        dut.tx_data.value  = data_byte
        await ClockCycles(dut.clk, 1)
        dut.tx_start.value = 1
        read_byte = await tx_Uart.serial_read_byte()

        # byte = random.randint(0, 255)
        # await tx_Uart.serial_write_byte(byte)
        # tx_Uart.log.info(f"Sent Byte {format(hex(byte))} to DUT rx bus.")
       
        # await ClockCycles(dut.CLK, random.randint(10, 50))  # Wait for some cycles to before checking
        
        # assert dut.RX_VALID.value == 1, "RX_DONE not asserted"
        # assert dut.RX_DATA.value.to_unsigned() == byte, f"RX Data Mismatch: Expected {format(hex(byte))}, Got {format(hex(dut.RX_DATA.value.integer))}"
        
        # dut._log.info(f"Byte: {format(hex(byte))} received correctly!")

        # await Timer(random.randint(1, 10000), unit='us')  # Random delay between packets
