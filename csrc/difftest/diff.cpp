#ifdef CONFIG_DIFFTEST
#include <iostream>
#include <dlfcn.h>
#include <cstdlib>
#include "mem.h"
#include "cpu.h"
#include <cstdint>
CPU_status ref_cpu;
extern CPU_status cpu;
enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };
void (*difftest_memcpy)(uint64_t addr, void *buf, size_t n, bool direction) = NULL;
void (*difftest_regcpy)(void *dut, bool direction) = NULL;
void (*difftest_exec)(uint64_t n) = NULL;
void (*difftest_raise_intr)(uint64_t NO) = NULL;

int icount = 0;
bool npc_is_ref_skip = false;

void init_difftest(char *ref_so_file, long img_size, int port)
{
  if(ref_so_file == nullptr){
    printf("no ref_so_file\n");
    exit(0);
  }
  void* handle = dlopen(ref_so_file, RTLD_LAZY);
  difftest_memcpy = reinterpret_cast<void (*)(uint64_t, void*, size_t, bool)>(dlsym(handle, "difftest_memcpy"));

  difftest_regcpy = reinterpret_cast<void (*)(void*, bool)>(dlsym(handle, "difftest_regcpy"));

  difftest_exec = reinterpret_cast<void (*)(uint64_t)>(dlsym(handle, "difftest_exec"));

  //difftest_raise_intr = dlsym(handle, "difftest_raise_intr");

  void (*difftest_init)(int) = reinterpret_cast<void (*)(int)>(dlsym(handle, "difftest_init"));

  difftest_init(port);
  difftest_memcpy(CONFIG_MBASE, (void*)v_to_p(CONFIG_MBASE), img_size, DIFFTEST_TO_REF);
  difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}

extern CPU_status cpu;
int check_regs(CPU_status* ref){
  for(int i = 0; i<32; i++){
    if(ref->gpr[i] != cpu.gpr[i])
       return i; 
  }
    
  if(ref->pc != cpu.pc)
    return -1;
  return 0;
}


int difftest_step(){
  if(npc_is_ref_skip){
    //cpu.pc += 4;
    difftest_regcpy(&cpu, DIFFTEST_TO_REF);
    //cpu.pc -= 4;
    npc_is_ref_skip = false;
    printf("cpu.pc = 0x%x\n", cpu.pc);
    return 0;
  }
  difftest_exec(1);
  icount ++;
  int i;
  difftest_regcpy(&ref_cpu, DIFFTEST_TO_DUT);
  //cpu_display(&ref_cpu);
  //cpu_display(&cpu);
  //printf("第%d条指令\n", icount);
  if((i = check_regs(&ref_cpu)) != 0){
    printf("difftest失败, 执行了%d条指令, 寄存器为：x[%d], 地址：0x%x\ncpu.gpr[i] = 0x%x\nref_gpr[i] = 0x%x\n",
           icount, i, cpu.pc, cpu.gpr[i], ref_cpu.gpr[i]);
    
    cpu_display(&cpu);
    cpu_display(&ref_cpu);
    return -1;
  }
  return 0;
}

#endif

