GHDL ?= ghdl
VHDL_STD ?= 08
ARCH ?= adder

WORK_DIR := build/ghdl
VCD_DIR := build/vcd

FP_ADDER_SRC := utils/adder.vhd
ADDER_TB_SRC := utils/adder_testbench.vhd
ADDER_TB := adder_testbench

GHDL_FLAGS := --std=$(VHDL_STD) --workdir=$(WORK_DIR)
GHDL_BUILD_FLAGS := --std=$(VHDL_STD) --workdir=.

.PHONY: analyze analyze-adder
.PHONY: elaborate-adder simulate-adder show-adder help clean adder

help:
	@echo "Usage:"
	@echo "  make ARCH=adder       Analyze, elaborate, and simulate the common adder"
	@echo ""
	@echo "Equivalent shortcuts: make adder"
	@echo "Other targets:        make show-adder | make clean"

adder: simulate-adder
	@echo "[OK] Common adder analyzed, elaborated, and simulated successfully."

analyze: analyze-adder

analyze-adder: | $(WORK_DIR)
	@echo "[1/3] Analyzing adder sources..."
	$(call require_files,$(FP_ADDER_SRC) $(ADDER_TB_SRC))
	@$(GHDL) -a $(GHDL_FLAGS) $(FP_ADDER_SRC)
	@$(GHDL) -a $(GHDL_FLAGS) $(ADDER_TB_SRC)

elaborate-adder: analyze-adder
	@echo "[2/3] Elaborating the testbench..."
	@cd $(WORK_DIR) && $(GHDL) -e $(GHDL_BUILD_FLAGS) $(ADDER_TB)

simulate-adder: elaborate-adder | $(VCD_DIR)
	@echo "[3/3] Simulating and generating VCD file..."
	@$(WORK_DIR)/$(ADDER_TB) \
		--assert-level=error \
		--ieee-asserts=disable-at-0 \
		--vcd=$(VCD_DIR)/adder.vcd
	@echo "[OK] VCD generated at: $(abspath $(VCD_DIR)/adder.vcd)"

$(WORK_DIR) $(VCD_DIR):
	@mkdir -p $@

clean:
	@$(GHDL) --clean --workdir=$(WORK_DIR) 2>/dev/null || true
	@rm -rf build
	@rm -f $(ADDER_TB) e~$(ADDER_TB).o
