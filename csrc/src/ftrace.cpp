#ifdef CONFIG_FTRACE

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <elf.h>
#include "ftrace.h"
char *string_table = NULL;
Elf32_Sym *func_table = NULL;
int func_num = 0;
int name;
int space_num = 0;
void init_ftrace(char* elf_file) {
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

void ftrace(uint32_t inst, uint32_t pc, uint32_t upc){
  if (inst == 0b00000000000000001000000001100111) {
    if ((name = f_ret(upc)) != -1) {

      printf("0x%x:", pc);
      for (int i = 0; i < space_num; i++)
        printf(" ");
      space_num--;
      printf("ret  [%s@0x%x]\n", &string_table[name], upc);
    }
  } else if ((inst & 0x7f) == 0x6f || (inst & 0x7f) == 0x67) {
    if ((name = f_call(upc)) != -1) {
      space_num++;
      printf("0x%x:", pc);
      for (int i = 0; i < space_num; i++)
        printf(" ");
      printf("call [%s@0x%x]\n", &string_table[name], upc);
    }
  }
}

#endif
