#include "trap.h"

int main()
{
  char* spi = (char*)0x10001000;
  *(int*)spi = 0xf0;  //  rx/tx
  *(int*)0x10001014 = 2;  //divider
  *(int*)0x10001018 = 0x80; //ss
  int ctl = 0x2000 | 0x10 | 0x0800 | 0x600;
  *(int*)0x10001010 = ctl;   //ctrl: lsb=1 char_len=16
  *(int*)0x10001010 = ctl | 0x0100; //ctrl: go_bsy=1
  while((*(int*)0x10001010 | 0x0100) == 0x0100);
  int a = *(int*)spi;
  printf("%x\n", a);
  check(a == 0x10ff0);
  return 0;
}
