#pragma once

#ifdef CONFIG_FTRACE
#include <elf.h>

void init_ftrace(char* elf_file);
int f_call(uint32_t ptr);
int f_ret(uint32_t ptr);
void ftrace(uint32_t, uint32_t, uint32_t);
#endif
