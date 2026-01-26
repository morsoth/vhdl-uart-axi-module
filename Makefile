GHDL ?= /ucrt64/bin/ghdl
GTKWAVE ?= /ucrt64/bin/gtkwave

TOP ?= tb_uart_tx

WORKDIR := build/ghdl
WAVE    := build/$(TOP).ghw
GTKW	:= waves/$(TOP).gtkw

SRCS := $(shell find rtl tb -type f -name "*.vhd")
GHDLFLAGS := --std=08 --workdir=$(WORKDIR)

.PHONY: all sim wave clean

all: sim wave

sim: $(WAVE)

$(WAVE): $(SRCS)
	@mkdir -p $(WORKDIR) build
	$(GHDL) -a $(GHDLFLAGS) $(SRCS)
	$(GHDL) -e $(GHDLFLAGS) $(TOP)
	$(GHDL) -r $(GHDLFLAGS) $(TOP) --wave=$(WAVE)

wave: sim
	@mkdir -p $(WORKDIR) waves
	@if [ -f "$(GTKW)" ]; then \
		$(GTKWAVE) $(WAVE) $(GTKW); \
	else \
		$(GTKWAVE) $(WAVE); \
	fi

clean:
	rm -rf build