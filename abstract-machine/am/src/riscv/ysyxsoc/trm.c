#include <am.h>
#include <klib.h>
#include <ysyxsoc.h>

extern char _text_load_start[];
extern char _text_start[];

extern char _data_start [];
extern char _data_end[];
extern char _data_load_start [];
extern char _bss_start[];
extern char _bss_end[];
extern char _heap_start[];
int main(const char *args);

extern char _stack_top[];
//#define PMEM_SIZE (128 * 1024 * 1024)
//#define PMEM_END  ((uintptr_t)&_rom_start + PMEM_SIZE)

Area heap = RANGE(_heap_start, _stack_top);
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

//static inline void outb(uintptr_t addr, uint8_t  data) { *(volatile uint8_t  *)addr = data; }
void putch(char ch) {
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0);
  WriteReg(THR, ch);
}

char getch() {
  if(ReadReg(LSR) & 0x01){
    // input data is ready.
    char a = ReadReg(RBR);
    putch(a);
    return a;
  } else {
    return 0xff;
  }
}
void halt(int code) {
  asm volatile("mv a0, %0; ebreak" : :"r"(code));
  __builtin_unreachable();
}

void load_data(){
  char* src = _data_load_start;
  char* dst = _data_start;
  //printf("%x, %x\n", (int)_data_end , (int)dst);
  while(dst != _data_end){
    *dst = *src;
    src++;
    dst++;
  }
}

/*void bootloader(){
  is_boot = 0;
  char* src = _text_load_start;
  char* dst = _text_start;
  //printf("%x, %x\n", (int)_data_end , (int)dst);
  while(dst != _data_end){
    *dst = *src;
    src++;
    dst++;
  }
}*/

void clear_bss(){
  char* src = _bss_start;
  char* end = _bss_end;
  while(src != end){
    *src = 0;
    src++;
  }
}

void uart_init()
{
    /*To set registers DLL and DLM, we need to set LCR's bit7 to 1*/
    //printf("%x\n", ReadReg(3));
    //char lcr = ReadReg(3);
    WriteReg(3, (1 << 7));
    /* Set baud rate. Here we set value to 3, which means 38.4K when 1.8432 MHZ crystal.
       We respectively set registers DLL(low) and DLM(high) because the divisor register is 16 bits.
    This step is necessary.
    */
    //printf("%x\n", ReadReg(0)); 
    WriteReg(DLL, 0x01);
    WriteReg(DLM, 0x00);
    //printf("%x\n", ReadReg(DLM));

    //lcr = 0;
    WriteReg(LCR, (3 << 0));
}

void _trm_init() {
  //load_data();
  //bootloader();
  uart_init();
  extern void init_keymap();
  init_keymap();
  printf("%x, %x\n", (int)_heap_start, (int)_stack_top);
  /* while(true){ */
    /* char a = getch(); */
    /* if(a == 'a') */
      /* break; */
  /* } */
  //clear_bss();
  //printf("%x\n", (((unsigned int)_bss_start)));
  //printf("%x\n", *(((unsigned int*)(_data_load_start - 7))));
  //halt(0);
  int ret = main(mainargs);
  halt(ret);
}
