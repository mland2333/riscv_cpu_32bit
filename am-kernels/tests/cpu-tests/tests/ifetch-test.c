#include "trap.h"
typedef void (*func_ptr)();
int main()
{
  //char* spi = (char*)0x10001000;
  /**(int*)0x10001004 = 0x03000000;  //  rx/tx
  *(int*)0x10001014 = 2;  //divider
  *(int*)0x10001018 = 0x01; //ss
  int ctl = 0x2000 | 0x40 | 0x000 | 0x00; //ASS, CHAR_LEN, LSB, Tx_NEG Rx_NEG
  *(int*)0x10001010 = ctl;   //ctrl: lsb=1 char_len=16
  *(int*)0x10001010 = ctl | 0x0100; //ctrl: go_bsy=1
  while(((*(int*)0x10001010) & 0x0100) == 0x0100);
  int a = *(int*)0x10001000;
  printf("%x\n", a);
  check(a == 0x80);*/
  /*int a = *(int*)0x30000000;
  int b = *(int*)0x30000004;
  int c = *(int*)0x3000000c;
  printf("%x\n%x\n%x\n", a, b, c);*/
  func_ptr func = (func_ptr)0x30000000;
  func();
  return 0;
}
