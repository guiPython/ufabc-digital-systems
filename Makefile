GHDL ?= ghdl
VHDL_STD ?= 08
ARCH ?= adder

WORK_DIR := build/ghdl
VCD_DIR := build/vcd

FP_ADDER_SRC := utils/adder.vhd
ADDER_TB_SRC := utils/adder_testbench.vhd
ADDER_TB := adder_testbench

UNSIGNED_ADDER_SRC := adder_unsigned.vhd
UNSIGNED_ADDER_TB_SRC := adder_unsigned_testbench.vhd
UNSIGNED_ADDER_TB := adder_unsigned_testbench

GHDL_FLAGS := --std=$(VHDL_STD) --workdir=$(WORK_DIR)
GHDL_BUILD_FLAGS := --std=$(VHDL_STD) --workdir=.

.PHONY: analyze analyze-adder analyze-adder-unsigned
.PHONY: elaborate-adder simulate-adder adder
.PHONY: elaborate-adder-unsigned simulate-adder-unsigned adder-unsigned
.PHONY: help clean

help:
	@echo "Usage:"
	@echo "  make ARCH=adder       Analyze, elaborate, and simulate the common adder"
	@echo "  make adder-unsigned   Analyze, elaborate, and simulate the packed unsigned adder"
	@echo ""
	@echo "Equivalent shortcuts: make adder"
	@echo "Other targets:        make show-adder | make clean"

adder: simulate-adder
	@echo "[OK] Common adder analyzed, elaborated, and simulated successfully."

adder-unsigned: simulate-adder-unsigned
	@echo "[OK] Unsigned adder analyzed, elaborated, and simulated successfully."

analyze: analyze-adder

analyze-adder: | $(WORK_DIR)
	@echo "[1/3] Analyzing adder sources..."
	$(call require_files,$(FP_ADDER_SRC) $(ADDER_TB_SRC))
	@$(GHDL) -a $(GHDL_FLAGS) $(FP_ADDER_SRC)
	@$(GHDL) -a $(GHDL_FLAGS) $(ADDER_TB_SRC)

analyze-adder-unsigned: | $(WORK_DIR)
	@echo "[1/3] Analyzing unsigned adder sources..."
	$(call require_files,$(UNSIGNED_ADDER_SRC) $(UNSIGNED_ADDER_TB_SRC))
	@$(GHDL) -a $(GHDL_FLAGS) $(UNSIGNED_ADDER_SRC)
	@$(GHDL) -a $(GHDL_FLAGS) $(UNSIGNED_ADDER_TB_SRC)

elaborate-adder: analyze-adder
	@echo "[2/3] Elaborating the testbench..."
	@cd $(WORK_DIR) && $(GHDL) -e $(GHDL_BUILD_FLAGS) $(ADDER_TB)

elaborate-adder-unsigned: analyze-adder-unsigned
	@echo "[2/3] Elaborating the unsigned testbench..."
	@cd $(WORK_DIR) && $(GHDL) -e $(GHDL_BUILD_FLAGS) $(UNSIGNED_ADDER_TB)

simulate-adder: elaborate-adder | $(VCD_DIR)
	@echo "[3/3] Simulating and generating VCD file..."
	@$(WORK_DIR)/$(ADDER_TB) \
		--assert-level=error \
		--ieee-asserts=disable-at-0 \
		--vcd=$(VCD_DIR)/adder.vcd
	@echo "[OK] VCD generated at: $(abspath $(VCD_DIR)/adder.vcd)"

simulate-adder-unsigned: elaborate-adder-unsigned | $(VCD_DIR)
	@echo "[3/3] Simulating unsigned adder and generating VCD file..."
	@$(WORK_DIR)/$(UNSIGNED_ADDER_TB) \
		--assert-level=error \
		--ieee-asserts=disable-at-0 \
		--vcd=$(VCD_DIR)/adder_unsigned.vcd
	@echo "[OK] VCD generated at: $(abspath $(VCD_DIR)/adder_unsigned.vcd)"

$(WORK_DIR) $(VCD_DIR):
	@mkdir -p $@

clean:
	@$(GHDL) --clean --workdir=$(WORK_DIR) 2>/dev/null || true
	@rm -rf build
	@rm -f $(ADDER_TB) e~$(ADDER_TB).o
	@rm -f $(UNSIGNED_ADDER_TB) e~$(UNSIGNED_ADDER_TB).o
