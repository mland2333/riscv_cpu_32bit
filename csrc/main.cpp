#include <cstdlib>
#include <getopt.h>
#include <stdio.h>
#include <assert.h>
#include "sdb.h"
#include "mem.h"
#include "ftrace.h"
#ifdef CONFIG_DIFFTEST

#endif

static char *img_file = NULL;
static char *elf_file = NULL;
static char *diff_so_file = NULL;

extern "C" int pmem_read(int raddr) {
  // 总是读取地址为`raddr & ~0x3u`的4字节返回
  return (int)vmem_read(raddr, 4);
}
extern "C" void pmem_write(int waddr, int wdata, char wmask) {
  //vmem_write(waddr, 4, wdata);
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
    // case 'b': sdb_set_batch_mode(); break;
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
    //printf("here\n");
    sim_init();
    args_init(argc, argv);
    long img_size = mem_init(img_file);
    printf("%lx\n", img_size);
    sdb_init();
    init_disasm("riscv32-linux-pc-gnu");
  #ifdef CONFIG_FTRACE
    init_ftrace(elf_file);
    
  #endif
  
  reset(2);
  printf("here\n");
  cpu_update();
  #ifdef CONFIG_DIFFTEST
    void init_difftest(char *ref_so_file, long img_size, int port);
    init_difftest(diff_so_file, img_size, 1234);
  #endif
    //printf("here\n");
  //const char* args = nullptr;
  printf("here\n");
  int result = run();
  /*#ifdef CONFIG_DIFFTEST
    printf("difftest success\n");
  #endif*/
  sim_close();
  assert(result != -1);
  return 0;
}



