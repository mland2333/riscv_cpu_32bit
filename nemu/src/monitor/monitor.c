/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <stdio.h>
#include <isa.h>
#include <memory/paddr.h>
#include <elf.h>
void init_rand();
void init_log(const char *log_file);
void init_mem();
void init_difftest(char *ref_so_file, long img_size, int port);
void init_device();
void init_sdb();
void init_disasm(const char *triple);

static void welcome() {
  Log("Trace: %s", MUXDEF(CONFIG_TRACE, ANSI_FMT("ON", ANSI_FG_GREEN), ANSI_FMT("OFF", ANSI_FG_RED)));
  IFDEF(CONFIG_TRACE, Log("If trace is enabled, a log file will be generated "
        "to record the trace. This may lead to a large log file. "
        "If it is not necessary, you can disable it in menuconfig"));
  Log("Build time: %s, %s", __TIME__, __DATE__);
  printf("Welcome to %s-NEMU!\n", ANSI_FMT(str(__GUEST_ISA__), ANSI_FG_YELLOW ANSI_BG_RED));
  printf("For help, type \"help\"\n");
  //Log("Exercise: Please remove me in the source code and compile NEMU again.");
  //assert(0);
}

#ifndef CONFIG_TARGET_AM
#include <getopt.h>

void sdb_set_batch_mode();

static char *log_file = NULL;
static char *diff_so_file = NULL;
static char *img_file = NULL;
static int difftest_port = 1234;
static char *elf_file = NULL;

static long load_img() {
  if (img_file == NULL) {
    Log("No image is given. Use the default build-in image.");
    return 4096; // built-in image size
  }
  FILE *fp = fopen(img_file, "rb");
  Assert(fp, "Can not open '%s'", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  Log("The image is %s, size = %ld", img_file, size);

  fseek(fp, 0, SEEK_SET);
  #if defined(CONFIG_TARGET_SHARE) || defined(CONFIG_CACHESIM)
    extern uint8_t flash[];
    int ret = fread(flash, size, 1, fp);
  #else
    int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
  #endif
  //guest_to_host(RESET_VECTOR)
  assert(ret == 1);

  fclose(fp);
  return size;
}

static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"batch"    , no_argument      , NULL, 'b'},
    {"log"      , required_argument, NULL, 'l'},
    {"diff"     , required_argument, NULL, 'd'},
    {"port"     , required_argument, NULL, 'p'},
    {"help"     , no_argument      , NULL, 'h'},
    {"file"     , required_argument, NULL, 'f'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhl:d:p:f:", table, NULL)) != -1) {
    switch (o) {
      case 'b': sdb_set_batch_mode(); break;
      case 'p': sscanf(optarg, "%d", &difftest_port); break;
      case 'l': log_file = optarg; break;
      case 'd': diff_so_file = optarg; break;
      case 'f': elf_file = optarg; break;
      case 1: img_file = optarg; printf("img_file=%s\n", img_file); return 0;
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
  return 0;
}
#ifdef CONFIG_FTRACE

char *string_table = NULL;
Elf32_Sym *func_table = NULL;
int func_num = 0;

void init_ftrace() {
  FILE *file;
  Elf32_Ehdr elf_header;              // ELF 文件头
  Elf32_Shdr *section_headers = NULL; // 节头表
  Elf32_Sym *symbol_table = NULL;     // 符号表
  // char *string_table = NULL;          // 字符串表
  size_t i;

  // 打开 ELF 文件
  printf("%s\n", elf_file);
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
    }
  }
  
  // 释放内存并关闭文件
  free(section_headers);
  free(symbol_table);
  // free(string_table);
  fclose(file);
}
#endif
void init_monitor(int argc, char *argv[]) {
  /* Perform some global initialization. */
  
  /* Parse arguments. */
  parse_args(argc, argv);

  /* Set random seed. */
  init_rand();

  /* Open the log file. */
  init_log(log_file);

  /* Initialize memory. */
  init_mem();

  /* Initialize devices. */
  IFDEF(CONFIG_DEVICE, init_device());

  /* Perform ISA dependent initialization. */
  init_isa();

  /* Load the image to memory. This will overwrite the built-in image. */
  long img_size = load_img();
  cpu.sr[MSTATUS] = 0x1800; 
  /* Initialize differential testing. */
  init_difftest(diff_so_file, img_size, difftest_port);
#ifdef CONFIG_ITRACE
  extern void init_itrace(char*);
  init_itrace(img_file);
#endif
  /* Initialize the simple debugger. */
  init_sdb();
#ifdef CONFIG_FTRACE
  init_ftrace();
#endif
#ifndef CONFIG_ISA_loongarch32r
  IFDEF(CONFIG_ITRACE, init_disasm(
    MUXDEF(CONFIG_ISA_x86,     "i686",
    MUXDEF(CONFIG_ISA_mips32,  "mipsel",
    MUXDEF(CONFIG_ISA_riscv,
      MUXDEF(CONFIG_RV64,      "riscv64",
                               "riscv32"),
                               "bad"))) "-pc-linux-gnu"
  ));
#endif

  /* Display welcome message. */
  welcome();
}
#else // CONFIG_TARGET_AM
static long load_img() {
  extern char bin_start, bin_end;
  size_t size = &bin_end - &bin_start;
  Log("img size = %ld", size);
  memcpy(guest_to_host(RESET_VECTOR), &bin_start, size);
  return size;
}

void am_init_monitor() {
  init_rand();
  init_mem();
  init_isa();
  load_img();
  cpu.sr[MSTATUS] = 0x1800;
  IFDEF(CONFIG_DEVICE, init_device());
  welcome();
}
#endif
