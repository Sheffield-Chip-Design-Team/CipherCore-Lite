# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0
import random 
import cocotb
import logging

from vip.common.VIP import VIP_Base 
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

class UART_VIP (VIP_Base):
    
    def __init__(self, dut, dut_rx_pin="", dut_tx_pin=""):
        super().__init__()
        
        # UART parameters
        self.baud_rate    = 9600         # Baud rate (Bits transferred per second)
        self.data_bits    = 8            # Number of data bits
        self.has_parity   = True         # Enable parity bit 
        self.bit_period   = (1_000_000_000) // self.baud_rate  # (bit period in ns)
    
        # Connect to DUT pins
        self.tx = self.resolve_handle(dut, dut_rx_pin)
        self.rx = self.resolve_handle(dut, dut_tx_pin)
        
        self.tx.value = 1  # Idle state

        # Log Setup
        self.log = logging.getLogger(f"cocotb.tb.uart_vip[{self.id}]")
        self.log.setLevel("INFO") 

    async def serial_write_byte (self, data):
        """ Drive the RX pin with a UART frame """   
        
        delay_time = random.randint(0, self.bit_period)  # Random delay before sending
        await Timer(delay_time, unit='ns')

        # Start bit
        self.tx.value = 0
        await Timer(self.bit_period, unit='ns')
       
        # Data bits 
        for i in range(self.data_bits):
            self.tx.value = (data >> i) & 0x1
            await Timer(self.bit_period, unit='ns')

        # Stop bit
        self.tx.value = 1
        await Timer(self.bit_period, unit='ns')
        

    async def serial_read_byte (self, data):
        """ monitor the RX pin """   

        # Wait for start bit
        while self.rx.value != 0:
            await Timer(self.bit_period // 10, unit='ns')  # Polling interval

        # Start bit detected
        await Timer(self.bit_period + self.bit_period // 2, unit='ns')  # Move to middle of first data bit

        received_data = 0
        for i in range(self.data_bits):
            bit = self.rx.value
            received_data |= (bit << i)
            await Timer(self.bit_period, unit='ns')

        # Stop bit
        stop_bit = self.rx.value
        if stop_bit != 1:
            self.log.warning("Stop bit not detected correctly!")

        self.log.info(f"Received data: 0x{received_data:02X}")

# # todo uvm style classes (transactions, sequences, drivers, monitors)
# class Uart_Transaction:

#     def __init__(self, data, timestamp=None):
#         self.start_bit   = 0
#         self.data        = data
#         self.has_parity  = True
#         self.parity_type = 'odd'
#         self.stop_bit    = 1
#         self.timestamp   = timestamp

#     def __repr__(self):
#         return f"<UART_TXN data=0x{self.data:02X} time={self.timestamp}>"