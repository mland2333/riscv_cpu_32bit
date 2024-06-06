#pragma once
#include <cstdint>
#define CONFIG_MBASE 0x30000000
#define CONFIG_MSIZE 0x1000000
extern void* mem;
#define v_to_p(addr) (((uint64_t)addr - (uint64_t)CONFIG_MBASE) + (uint64_t)mem)

extern char* flash;
#define FLASH_SIZE 0x10000000
#define FLASH_BASE 0x30000000
#define flash_addr(addr) ((uint64_t)addr + (uint64_t)flash)

extern char* psram;
#define PSRAM_SIZE 0x20000000
#define PSRAM_BASE 0x80000000
#define psram_addr(addr) ((uint64_t)addr + (uint64_t)psram)


long mem_init(char* img_file);
uint64_t vmem_read(uint32_t addr, int len);
void mem_write(void *addr, int len, uint64_t data);
uint64_t mem_read(void *addr, int len);
void vmem_write(uint32_t addr, int len, uint64_t data);
