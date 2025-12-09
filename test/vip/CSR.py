# SPDX-FileCopyrightText: 
# SPDX-License-Identifier: Apache-2.0

import random 
import cocotb
import logging

from common.VIP import VIP_Base 
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

class CSR_VIP (VIP_Base):
    
    def __init__(self, dut, rst, data_bus, addr_bus, wr_en, rd_en, data_out):
        super().__init__()
        
        # CSR parameters
        # Log Setup
        self.log = logging.getLogger(f"cocotb.tb.csr_vip.{self.id}")
        self.log.setLevel("INFO") 

    
    def write_csr(self, address, data):
        """ Write data to CSR at given address """   
        pass

    def read_csr(self, address):
        """ Read data from CSR at given address """   
        pass

    def rst_csr(self):
        """ Reset CSR interface """   
        pass

 