/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include "isa-def.h"
#include "isa.h"
#include "local-include/reg.h"
#include <cpu/cpu.h>
#include <cpu/ifetch.h>
#include <cpu/decode.h>
#include <elf.h>

#ifdef CONFIG_FTRACE
    extern char* string_table;
    extern Elf32_Sym *func_table;
    extern int func_num;
    int name;
    int space_num = 0; 
    int f_call(uint32_t ptr)
    {
        for(int i = 0; i < func_num; i++)
        {
            if(ptr == func_table[i].st_value) //&& ptr < func_table[i].st_value + func_table[i].st_size)
                return func_table[i].st_name;
        }
        return -1;
    }
    int f_ret(uint32_t ptr)
    {
        for(int i = 0; i < func_num; i++)
        {
            if(ptr >= func_table[i].st_value && ptr < func_table[i].st_value + func_table[i].st_size)
                return func_table[i].st_name;
        }
        return -1;
    }

#endif
#define R(i) gpr(i)
#define Mr vaddr_read
#define Mw vaddr_write

enum {
  TYPE_I, TYPE_U, TYPE_S,TYPE_R,TYPE_J,TYPE_B,
  TYPE_N, // none
};

#define src1R() do { *src1 = R(rs1); } while (0)
#define src2R() do { *src2 = R(rs2); } while (0)
#define immI() do { *imm = SEXT(BITS(i, 31, 20), 12); } while(0)
#define immU() do { *imm = SEXT(BITS(i, 31, 12), 20) << 12; } while(0)
#define immS() do { *imm = (SEXT(BITS(i, 31, 25), 7) << 5) | BITS(i, 11, 7); } while(0)
#define immJ() do { *imm = SEXT((BITS(i,31,31)<<19|BITS(i,30,21)|BITS(i,20,20)<<10|BITS(i,19,12)<<11)<<1,21);}while(0)
#define immB() do { *imm = SEXT((BITS(i,31,31)<<11|BITS(i,30,25)<<4|BITS(i,11,8)|BITS(i,7,7)<<10)<<1,13);}while(0)
static void decode_operand(Decode *s, int *rd, word_t *src1, word_t *src2, word_t *imm, int type) {
  uint32_t i = s->isa.inst.val;
  int rs1 = BITS(i, 19, 15);
  int rs2 = BITS(i, 24, 20);
  *rd     = BITS(i, 11, 7);
  switch (type) {
    case TYPE_I: src1R();          immI(); break;
    case TYPE_U:                   immU(); break;
    case TYPE_S: src1R(); src2R(); immS(); break;
    case TYPE_R: src1R(); src2R();         break;
    case TYPE_J:                   immJ(); break;
    case TYPE_B: src1R(); src2R(); immB(); break;
  }
}

