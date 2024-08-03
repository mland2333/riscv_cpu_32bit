#include "mem.h"
#include <cstdint>
#include <cstdio>
#include <cstdlib>

char* flash;
char* psram;

extern "C" void flash_read(uint32_t addr, uint32_t *data) {
  //printf("flash addr = %x\n", addr);
  *data = *(uint32_t*)flash_addr(addr);
}
extern "C" void mrom_read(uint32_t addr, uint32_t *data) { 
  *data = vmem_read(addr, 4); 
}

extern "C" int psram_read(uint32_t addr) { 
  uint32_t a = *(uint32_t*)psram_addr(addr);
  printf("psram_read, %x\n", a);
  return a;
}

extern "C" void psram_write(uint32_t addr, uint32_t data) { 
  *(uint32_t*)psram_addr(addr) = data;
  printf("psram_write, %x\n", data);
}

 long flash_init(char* img_file){
  flash = (char*)malloc(FLASH_SIZE);

  FILE *fp = fopen(img_file, "rb");

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  fseek(fp, 0, SEEK_SET);
  int ret = fread((void*)flash, size, 1, fp);
  fclose(fp);
  return size;
}

void psram_init(){
  psram = (char*)malloc(PSRAM_SIZE);
}

void* mem = nullptr;
inline uint64_t mem_read(void *addr, int len) {
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

inline void mem_write(void *addr, int len, uint64_t data) {
  #ifdef CONFIG_MTRACE
  //int result = (int)mem_read((void*)v_to_p(addr), len);
    printf("写入地址0x%x, 内容为0x%x, 写入后地址数据\n", addr, (int)data);
#endif
  //printf("mem 访问地址：%p\n", addr);
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
    uint64_t result = mem_read((void*)v_to_p(addr), len);
  #ifdef CONFIG_MTRACE
    printf("读取地址0x%x, 内容为0x%x\n", addr, (int)result);
#endif
    return result;
}

void vmem_write(uint32_t addr, int len, uint64_t data)
{
    //printf("vmem访问地址：0x%x\n", addr);
    mem_write((void*)v_to_p(addr), len, data);
  //#ifdef CONFIG_MTRACE
  //int result = (int)mem_read((void*)v_to_p(addr), len);
   // printf("写入地址0x%x, 内容为0x%x, 写入后地址数据为:0x%x\n", addr, (int)data, result);
//#endif
}

long mem_init(char* img_file) {
  if (img_file == NULL) {
    mem = malloc(sizeof(uint) * 5);
    mem_write((void *)((uint64_t)mem), 4, 0x00100513);
    mem_write((void *)((uint64_t)mem + 16), 4, 0x00100073);
    mem_write((void *)((uint64_t)mem + 12), 4, 0x00150513);
    mem_write((void *)((uint64_t)mem + 8), 4, 0x00150513);
    mem_write((void *)((uint64_t)mem + 4), 4, 0x00009117);
    printf("no img_file\n");
    return 20;
  }
  psram_init();
  long size = flash_init(img_file);
  mem = malloc(CONFIG_MSIZE);

  /* FILE *fp = fopen(img_file, "rb"); */
  /* // Assert(fp, "Can not open '%s'", img_file); */
  /**/
  /* fseek(fp, 0, SEEK_END); */
  /* long size = ftell(fp); */
  /* //mem = malloc(size); */
  /* // Log("The image is %s, size = %ld", img_file, size); */
  /**/
  /* fseek(fp, 0, SEEK_SET); */
  /* int ret = fread((void*)v_to_p(CONFIG_MBASE), size, 1, fp); */
  /* fclose(fp); */
  return size;
}





