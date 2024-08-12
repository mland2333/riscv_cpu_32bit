#include "trap.h"



void mem_write(unsigned int addr, unsigned int len_mask){
  switch(len_mask){
    case 8:
      for(int i = 0; i<1000; i++)
      {
        *(((char*) addr) + i) = (char) ((addr + i)& 0xff);
      }
      break;
    case 16:
      for(int i = 0; i<500; i++)
      {
        *(((unsigned short*) addr) + i) = (unsigned short)((addr+i*2) & 0xffff);
      }
      break;
    case 32:
      for(int i = 0; i<250; i++)
      {
        *((unsigned int*)addr + i) = addr + 4*i;
      }
      break;
  }
}

int main()
{
  unsigned int *mem = (unsigned int*)0xc0000000;
  char* cmem = (char*) mem;
    mem_write((unsigned int)(cmem), 8);
  for(int i = 0; i<1000; i++, cmem++)
  {
    check(*cmem == (char) ((int)cmem & 0xff));
  }

  unsigned short* smem = (unsigned short*) mem;
    mem_write((unsigned int)(smem), 16);
  for(int i = 0; i<500; i++, smem++)
  {
    check(*smem == (unsigned short) ((int)smem & 0xffff));
  }

  unsigned int* umem = mem;
    mem_write((unsigned int)(umem), 32);
  for(int i = 0; i<250; i++, umem++)
  {
    check(*umem == (unsigned int)umem);
  }
  /**mem = 1;
  *(mem + 1) = 2;
  int a = *mem;
  int b = *(mem + 1);
  check(a == 1);
  check(b == 2);*/

}
