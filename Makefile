#############################
#   RTL build               #
#############################

GHDL ?= ghdl
GTKWAVE ?= gtkwave

TOP ?= tb_uart_core

RTL_DIR := build/ghdl
WAVE    := build/$(TOP).ghw
GTKW	:= waves/$(TOP).gtkw

GHDLFLAGS := --std=08 --workdir=$(RTL_DIR)

RTL_SRCS := \
	rtl/fifo/fifo_sync.vhd \
	rtl/uart/uart_rx.vhd \
	rtl/uart/uart_tx.vhd \
	rtl/uart/uart_core.vhd \
	rtl/regfile/uart_regfile.vhd \
	rtl/axi/axi_lite_slave.vhd

TB_SRCS := tb/$(TOP).vhd

#############################
#   C build                 #
#############################

CC ?= gcc
CFLAGS ?= -std=c11 -O2 -Wall -Wextra -Isw

C_DIR := build/c

C_SRCS := sw/main.c
C_OBJS := $(C_DIR)/main.o
C_EXE := build/uart_axi.exe

#############################
#   RTL targets             #
#############################

.PHONY: all sim wave c clean

all: sim wave

sim: $(WAVE)

$(WAVE): $(RTL_SRCS) $(TB_SRCS)
	@mkdir -p $(RTL_DIR) build
	$(GHDL) -a $(GHDLFLAGS) $(RTL_SRCS) $(TB_SRCS)
	$(GHDL) -e $(GHDLFLAGS) $(TOP)
	$(GHDL) -r $(GHDLFLAGS) $(TOP) --wave=$(WAVE)

wave: sim
	@mkdir -p $(RTL_DIR) waves
	@if [ -f "$(GTKW)" ]; then \
		$(GTKWAVE) $(WAVE) $(GTKW); \
	else \
		$(GTKWAVE) $(WAVE); \
	fi

#############################
#   C targets               #
#############################

c: $(C_EXE)

$(C_DIR)/%.o: sw/%.c
	@mkdir -p $(C_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(C_EXE): $(C_OBJS)
	@mkdir -p $(C_DIR)
	$(CC) $(CFLAGS) $^ -o $@

clean:
	rm -rf build