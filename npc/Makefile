ifdef CONFIG_YSYXSOC
	TOPNAME = ysyxSoCFull #ysyx_20020207
else
	TOPNAME = ysyx_20020207
endif

NXDC_FILES = constr/top.nxdc
INC_PATH += $(NPC_HOME)/csrc/include
INC_PATH += $(NPC_HOME)/vsrc

ifdef CONFIG_YSYXSOC
INC_PATH += $(YSYX_HOME)/ysyxSoC/perip/uart16550/rtl
INC_PATH += $(YSYX_HOME)/ysyxSoC/perip/spi/rtl
endif

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert --trace --autoflush

ifdef CONFIG_YSYXSOC
	VERILATOR_CFLAGS += --timescale "1ns/1ns" --notiming --top-module ysyxSoCFull -DCONFIG_YSYXSOC
else
	VERILATOR_CFLAGS += --top-module ysyx_20020207
endif

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

ifdef CONFIG_YSYXSOC
# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

include $(NVBOARD_HOME)/scripts/nvboard.mk
CSRCS += $(SRC_AUTO_BIND)
endif

# project source
CDIRS := $(shell find $(abspath ./csrc) -mindepth 1 -type d)

# project source
ifdef CONFIG_YSYXSOC
VSRCS += $(YSYX_HOME)/ysyxSoC/build/ysyxSoCFull.v
VSRCS += $(shell find $(abspath ./vsrc) -name "*.v")
VSRCS += $(shell find $(abspath $(YSYX_HOME)/ysyxSoC/perip) -name "*.v")
else
VSRCS += $(shell find $(abspath ./vsrc) -name "*.v")
endif

CSRCS = $(shell find $(abspath $(CDIRS)) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(shell find $(abspath ./csrc) -maxdepth 1 -name "*.c" -or -name "*.cc" -or -name "*.cpp")
#CSRCS += ./csrc/main.cpp

FILELIST_MK = $(shell find -L ./csrc -name "filelist.mk")
include $(FILELIST_MK)

ARGS ?= -b
ELF ?=
RUNFLAGS ?=
IMG ?= ./test/char-test.bin

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CFLAGS += $(INCFLAGS) -DTOP_NAME=V$(TOPNAME) -g
# CFLAGS += -DCONFIG_ITRACE
# CFLAGS += -DCONFIG_KEYBOARD
# CFLAGS += -DCONFIG_DEVICE
# CFLAGS += -DCONFIG_VGA
# CFLAGS += -DCONFIG_NVBOARD
CFLAGS += -DCONFIG_GTKTRACE
#CFLAGS += -DCONFIG_MTRACE
ifdef CONFIG_YSYXSOC
	CFLAGS += -DCONFIG_YSYXSOC
endif
ifneq ($(strip $(ELF)),)
	# CFLAGS += -DCONFIG_FTRACE
	RUNFLAGS += -f $(ELF)
endif

OBJCACHE = ccache
CC = ccache gcc
CXX = ccache g++

DIFF_NUME_SO = $(NEMU_HOME)/build/riscv32-nemu-interpreter-so

ifneq ($(strip $(DIFF_NUME_SO)),)
	# CFLAGS += -DCONFIG_DIFFTEST
	CFLAGS += -l$(DIFF_NUME_SO)
	RUNFLAGS += -d $(DIFF_NUME_SO)
endif

CFLAGS += -std=c++20

LDFLAGS += $(LIBS)
LDFLAGS += -lSDL2
$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		$^ \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		$(INCFLAGS) --Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

all: default

RUNFLAGS += $(ARGS)
run: $(BIN)
	@$^ $(IMG) $(RUNFLAGS)
gdb: $(BIN)
	gdb --args $(BIN) $(IMG) $(RUNFLAGS)

clean:
	rm -rf $(BUILD_DIR)

include ../Makefile
sim: $(BIN)
	echo "sim"
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@$^ $(IMG) $(RUNFLAGS)
	


