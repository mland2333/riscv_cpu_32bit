TOPNAME = top
INC_PATH ?=

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert --trace 

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

CDIRS := $(shell find $(abspath ./csrc) -mindepth 1 -type d)
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath $(CDIRS)) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(shell find $(abspath ./csrc) -maxdepth 1 -name "*.c" -or -name "*.cc" -or -name "*.cpp")

FILELIST_MK = $(shell find -L ./csrc -name "filelist.mk")
include $(FILELIST_MK)
IMG ?=
ELF ?=
RUNFLAGS ?=
ifneq ($(strip $(ELF)),)
	CXXFLAGS += -DCONFIG_FTRACE
	RUNFLAGS += -f $(ELF)
endif

INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\"" -g
CXXFLAGS += -DCONFIG_ITRACE
LDFLAGS += $(LIBS)

$(BIN): $(VSRCS) $(CSRCS)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

all: default

run: $(BIN)
	@$^ $(IMG) $(RUNFLAGS)
gdb: $(BIN)
	gdb --args $(BIN) $(IMG) $(RUNFLAGS)

clean:
	rm -rf $(BUILD_DIR)
