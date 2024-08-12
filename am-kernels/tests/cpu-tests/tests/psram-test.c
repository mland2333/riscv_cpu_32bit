#include "trap.h"

int main() {
  /*for(int i = 0; i < 0x100; i++)
    *(char*)(0x80000000 + i) = i;

  for(int i = 0; i < 0x100; i++)
    check(*(char*)(0x80000000 + i) == i);*/

  for(int i = 0; i < 0x80000; i+=4)
    *(int*)(0x80000000 + i) = i;

  for(int i = 0; i < 0x80000; i+=4)
    check(*(int*)(0x80000000 + i) == i);

  return 0;
}
