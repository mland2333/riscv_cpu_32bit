#include <cstdlib>
#include <chrono>
#include <getopt.h>
#include <stdio.h>
#include <assert.h>
#include "sdb.h"
#include "mem.h"
#include "device.h"
#include "ftrace.h"
#include "verilated.h"
#ifdef CONFIG_DIFFTEST

#endif


static char *img_file = NULL;
static char *elf_file = NULL;
static char *diff_so_file = NULL;
static uint32_t k = 0;
extern int batch;
extern bool mem_en;
extern bool mem_wen;
uint64_t d;
extern int write_sync;
extern void* vmem;

#ifdef CONFIG_DIFFTEST
extern bool npc_is_ref_skip_next;
#endif

#define FLASH_SIZE 0x10000000
#define FLASH_BASE 0x30000000
#define flash_addr(addr) ((uint64_t)addr + (uint64_t)flash)
char* flash;

extern "C" void flash_read(uint32_t addr, uint32_t *data) {
  //printf("flash addr = %x\n", addr);
  *data = *(uint32_t*)flash_addr(addr);
}
extern "C" void mrom_read(uint32_t addr, uint32_t *data) { 
  *data = vmem_read(addr, 4); 
}

void flash_init(){
  flash = (char*)malloc(FLASH_SIZE);

  const char* char_test = "/home/mland/ysyx-workbench/npc/test/char-test.bin";
  FILE *fp = fopen(char_test, "rb");

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  fseek(fp, 0, SEEK_SET);
  int ret = fread((void*)flash, size, 1, fp);
  fclose(fp);

  /*uint32_t* flash32 = (uint32_t*)flash;
  for(uint32_t i = 0; i < FLASH_SIZE / 4; i++)
     flash32[i] = i;*/
}

extern "C" int pmem_read(int addr) {
  uint32_t raddr = (uint32_t)addr;
  #ifdef CONFIG_DEVICE
  
  if (raddr == RTC_ADDR + 4) {
    #ifdef CONFIG_DIFFTEST
    npc_is_ref_skip_next = true;
    #endif
    //d = get_time();
    //return (int)(d >> 32); 
  }
  else if (raddr == RTC_ADDR) {
    #ifdef CONFIG_DIFFTEST
    npc_is_ref_skip_next = true;
    #endif
    //return (int)d;
  }
  else if(raddr == VGACTL_ADDR){
    return HEIGHT;
  }
  else if(raddr == VGACTL_ADDR + 2){
    return WIDTH;
  }
  else if(raddr == VGACTL_ADDR + 4){
    return write_sync;
  }
#ifdef CONFIG_KEYBOARD
  else if (raddr == KBD_ADDR) {
    //printf("读key\n");
    if(mem_en){
       k = get_key();
       if(k!=0) 
        printf("key=0x%x\n",k);
      return k;
    }
    return k;
  }
#endif
  else if(raddr >= FB_ADDR && raddr <= FB_ADDR + WIDTH*HEIGHT*4){
    return ((uint32_t*)vmem)[(raddr-FB_ADDR)/4];
  }
  
  else if(raddr < CONFIG_MBASE || raddr > CONFIG_MBASE + CONFIG_MSIZE){
    return 0;
  }
  
  #endif
  // 总是读取地址为`raddr & ~0x3u`的4字节返回
    return (int)vmem_read(raddr, 4);
}


extern "C" void pmem_write(int addr, int wdata, char wmask) {
    uint32_t waddr = (uint32_t) addr;
#ifdef CONFIG_DEVICE 
  if(waddr == SERIAL_PORT){
    #ifdef CONFIG_DIFFTEST
    npc_is_ref_skip_next = true;
    #endif
    
    if(mem_wen){
      //printf("here\n");
      //putchar(wdata&0xff);
    }
      
    return;
  }
  else if(waddr == VGACTL_ADDR + 4){
    write_sync = wdata;
    return;
  }
  else if (waddr == KBD_ADDR) {
        return;
  }
  else if(waddr >= FB_ADDR && waddr < FB_ADDR + WIDTH*HEIGHT*4){
    if(mem_wen)
      ((uint32_t*)vmem)[(waddr-FB_ADDR)/4] = wdata;
    return;
  }
  
#endif
  
  wmask = wmask & 0x00ff;
  uint8_t *cdata = (uint8_t*)(&wdata); 
  for(int i = 0; i<4; i++){
    if(((1<<i)&wmask) != 0){
      vmem_write(waddr+i, 1, (uint64_t)(*(cdata+i)));
    }
  }  // 总是往地址为`waddr & ~0x3u`的4字节按写掩码`wmask`写入`wdata`
  // `wmask`中每比特表示`wdata`中1个字节的掩码,
  // 如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变
}

void args_init(int argc, char *argv[]) {
  const struct option table[] = {
      {"batch", no_argument, NULL, 'b'},
      {"log", required_argument, NULL, 'l'},
      {"diff", required_argument, NULL, 'd'},
      {"port", required_argument, NULL, 'p'},
      {"file", required_argument, NULL, 'f'},
      {"help", no_argument, NULL, 'h'},
      {0, 0, NULL, 0},
  };
  int o;
  while ((o = getopt_long(argc, argv, "-bhl:d:p:f:", table, NULL)) != -1) {
    switch (o) {
    case 'b': batch = 1; break;
    // case 'p': sscanf(optarg, "%d", &difftest_port); break;
    // case 'l': log_file = optarg; break;
    case 'd': diff_so_file = optarg; break;
    case 'f':
      elf_file = optarg;
      break;
    case 1:
      img_file = optarg;
      break;
    default:
      printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
      printf("\t-b,--batch              run with batch mode\n");
      printf("\t-l,--log=FILE           output log to FILE\n");
      printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
      printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
      printf("\n");
      exit(0);
    }
  }
  return;
}

extern void cpu_update();
extern "C" void init_disasm(const char *triple);
int main(int argc, char* argv[])
{
  /*
  for(int i = 0; i<argc; i++)
  {
    printf("%s\n", argv[i]);
  }*/
  Verilated::commandArgs(argc, argv);
  sim_init();
  flash_init();
  args_init(argc, argv);
  long img_size = mem_init(img_file);
  sdb_init();
  init_disasm("riscv32-linux-pc-gnu");
#ifdef CONFIG_FTRACE
  init_ftrace(elf_file);
#endif

#ifdef CONFIG_DEVICE
  #ifdef CONFIG_VGA
  init_vga();
  #endif
  #ifdef CONFIG_KEYBOARD
  init_i8042();
  #endif
  extern void sdl_clear_event_queue();
  sdl_clear_event_queue();
#endif
  reset(10);
  cpu_update();
#ifdef CONFIG_DIFFTEST
  void init_difftest(char *ref_so_file, long img_size, int port);
  init_difftest(diff_so_file, img_size, 1234);
#endif
    //printf("here\n");
  //const char* args = nullptr;
  int result = run();
  /*#ifdef CONFIG_DIFFTEST
    printf("difftest success\n");
  #endif*/
  sim_close();
  extern int inst_num;
  printf("inst nums: %d\n", inst_num);
  assert(result != -1);
  return 0;
}



