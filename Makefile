#-------------------------------------------------------------------------------
# Copyright (c) 2026 Pedro Botelho
#-------------------------------------------------------------------------------
# FILE NAME : Makefile
# AUTHOR : Pedro Henrique Magalhães Botelho
# AUTHOR’S EMAIL : pedro.botelho@ufc.br
#-------------------------------------------------------------------------------

# Project
BOARD 		= tangnano9k
PROJECT 	= $(BOARD)_hdmi
TOP_MODULE 	= Top

# Files
SCRIPTS_DIR	= ./scripts
SRC_DIR 	= ./rtl
OUTPUT_DIR 	= ./output
TB_DIR		= ./tb
CST_FILE 	= ./cst/TangNano_9k.cst
SDC_FILE	= ./sdc/Clocks.sdc
SRCS 		= $(shell find $(SRC_DIR) -type f -name '*.v')
SIM_FILES 	= $(shell find $(TB_DIR) -type f -name '*.v')

# FPGA
DEVICE 		= GW1NR-LV9QN88PC6/I5
FAMILY 		= GW1N-9C

# Files
SYNTH_LOG   = $(OUTPUT_DIR)/$(PROJECT)_synth.log
PNR_LOG     = $(OUTPUT_DIR)/$(PROJECT)_pnr.log
JSON 		= $(OUTPUT_DIR)/$(PROJECT).json
PNR_JSON 	= $(OUTPUT_DIR)/$(PROJECT)_pnr.json
FS 			= $(OUTPUT_DIR)/$(PROJECT).fs
VVP 		= $(OUTPUT_DIR)/$(PROJECT).vvp

# Image
GENBIN		= $(SCRIPTS_DIR)/genbin.py
IMG_IN 		?= examples/image.bmp
BIN_OUT 	?= $(OUTPUT_DIR)/image.bin
OFFSET 		?= 0x100000

# Flags
SYNTH		= yosys
PNR			= nextpnr-himbaechel
PACK		= gowin_pack
SYNTH_FLAGS	= -noalu -nowidelut -nolutram -nodffe -retime
PNR_FLAGS	= -v --device ${DEVICE} --vopt freq=27 --vopt enable-globals --vopt enable-auto-longwires --vopt family=${FAMILY}
PACK_FLAGS	= -d $(FAMILY)

all: flash

build: $(FS)

test: $(VVP)
	vvp $(VVP)

$(OUTPUT_DIR):
	mkdir -p $@

$(JSON): $(SRCS) | $(OUTPUT_DIR)
	$(SYNTH) -p "read_verilog $^; synth_gowin $(SYNTH_FLAGS) -top $(TOP_MODULE) -json $@" > $(SYNTH_LOG) 2>&1

$(PNR_JSON): $(JSON) $(CST_FILE) $(SDC_FILE)
	$(PNR) --json $< --write $@ $(PNR_FLAGS) --vopt cst=$(CST_FILE) --vopt sdc=$(SDC_FILE) > $(PNR_LOG) 2>&1

$(FS): $(PNR_JSON)
	$(PACK) $(PACK_FLAGS) -o $@ $<

$(VVP): $(SRCS) $(SIM_FILES)
	iverilog -o $@ $^

clean:
	rm -rf $(OUTPUT_DIR)/*

flash: build
	openFPGALoader -b $(BOARD) $(FS)

gen-img: $(IMG_IN)
	python $(GENBIN) $< $(BIN_OUT)

flash-img: gen-img
	sudo openFPGALoader -b tangnano9k -f --file-type raw --offset $(OFFSET) $<

.PHONY: all build test clean flash flash-img gen-img