static int mul(int a,int b) {
	long long ans = (long long)a*(long long)b;
	return ans>>32;
}
static int mulu(uint32_t a,uint32_t b) {
	uint64_t ans = (uint64_t)a*(uint64_t)b;
	return ans>>32;
}
static int decode_exec(Decode *s) {
  int rd = 0;
  word_t src1 = 0, src2 = 0, imm = 0;
  s->dnpc = s->snpc;

#define INSTPAT_INST(s) ((s)->isa.inst.val)
#define INSTPAT_MATCH(s, name, type, ... /* execute body */ ) { \
  decode_operand(s, &rd, &src1, &src2, &imm, concat(TYPE_, type)); \
  __VA_ARGS__ ; \
}

  INSTPAT_START();
  INSTPAT("??????? ????? ????? ??? ????? 00101 11", auipc  , U, R(rd) = s->pc + imm);
  INSTPAT("??????? ????? ????? 100 ????? 00000 11", lbu    , I, R(rd) = Mr(src1 + imm, 1));
  INSTPAT("??????? ????? ????? 000 ????? 01000 11", sb     , S, Mw(src1 + imm, 1, src2));

  INSTPAT("0000000 00001 00000 000 00000 11100 11", ebreak , N, NEMUTRAP(s->pc, R(10))); // R(10) is $a0
  //dummy
  INSTPAT("??????? ????? 00000 000 ????? 00100 11", li     , I, R(rd) = imm);
  INSTPAT("??????? ????? ????? 000 ????? 00100 11", addi   , I, R(rd) = src1 + imm);
  INSTPAT("0000000 ????? ????? 000 ????? 01100 11", add    , R, R(rd) = src1 + src2);
  INSTPAT("??????? ????? ????? ??? ????? 11011 11", jal    , J, R(rd) = s->pc + 4; s->dnpc = s->pc + imm
#ifdef CONFIG_FTRACE
          ;
          if((name = f_call(s->dnpc)) != -1)
          {
              space_num++;
              printf("0x%x:", s->pc);
              for(int i = 0; i<space_num; i++)
                printf(" ");
              printf("call [%s@0x%x]\n", &string_table[name], s->dnpc);
          }
#endif
            );
  INSTPAT("??????? ????? ????? 010 ????? 01000 11", sw     , S, Mw(src1 + imm, 4, src2));
  INSTPAT("0000000 00000 00001 000 00000 11001 11", ret    , I, s->dnpc = src1
#ifdef CONFIG_FTRACE
          ;
          if((name = f_ret(s->dnpc)) != -1)
          {

            printf("0x%x:", s->pc);
            for(int i = 0; i<space_num; i++)
                printf(" ");
            space_num--;
            printf("ret  [%s@0x%x]\n", &string_table[name], s->dnpc);
          }
#endif
         );
  //add
  INSTPAT("??????? ????? ????? 010 ????? 00000 11", lw     , I, R(rd) = Mr(src1 + imm, 4));
  INSTPAT("0100000 ????? ????? 000 ????? 01100 11", sub    , R, R(rd) = src1 - src2);
  INSTPAT("0000000 00001 ????? 011 ????? 00100 11", seqz   , I, R(rd) = (src1 == 0));
  INSTPAT("??????? 00000 ????? 000 ????? 11000 11", beqz   , B, if(src1 == 0) s->dnpc = s->pc + imm);
  INSTPAT("??????? ????? ????? 001 ????? 11000 11", bne    , B, if(src1 != src2) s->dnpc = s->pc + imm);
  //add-longlong
  INSTPAT("0000000 ????? ????? 011 ????? 01100 11", sltu   , R, R(rd) = src1 < src2);
  INSTPAT("0000000 ????? ????? 100 ????? 01100 11", xor    , R, R(rd) = src1 ^ src2);
  INSTPAT("0000000 ????? ????? 110 ????? 01100 11", or     , R, R(rd) = src1 | src2);
  //bit
  INSTPAT("??????? ????? ????? 001 ????? 01000 11", sh     , S, Mw(src1 + imm, 2, src2));
  INSTPAT("0100000 ????? ????? 101 ????? 00100 11", srai   , I, R(rd) = (sword_t)src1 >> (imm & 0x1f));
  INSTPAT("??????? ????? ????? 111 ????? 00100 11", andi   , I, R(rd) = src1 & imm);
  INSTPAT("0000000 ????? ????? 001 ????? 01100 11", sll    , R, R(rd) = src1 << (src2&0x1f));
  INSTPAT("0000000 ????? ????? 111 ????? 01100 11", and    , R, R(rd) = src1 & src2);
  INSTPAT("??????? ????? ????? 100 ????? 00100 11", xori   , I, R(rd) = src1 ^ imm);
  //bubble-sort
  INSTPAT("??????? ????? ????? 101 ????? 11000 11", bge    , B, if((sword_t)src1 >= (sword_t)src2) s->dnpc = s->pc + imm);
  INSTPAT("??????? ????? ????? 100 ????? 11000 11", blt    , B, if((sword_t)src1 < (sword_t)src2) s->dnpc = s->pc + imm);
  //crc32
  INSTPAT("??????? ????? ????? ??? ????? 01101 11", lui    , U, R(rd) = imm);
  INSTPAT("000000? ????? ????? 101 ????? 00100 11", srli   , I, R(rd) = src1 >> (imm));
  INSTPAT("??????? ????? ????? 111 ????? 11000 11", bgeu   , B, if(src1 >= src2) s->dnpc = s->pc + imm);
  INSTPAT("0000000 ????? ????? 001 ????? 00100 11", slli   , I, R(rd) = src1 << (imm&0x1f));
  //div
  INSTPAT("0000001 ????? ????? 000 ????? 01100 11", mul    , R, R(rd) = (sword_t)src1 * (sword_t)src2);
  INSTPAT("0000001 ????? ????? 100 ????? 01100 11", div    , R, R(rd) = (sword_t)src1 / (sword_t)src2);
  //fact
  //fib
  //goldbach
  INSTPAT("??????? ????? ????? 000 ????? 11000 11", beq    , B, if(src1 == src2) s->dnpc = s->pc + imm);
  INSTPAT("0000001 ????? ????? 110 ????? 01100 11", rem    , R, R(rd) = (sword_t)src1 % (sword_t)src2);
  //load-store
  INSTPAT("??????? ????? ????? 001 ????? 00000 11", lh     , I, R(rd) = SEXT(Mr(src1 + imm, 2), 16));
  INSTPAT("??????? ????? ????? 101 ????? 00000 11", lhu    , I, R(rd) = Mr(src1 + imm, 2));
  //mersenne
  INSTPAT("0000001 ????? ????? 001 ????? 01100 11", mulh   , R, R(rd) = mul(src1, src2)); 
  INSTPAT("0000001 ????? ????? 111 ????? 01100 11", remu   , R, R(rd) = src1 % src2);
  INSTPAT("0000001 ????? ????? 101 ????? 01100 11", divu   , R, R(rd) = src1 / src2);
  //recursion
  INSTPAT("??????? ????? ????? 000 ????? 11001 11", jalr   , I, R(rd) = s->pc + 4; s->dnpc = (src1 + imm)&(~1)
          #ifdef CONFIG_FTRACE                                  
          ;
          if((name = f_call(s->dnpc)) != -1)
          {
              space_num++;
              printf("0x%x:", s->pc);
              for(int i = 0; i<space_num; i++)
                printf(" ");
              
              printf("call [%s@0x%x]\n", &string_table[name], s->dnpc);
          }
#endif
            );
  //shift
  INSTPAT("0100000 ????? ????? 101 ????? 01100 11", sra    , R, R(rd) = (sword_t)src1 >> (src2&0x1f));//???
  INSTPAT("0000000 ????? ????? 101 ????? 01100 11", srl    , R, R(rd) = src1 >> src2);
  //switch 
  INSTPAT("??????? ????? ????? 110 ????? 11000 11", bltu   , B, if(src1 < src2) s->dnpc = s->pc + imm);
  
  //INSTPAT("0000000 ????? ????? 111 ????? 01100 11", and    , R, R(rd) = src1 & src2);
  //INSTPAT("0000000 ????? ????? 001 ????? 01100 11", sll    , R, R(rd) = src1 << (src2&0x1f));
  INSTPAT("0000001 ????? ????? 011 ????? 01100 11", mulhu    , R, R(rd) = mulu(src1, src2));
  INSTPAT("??????? ????? ????? 000 ????? 00000 11", lb     , I, R(rd) = SEXT(BITS(Mr(src1 + imm, 1), 7,0),8) ); 
  INSTPAT("0000000 ????? ????? 010 ????? 01100 11", slt    , R, R(rd) = (sword_t)src1 < (sword_t)src2);
  INSTPAT("??????? ????? ????? 110 ????? 00100 11", ori    , I, R(rd) = src1 | imm);
  INSTPAT("??????? ????? ????? 011 ????? 00100 11", sltiu  , I, R(rd) = src1 < imm);
  //INSTPAT("??????? ????? ????? 000 ????? 00000 11", lb     , I, R(rd) = Mr(src1 + imm, 1));
  INSTPAT("??????? ????? ????? 010 ????? 00100 11", slti   , I, R(rd) = src1 < imm);

  INSTPAT("0011000 00010 00000 000 00000 11100 11", mret   , I, 
  #ifdef CONFIG_ETRACE
    printf("mret, pc = 0x%x, dnpc = 0x%x\n", s->pc, cpu.sr[MEPC] + 4);
  #endif
    //printf("mret, pc = 0x%x\n", s->pc);
    s->dnpc = cpu.sr[MEPC]); 
  INSTPAT("0000000 00000 00000 000 00000 11100 11", ecall  , I, 
  #ifdef CONFIG_ETRACE
    printf("ecall, pc = 0x%x\n", s->pc);
  #endif
    s->dnpc = isa_raise_intr(11, s->pc));
  INSTPAT("0000000 00001 00000 000 00000 11100 11", ebreak , I, );
  INSTPAT("??????? ????? ????? 001 00000 11100 11", csrw   , I, 
    switch(imm){
      case 0x300: cpu.sr[MSTATUS] = src1; break;
      case 0x305: cpu.sr[MTVEC] = src1; break;
      case 0x341: cpu.sr[MEPC] = src1; break;
      case 0x342: cpu.sr[MCAUSE] = src1; break;
  });
  INSTPAT("??????? ????? 00000 010 ????? 11100 11", csrr   , I, 
    switch(imm){
      case 0x300: R(rd) = cpu.sr[MSTATUS]; break;
      case 0x305: R(rd) = cpu.sr[MTVEC]; break;
      case 0x341: R(rd) = cpu.sr[MEPC]; break;
      case 0x342: R(rd) = cpu.sr[MCAUSE]; break;
  });
  
  INSTPAT("??????? ????? ????? ??? ????? ????? ??", inv    , N, INV(s->pc));
  INSTPAT_END();

  R(0) = 0; // reset $zero to 0

  return 0;
}

int isa_exec_once(Decode *s) {
  s->isa.inst.val = inst_fetch(&s->snpc, 4);
  return decode_exec(s);
}