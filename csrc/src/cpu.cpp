#include "cpu.h"
#include <cstdio>
void cpu_display(CPU_status* mcpu){
  if(mcpu==nullptr){
    printf("error: mcpu等于0\n");
    return;
  }
  for(int i = 0; i<32; i++){
    printf("x[%d]=0x%x ", i, mcpu->gpr[i]);
  }
  printf("\n");
  printf("pc=0x%x\n", mcpu->pc);
}
