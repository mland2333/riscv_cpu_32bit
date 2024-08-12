#include "trap.h"

#define SDRAM_BASE 0xa0000000

int main() {
  /* char a[4]; */
  /* a[0] = 0x78; */
  /* a[1] = 0x56; */
  /* a[2] = 0x34; */
  /* a[3] = 0x12; */
  /* short b[2]; */
  /* b[0] = 0x5678; */
  /* b[1] = 0x1234; */
  /* for(int i = 0x000; i < 0x400; i+=4) */
  /*   *(int*)(SDRAM_BASE + i) = i; */
  /**/
  /**/
  /* for(int i = 0x000; i < 0x400; i+=4) */
  /*   check(*(int*)(SDRAM_BASE + i) == i); */
  /* for (int j = 1; j < 128; j++) { */
    for (int i = 0x4000000; i < 0x4002000; i += 4)
      *(int *)(SDRAM_BASE + i) = i;

    for (int i = 0x4000000; i < 0x4002000; i += 4)
      check(*(int *)(SDRAM_BASE + i) == i);
  /* } */

  /* *(int*)(SDRAM_BASE + 0x400) = 0x400; */
  /* check(*(int*)(SDRAM_BASE + 0x400) == 0x400); */

  /* *(int*)0xa0000400 = 0x11223344; */
  /* check(*(int*)0xa0000400 == 0x11223344); */

  /* *(char*)0xa0000000 = 0x00; */
  /* printf("a = %x\n", *(short*)0xa0000000);  */
  /* *(char*)0xa0000003 = 0x03; */
  /* printf("a = %x\n", *(short*)0xa0000002); */
  /* *(char*)0xa0000002 = 0x02; */
  /* printf("a = %x\n", *(short*)0xa0000002); */
  /* *(char*)0xa0000001 = 0x01;  */
  /**/
  /* int a = *(short*)0xa0000000; */
  /* printf("a = %x\n", a); */
  /* check(a == 0x0100); */
  /* *(int*)0xa0000698 = 0x11223344; */
  /* *(int*)0xa0001000 = 0; */
  /* *(int*)0xa00001b0 = 0x55667788; */
  /* *(int*)0xa0010000 = 0; */
  /* check(*(int*)0xa0000698 == 0x11223344); */
  /* check(*(int*)0xa00001b0 == 0x55667788); */
  return 0;
}
