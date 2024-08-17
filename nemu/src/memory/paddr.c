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

#include <memory/host.h>
#include <memory/paddr.h>
#include <device/mmio.h>
#include <isa.h>

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#endif

static uint8_t mrom[MROM_SIZE] PG_ALIGN = {};
static uint8_t sram[SRAM_SIZE] PG_ALIGN = {};
uint8_t flash[FLASH_SIZE] PG_ALIGN = {};
static uint8_t sdram[SDRAM_SIZE] PG_ALIGN = {};
static uint8_t psram[PSRAM_SIZE] PG_ALIGN = {};

uint8_t* mrom_guest_to_host(paddr_t paddr) { return mrom + paddr - MROM_RADDR; }
paddr_t mrom_host_to_guest(uint8_t *haddr) { return haddr - mrom + MROM_RADDR; }

uint8_t* sram_guest_to_host(paddr_t paddr) { return sram + paddr - SRAM_RADDR; }
paddr_t sram_host_to_guest(uint8_t *haddr) { return haddr - sram + SRAM_RADDR; }

uint8_t* flash_guest_to_host(paddr_t paddr) { return flash + paddr - FLASH_RADDR; }
paddr_t flash_host_to_guest(uint8_t *haddr) { return haddr - flash + FLASH_RADDR; }

uint8_t* sdram_guest_to_host(paddr_t paddr) { return sdram + paddr - SDRAM_RADDR; }
paddr_t sdram_host_to_guest(uint8_t *haddr) { return haddr - sdram + SDRAM_RADDR; }

uint8_t* psram_guest_to_host(paddr_t paddr) { return psram + paddr - PSRAM_RADDR; }
paddr_t psram_host_to_guest(uint8_t *haddr) { return haddr - psram + PSRAM_RADDR; }

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

word_t mrom_read(paddr_t addr, int len){
  #ifdef CONFIG_MTRACE
    printf("mrom_read , address: 0x%x, len: %d\n", addr, len);
  #endif
  word_t ret = host_read(mrom_guest_to_host(addr), len);
  return ret;
}
void mrom_write(paddr_t addr, int len, word_t data) {
  #ifdef CONFIG_MTRACE
    printf("mrom_write, address: 0x%x, len: %d\n", addr, len);
  #endif
  host_write(mrom_guest_to_host(addr), len, data);
}

word_t sram_read(paddr_t addr, int len){
  #ifdef CONFIG_MTRACE
    printf("sram_read , address: 0x%x, len: %d\n", addr, len);
  #endif
  word_t ret = host_read(sram_guest_to_host(addr), len);
  return ret;
}
void sram_write(paddr_t addr, int len, word_t data) {
  #ifdef CONFIG_MTRACE
    printf("sram_write, address: 0x%x, len: %d\n", addr, len);
  #endif
  host_write(sram_guest_to_host(addr), len, data);
}

word_t flash_read(paddr_t addr, int len){
  #ifdef CONFIG_MTRACE
    printf("flash_read , address: 0x%x, len: %d\n", addr, len);
  #endif
  word_t ret = host_read(flash_guest_to_host(addr), len);
  return ret;
}
void flash_write(paddr_t addr, int len, word_t data) {
  #ifdef CONFIG_MTRACE
    printf("flash_write, address: 0x%x, len: %d\n", addr, len);
  #endif
  host_write(flash_guest_to_host(addr), len, data);
}

word_t sdram_read(paddr_t addr, int len){
  #ifdef CONFIG_MTRACE
    printf("sdram_read , address: 0x%x, len: %d\n", addr, len);
  #endif
  word_t ret = host_read(sdram_guest_to_host(addr), len);
  return ret;
}
void sdram_write(paddr_t addr, int len, word_t data) {
  #ifdef CONFIG_MTRACE
    printf("sdram_write, address: 0x%x, len: %d\n", addr, len);
  #endif
  host_write(sdram_guest_to_host(addr), len, data);
}

word_t psram_read(paddr_t addr, int len){
  #ifdef CONFIG_MTRACE
    printf("psram_read , address: 0x%x, len: %d\n", addr, len);
  #endif
  word_t ret = host_read(psram_guest_to_host(addr), len);
  return ret;
}
void psram_write(paddr_t addr, int len, word_t data) {
  #ifdef CONFIG_MTRACE
    printf("psram_write, address: 0x%x, len: %d\n", addr, len);
  #endif
  host_write(psram_guest_to_host(addr), len, data);
}


static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  #ifdef CONFIG_MTRACE
    printf("pmem_read , address: 0x%x, len: %d, data:0x%x\n", addr, len, ret);
  #endif
  /* if(addr == 0x80020ebc) printf("read data = 0x%x", ret); */
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  #ifdef CONFIG_MTRACE
    printf("pmem_write, address: 0x%x, len: %d, data:0x%x\n", addr, len, data);
  #endif
  host_write(guest_to_host(addr), len, data);
  /* if(addr == 0x80020ebc) printf("write data = 0x%x", data); */
}

static void out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

void init_mem() {
#if   defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(CONFIG_MSIZE);
  assert(pmem);
#endif
  IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), CONFIG_MSIZE));
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
}

word_t paddr_read(paddr_t addr, int len) {
  if(in_pmem(addr)) return pmem_read(addr, len);
#if defined(CONFIG_TARGET_SHARE) || defined(CONFIG_CACHESIM)
  else if(in_mrom(addr)) return mrom_read(addr, len);
  else if(in_sram(addr)) return sram_read(addr, len);
  else if(in_flash(addr)) return flash_read(addr, len);
  else if(in_sdram(addr)) return sdram_read(addr, len);
  else if(in_psram(addr)) return psram_read(addr, len);
#endif
  IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  if (in_pmem(addr)) { pmem_write(addr, len, data); return; }
#if defined(CONFIG_TARGET_SHARE) || defined(CONFIG_CACHESIM)
  else if (in_sram(addr)) { sram_write(addr, len, data); return; }
  else if (in_sdram(addr)){ sdram_write(addr, len, data); return;}
  else if (in_psram(addr)){ psram_write(addr, len, data); return;}
  printf("here\n");
#endif
  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
  out_of_bound(addr);
}
