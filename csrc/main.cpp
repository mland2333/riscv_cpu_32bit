#include "verilated_vcd_c.h"
#include "Vtop.h"
#include "Vtop___024root.h"
#include <cstdlib>
#include <cstring>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <unordered_map>
#include <iostream>
#include <cstring>
#include <elf.h>
#define BASE 0x80000000
#define v_to_p(addr) (((uint64_t)addr - (uint64_t)BASE) + (uint64_t)mem) 
std::unordered_map<std::string, std::function<int(char*)>> sdb_map;

#ifdef CONFIG_ITRACE
char inst_buf[128] = {};
extern "C" void disassemble(char *str, int size, uint64_t pc, uint8_t *code,
                            int nbyte);
#endif

VerilatedContext* contextp = NULL;
VerilatedVcdC* tfp = NULL;
Vtop* top = NULL;
void* mem = NULL;

static char *img_file = NULL;
static char *elf_file = NULL;
void sim_init()
{
    contextp = new VerilatedContext;
    tfp = new VerilatedVcdC;
    top = new Vtop;
    contextp->traceEverOn(true);
    top->trace(tfp, 0);
    tfp->open("dump.vcd");
}

static inline uint64_t mem_read(void *addr, int len) {
  switch (len) {
  case 1:
    return *(uint8_t *)addr;
  case 2:
    return *(uint16_t *)addr;
  case 4:
    return *(uint32_t *)addr;
  case 8:
    return *(uint64_t *)addr;
  default:
    return 0;
  }
}

static inline void mem_write(void *addr, int len, uint64_t data) {
  switch (len) {
  case 1:
    *(uint8_t *)addr = data;
    return;
  case 2:
    *(uint16_t *)addr = data;
    return;
  case 4:
    *(uint32_t *)addr = data;
    return;
  case 8:
    *(uint64_t *)addr = data;
    return;
  default:
    return;
  }
}

uint64_t vmem_read(uint32_t addr, int len)
{
    return mem_read((void*)v_to_p(addr), len);
}

void mem_init() {
  if (img_file == NULL) {
    mem = malloc(sizeof(uint) * 5);
    mem_write((void *)((uint64_t)mem), 4, 0x00100513);
    mem_write((void *)((uint64_t)mem + 4), 4, 0x00009117);
    mem_write((void *)((uint64_t)mem + 8), 4, 0x00150513);
    mem_write((void *)((uint64_t)mem + 12), 4, 0x00150513);
    mem_write((void *)((uint64_t)mem + 16), 4, 0x00100073);
    printf("Notice: no img_file, use default mem\n");
    return;
  }

  FILE *fp = fopen(img_file, "rb");
  // Assert(fp, "Can not open '%s'", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);
  mem = malloc(size);
  // Log("The image is %s, size = %ld", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread((void*)v_to_p(BASE), size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  // return size;
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
    // case 'd': diff_so_file = optarg; break;
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
  /*if(argc > 1)
      img_file = argv[1];*/
}
void sim_close()
{
    top->final();
    delete top;
    delete tfp;
    delete contextp;
}
void step_and_dump_wave() {
  top->eval();
  contextp->timeInc(1);
  tfp->dump(contextp->time());
}
void single_cycle() {
  top->clk = 0; step_and_dump_wave();
  top->clk = 1; step_and_dump_wave();
}

void reset(int n) {
  top->rst = 1;
  while (n -- > 0) single_cycle();
  top->rst = 0;
}

#ifdef CONFIG_FTRACE

char *string_table = NULL;
Elf32_Sym *func_table = NULL;
int func_num = 0;
int name;
int space_num = 0;
void init_ftrace() {
  FILE *file;
  Elf32_Ehdr elf_header;              // ELF 文件头
  Elf32_Shdr *section_headers = NULL; // 节头表
  Elf32_Sym *symbol_table = NULL;     // 符号表
  // char *string_table = NULL;          // 字符串表
  size_t i;

  // 打开 ELF 文件
  //printf("%s\n", elf_file);
  file = fopen(elf_file, "r");
  if (file == NULL) {
    perror("文件打开失败");
    return;
  }

  // 读取 ELF 文件头
  fread(&elf_header, sizeof(Elf32_Ehdr), 1, file);

  // 定位到节头表
  fseek(file, elf_header.e_shoff, SEEK_SET);

  // 读取节头表
  section_headers =
      (Elf32_Shdr *)malloc(elf_header.e_shentsize * elf_header.e_shnum);
  fread(section_headers, elf_header.e_shentsize, elf_header.e_shnum, file);

  // 查找符号表和字符串表
  Elf32_Shdr *symtab_hdr = NULL;
  // symtab_hdr = &section_headers[18];
  Elf32_Shdr *strtab_hdr = NULL;
  // strtab_hdr = &section_headers[19];

  for (i = 0; i < elf_header.e_shnum; i++) {
    if (section_headers[i].sh_type == SHT_SYMTAB) {
      symtab_hdr = &section_headers[i];
    } else if (section_headers[i].sh_type == SHT_STRTAB) {
      strtab_hdr = &section_headers[i];
      break;
    }
  }

  if (symtab_hdr == NULL || strtab_hdr == NULL) {
    fprintf(stderr, "未找到符号表或字符串表\n");
    return;
  }

  fseek(file, strtab_hdr->sh_offset, SEEK_SET);
  string_table = (char *)malloc(strtab_hdr->sh_size);
  fread(string_table, 1, strtab_hdr->sh_size, file);
  // 定位到符号表
  fseek(file, symtab_hdr->sh_offset, SEEK_SET);
  symbol_table = (Elf32_Sym *)malloc(symtab_hdr->sh_size);
  fread(symbol_table, symtab_hdr->sh_size, 1, file);

  func_table = (Elf32_Sym *)malloc(symtab_hdr->sh_size);
  for (i = 0; i < (symtab_hdr->sh_size / sizeof(Elf32_Sym)); i++) {
    if (ELF32_ST_TYPE(symbol_table[i].st_info) == STT_FUNC) {
      memcpy(&func_table[func_num++], &symbol_table[i], sizeof(Elf32_Sym));
      char *symbol_name = string_table + symbol_table[i].st_name;
      printf("i = %u, 函数名称：%s, 地址：%x\n", i, symbol_name,
      (unsigned)symbol_table[i].st_value);
    }
  }
  for(i = 0; i < func_num; i++)
  {
      char *symbol_name = &string_table[func_table[i].st_name];
      printf("i = %u, 函数名称：%s, 地址：%x\n", i, symbol_name,
             (unsigned)func_table[i].st_value);
  }
  // 释放内存并关闭文件
  free(section_headers);
  free(symbol_table);
  // free(string_table);
  fclose(file);
}

