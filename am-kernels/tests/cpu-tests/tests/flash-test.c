#include "trap.h"
#define INST_NUMS 12
union Inst{
  int inst;
  unsigned char b[4];
};
typedef void (*func_ptr)();

#define UART_BASE 0x10000000L
#define UART_TX   0
void char_test() {
  *(volatile char *)(UART_BASE + UART_TX) = 'B';
  /**(volatile char *)(UART_BASE + UART_TX) = 'C';
  *(volatile char *)(UART_BASE + UART_TX) = 'C';
  *(volatile char *)(UART_BASE + UART_TX) = 'D';
  *(volatile char *)(UART_BASE + UART_TX) = 'E';*/
  //while (1);
}

int main()
{
  //int file_size = 28;
  int inst[INST_NUMS];
  union Inst minst;
  for(int i = 0; i < INST_NUMS; i++){
    *(int*)0x10001004 = 0x03000000 + 4 * i;  //  rx/tx
    *(int*)0x10001014 = 2;  //divider
    *(int*)0x10001018 = 0x01; //ss
    int ctl = 0x2000 | 0x40 | 0x000 | 0x00; //ASS, CHAR_LEN, LSB, Tx_NEG Rx_NEG
    *(int*)0x10001010 = ctl;   //ctrl: lsb=1 char_len=16
    *(int*)0x10001010 = ctl | 0x0100; //ctrl: go_bsy=1
    while(((*(int*)0x10001010) & 0x0100) == 0x0100);
    minst.inst = *(int*)0x10001000;
    inst[i] = (int)minst.b[0] << 24 | (int)minst.b[1] << 16 | (int)minst.b[2] << 8 | (int)minst.b[3];
    //printf("%x\n", inst[i]);
  }
  func_ptr func = (func_ptr)inst;
  //func();
  //char* spi = (char*)0x10001000;
  //char_test();
  func();
  //printf("%x\n", a);
  //check(a == 0x80);
  return 0;
}
