#include "mem.h"
#include <cstdint>
#include <cstdio>
#include <cstdlib>

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

  FILE *fp = fopen(img_file, "rb");
  // Assert(fp, "Can not open '%s'", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);
  mem = malloc(size);
  // Log("The image is %s, size = %ld", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread((void*)v_to_p(BASE), size, 1, fp);
  fclose(fp);
  return size;
}


