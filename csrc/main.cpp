#include <cstdlib>
#include <getopt.h>
#include <stdio.h>
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
    sdb_init();
    init_disasm("riscv32-linux-pc-gnu");
  #ifdef CONFIG_FTRACE
    init_ftrace(elf_file);
    
  #endif
  
  reset(2);
  cpu_update();
  #ifdef CONFIG_DIFFTEST
    void init_difftest(char *ref_so_file, long img_size, int port);
    init_difftest(diff_so_file, img_size, 1234);
  #endif
  run();
  #ifdef CONFIG_DIFFTEST
    printf("difftest success\n");
  #endif
  sim_close();
    return 0;
}