int f_call(uint32_t ptr) {
  for (int i = 0; i < func_num; i++) {
    if (ptr == func_table[i].st_value) //&& ptr < func_table[i].st_value +
                                       // func_table[i].st_size)
      return func_table[i].st_name;
  }
  return -1;
}
int f_ret(uint32_t ptr) {
  for (int i = 0; i < func_num; i++) {
    if (ptr >= func_table[i].st_value &&
        ptr < func_table[i].st_value + func_table[i].st_size)
      return func_table[i].st_name;
  }
  return -1;
}
#endif


int exec_once(){
  uint32_t pc = top->pc;              
  uint32_t inst = vmem_read(pc, 4);
  top->inst = inst;
  single_cycle();
#ifdef CONFIG_ITRACE
  disassemble(inst_buf, 128, (uint64_t)pc, (uint8_t *)(&inst), 4);
  //printf("%08x\n", inst);
  printf("0x%x\t0x%08x\t%s\t\n", pc, inst, inst_buf);
#endif
#ifdef CONFIG_FTRACE
  if (inst == 0b00000000000000001000000001100111) {
    if ((name = f_ret(top->pc)) != -1) {

      printf("0x%x:", pc);
      for (int i = 0; i < space_num; i++)
        printf(" ");
      space_num--;
      printf("ret  [%s@0x%x]\n", &string_table[name], top->pc);
    }
  } else if ((inst & 0x7f) == 0x6f || (inst & 0x7f) == 0x67) {
    if ((name = f_call(top->pc)) != -1) {
      space_num++;
      printf("0x%x:", pc);
      for (int i = 0; i < space_num; i++)
        printf(" ");
      printf("call [%s@0x%x]\n", &string_table[name], top->pc);
    }
  }
#endif
  
  return top->exit;
}
int cmd_c(char* args) {
  while (1) {
    if (exec_once() == 1)
      return 1;
  }
}
int cmd_si(char* args) {
  if(args == nullptr){
    if (exec_once() == 1)
      return 1;
  }else{
    char *num = strtok(args, " ");
    int n = atoi(num);
    for (int i =0; i<n; i++) {
      if(exec_once() == 1)
        return 1;
    }
  }
  return 0;
}
int cmd_info(char* args) {
  for (int i = 0; i < 32; i++) {
    printf("x[%d] = 0x%x ", i, (top->rootp->top__DOT__mreg__DOT__rf)[i]);
    //std::cout << std::format("x{} = 0x{:x} ", i,
                             //top->rootp->top__DOT__register__DOT__rf[i]);
  }
  std::cout << '\n';
  return 0;
}
int cmd_q(char* args) { return 1; }
int cmd_x(char* args){
  if(args == nullptr) 
  {
    printf("请输入打印地址\n");
    return 0;
  }
  char* endptr;
  uint32_t addr = strtol(strtok(args, " "), &endptr, 0);
  printf("0x%08x\n", (uint32_t)vmem_read(addr, 4));
  return 0;
}



void sdb_init(){
  sdb_map["si"] = cmd_si;
  sdb_map["c"] = cmd_c;
  sdb_map["info"] = cmd_info;
  sdb_map["q"] = cmd_q;
  sdb_map["x"] = cmd_x;
}
extern "C" void init_disasm(const char *triple);
int main(int argc, char* argv[])
{
    //printf("here\n");
    sim_init();
    args_init(argc, argv);
    mem_init();
    sdb_init();
    init_disasm("riscv32-linux-pc-gnu");
  #ifdef CONFIG_FTRACE
    init_ftrace();
    printf("here\n");
  #endif
    reset(2);
    //printf("here\n");
  //const char* args = nullptr;
  char args[32];
  char* cmd;
  char* strend;
  std::string line;
  std::cout << "<< ";
    while (getline(std::cin, line)) {
      strcpy(args, line.c_str());
      strend = args + strlen(args);
      cmd = strtok(args, " ");
      char *sdb_args= cmd + strlen(cmd) + 1;
      if(sdb_args >= strend) sdb_args = nullptr;
      if (sdb_map[cmd](sdb_args) == 1)
        break;
      std::cout << "<< ";
    }
    sim_close();
    return 0;
}



