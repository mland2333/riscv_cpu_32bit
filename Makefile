TOPNAME = top
NXDC_FILES = constr/top.nxdc
INC_PATH += $(NPC_HOME)/csrc/include
INC_PATH += $(NPC_HOME)/vsrc
INC_PATH += $(YSYX_HOME)/ysyxSoC/perip/uart16550/rtl
INC_PATH += $(YSYX_HOME)/ysyxSoC/perip/spi/rtl

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert --trace --timescale "1ns/1ns" --notiming --autoflush

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

# constraint file
#SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
#$(SRC_AUTO_BIND): $(NXDC_FILES)
#	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
CDIRS := $(shell find $(abspath ./csrc) -mindepth 1 -type d)

# project source
VSRCS += $(YSYX_HOME)/ysyxSoC/build/ysyxSoCFull.v
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath $(CDIRS)) -name "*.c" -or -name "*.cc" -or -name "*.cpp")

CSRCS += $(shell find $(abspath ./csrc) -maxdepth 1 -name "*.c" -or -name "*.cc" -or -name "*.cpp")
#CSRCS += ./csrc/main.cpp
CSRCS += $(SRC_AUTO_BIND)

FILELIST_MK = $(shell find -L ./csrc -name "filelist.mk")
include $(FILELIST_MK)

ELF ?=
RUNFLAGS ?=
# rules for NVBoard
#include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""# -g
#CFLAGS += -DCONFIG_ITRACE

RUNFLAGS ?=
ifneq ($(strip $(ELF)),)
	#CFLAGS += -DCONFIG_FTRACE
	RUNFLAGS += -f $(ELF)
endif

DIFF_NUME_SO = $(NEMU_HOME)/build/riscv32-nemu-interpreter-so

ifneq ($(strip $(DIFF_NUME_SO)),)
	#CFLAGS += -DCONFIG_DIFFTEST
	CFLAGS += -l$(DIFF_NUME_SO)
	RUNFLAGS += -d $(DIFF_NUME_SO)

endif

#CFLAGS += -DCONFIG_MTRACE
#CFLAGS += -DCONFIG_KEYBOARD
LDFLAGS += $(LIBS)
LDFLAGS += -lSDL2
$(BIN): $(VSRCS) $(CSRCS) #$(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module ysyxSoCFull $^ \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		$(INCFLAGS) --Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

all: default

run: $(BIN)
	@$^ $(IMG) $(RUNFLAGS)
gdb: $(BIN)
	gdb --args $(BIN) $(IMG) $(RUNFLAGS)

clean:
	rm -rf $(BUILD_DIR)
sim: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@$^
	

include ../Makefile
