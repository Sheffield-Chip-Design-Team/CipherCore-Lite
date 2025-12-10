# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

SIM=verilator
TOPLEVEL_LANG ?= verilog

SRC_DIR = $(PWD)/../../../src
PROJECT_SOURCES = tx.v
EXTRA_ARGS += --trace --trace-fst --trace-structs
export PYTHONPATH := $(PWD)/../../:$(PYTHONPATH)

SIM_BUILD = sim_build/rtl

VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))
VERILOG_SOURCES += $(PWD)/tx_wtb.v

COMPILE_ARGS += -I$(SRC_DIR)

TOPLEVEL = uart_tx_wtb
COCOTB_TEST_MODULES = test_tx


include $(shell cocotb-config --makefiles)/Makefile.sim
