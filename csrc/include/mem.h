#pragma once
#include <cstdint>
#define BASE 0x80000000

extern void* mem;
#define v_to_p(addr) (((uint64_t)addr - (uint64_t)BASE) + (uint64_t)mem)

long mem_init(char* img_file);
uint64_t vmem_read(uint32_t addr, int len);
void mem_write(void *addr, int len, uint64_t data);
uint64_t mem_read(void *addr, int len);
