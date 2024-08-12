.section entry, "ax"
.globl _start
.type _start, @function


_start:
  mv s0, zero
  la sp, _stack_pointer
  la a0, _text_load_start
  la a1, _text_start
  la a2, _bss_end
bootloader:
  bgeu a1, a2, jump2main
  lw a3, 0(a0)
  sw a3, 0(a1)
  addi a0, a0, 0x4
  addi a1, a1, 0x4
  j bootloader
jump2main:
  la a0, _trm_init
  jalr x0, 0(a0)
