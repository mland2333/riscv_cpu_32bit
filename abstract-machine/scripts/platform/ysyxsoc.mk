AM_SRCS := riscv/ysyxsoc/start.S \
           riscv/ysyxsoc/trm.c \
					 riscv/ysyxsoc/ioe.c \
					 riscv/ysyxsoc/trap.S \
					 riscv/ysyxsoc/timer.c \
					 riscv/ysyxsoc/input.c \
					 riscv/ysyxsoc/gpu.c \
					 riscv/ysyxsoc/mpe.c \
					 riscv/ysyxsoc/vme.c \
					 riscv/ysyxsoc/cte.c

CFLAGS    += -fdata-sections -ffunction-sections -ffreestanding
LDFLAGS   += -T $(AM_HOME)/scripts/linker-ysyxsoc.ld \
						 --defsym=_rom_start=0x20000000 --defsym=_entry_offset=0x0
LDFLAGS   += --gc-sections -e _start
CFLAGS += -DMAINARGS=\"$(mainargs)\"
CFLAGS += -I$(AM_HOME)/am/src/riscv/ysyxsoc/include
.PHONY: $(AM_HOME)/am/src/riscv/ysyxsoc/trm.c
NPCFLAGS += -b
image: $(IMAGE).elf
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: image
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) run ARGS=$(NPCFLAGS) IMG=$(IMAGE).bin ELF=$(IMAGE).elf \
		CONFIG_YSYXSOC=1

gdb: image
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) gdb ARGS=$(NPCFLAGS) IMG=$(IMAGE).bin ELF=$(IMAGE).elf \
		CONFIG_YSYXSOC=1
