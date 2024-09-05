#pragma once
#include <cstdint>
typedef struct{
  uint32_t gpr[16];
  uint32_t pc;
}CPU_status;

void cpu_display(CPU_status* mcpu);
