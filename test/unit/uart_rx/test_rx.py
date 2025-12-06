# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
import random
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer

from vip import UART

async def reset_dut(dut):
    dut._log.info("Resetting DUT")
    dut.RST_N.value = 0
    await ClockCycles(dut.CLK, 5)
    dut.RST_N.value = 1
    await ClockCycles(dut.CLK, 5)
    dut._log.info("DUT Reset complete")

@cocotb.test()
async def test_dut_rx(dut):
    
    # Connect to tx UART VIP
    tx_Uart = UART.UART_VIP(dut, dut_rx_pin="RX")

    # Set the clock period to 1042 ns 
    dut._log.info("Starting clock")
    clock = Clock(dut.CLK, 10416, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset DUT
    await reset_dut(dut)
    
    for i in range(100):

        byte = random.randint(0, 255)
        await tx_Uart.serial_write_byte(byte)
        tx_Uart.log.info(f"Sent Byte {format(hex(byte))} to DUT rx bus.")
       
        await ClockCycles(dut.CLK, random.randint(10, 50))  # Wait for some cycles to before checking
        
        assert dut.RX_VALID.value == 1, "RX_DONE not asserted"
        assert dut.RX_DATA.value.to_unsigned() == byte, f"RX Data Mismatch: Expected {format(hex(byte))}, Got {format(hex(dut.RX_DATA.value.integer))}"
        
        dut._log.info(f"Byte: {format(hex(byte))} received correctly!")

        await Timer(random.randint(1, 10000), unit='us')  # Random delay between packets
