#include "sdb.h"
#include <cstdlib>
#ifdef CONFIG_YSYXSOC
#include "VysyxSoCFull.h"
#include "VysyxSoCFull___024root.h"
#else
#include "Vysyx_20020207.h"
#include "Vysyx_20020207___024root.h"
#endif
#include "cpu.h"
#include "device.h"
#include "mem.h"
#include <cstdint>
#include <format>
#include <functional>
#include <getopt.h>
#include <iostream>
#include <unordered_map>
#ifdef CONFIG_FTRACE
#include "ftrace.h"
#endif

#ifdef CONFIG_NVBOARD
#include <nvboard.h>
void nvboard_bind_all_pins(TOP_NAME *top);
#endif

#ifdef CONFIG_GTKTRACE
#include "verilated_vcd_c.h"
VerilatedContext *contextp = NULL;
VerilatedVcdC *tfp = NULL;
int trace_enable = 0;
#endif

#ifdef CONFIG_ITRACE
char inst_buf[128] = {};
extern "C" void disassemble(char *str, int size, uint64_t pc, uint8_t *code,
                            int nbyte);
#endif

#ifdef CONFIG_YSYXSOC
#define TOP_PREFIX top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__
#define PC_BEGIN 0xa0000000
#else
#define TOP_PREFIX top->rootp->ysyx_20020207__DOT__
#define PC_BEGIN 0x80000000
#endif
// #define TOP_MEMBER_HELPER(prefix, member) prefix member
#define CONCAT_HELPER(x, y) x##y
#define CONCAT(x, y) CONCAT_HELPER(x, y)
#define TOP_MEMBER(m) CONCAT(TOP_PREFIX, m)

TOP_NAME *top;
std::unordered_map<std::string, std::function<int(char *)>> sdb_map;
CPU_status cpu;
uint32_t pc;

enum {
  LOAD,
  STORE,
  CSR,
  EXECUTE,
  LSU,
  IFETCH,
};

struct CachePerf {
  int miss = 0;
  int hit = 0;
  void cache_miss() { miss++; }
  void cache_hit() { hit++; }
  void cache_init() {
    hit = 0;
    miss = 0;
  }
  ~CachePerf() {
    std::cout << std::format(
        "inst nums = {}\ncache miss = {}\ncache hit = {}\nmiss 占比：{}%\n\n",
        miss + hit, miss, hit, (float)miss / (float)(miss + hit));
  }
};

class Performance {
public:
  int inst_nums = 0;
  int clk_nums = 0;
  int ifu_nums = 0;
  int load_nums = 0;
  int exu_nums = 0;
  int idu_exu_nums = 0, idu_store_nums = 0, idu_load_nums = 0, idu_csr_nums = 0;
  int inst_type = 0;
  int clk_rev = 0;
  int inst_clk[6];
  void ifu_get_inst() {
    if (pc >= PC_BEGIN)
      ifu_nums++;
  }
  void lsu_get_data() {
    if (pc >= PC_BEGIN)
      load_nums++;
  }
  void exu_finish_cal() {
    if (pc >= PC_BEGIN)
      exu_nums++;
  }
  void idu_decode_inst(int inst) {
    if (pc >= PC_BEGIN) {
      int a = inst & 0x7f;
      switch (a) {
      case 0x03:
        idu_load_nums++;
        inst_type = LOAD;
        break;
      case 0x23:
        idu_store_nums++;
        inst_type = STORE;
        break;
      case 0x73:
        idu_csr_nums++;
        inst_type = CSR;
        break;
      default:
        idu_exu_nums++;
        inst_type = EXECUTE;
      }
    }
  }

  float get_ipc() {
    if (clk_nums != 0)
      return float(inst_nums) / float(clk_nums);
    else
      return 0;
  }

  ~Performance() {
    clk_nums -= 10;
    std::cout << std::format(
        "inst_nums = {}\nclk_nums = {}\nipc = {}\nifu_nums = {}\nload_nums = "
        "{}\nexu_nums = {}\n"
        "inst_exu_nums = {},占比{}%,平均需要{}个周期\n"
        "inst_csr_nums = {},占比{}%,平均需要{}个周期\n"
        "inst_store_nums = {},占比{}%,平均需要{}个周期\n"
        "inst_load_nums = {},占比{}%,平均需要{}个周期\n"
        "平均访存延迟为{}个周期\n"
        "平均取指延迟为{}个周期\n"
        "平均每条指令为{}个周期\n",
        inst_nums, clk_nums, get_ipc(), ifu_nums, load_nums, exu_nums,
        idu_exu_nums, (float)idu_exu_nums / (float)inst_nums * 100,
        (float)inst_clk[EXECUTE] / (float)idu_exu_nums, idu_csr_nums,
        (float)idu_csr_nums / (float)inst_nums * 100,
        (float)inst_clk[CSR] / (float)idu_csr_nums, idu_store_nums,
        (float)idu_store_nums / (float)inst_nums * 100,
        (float)inst_clk[STORE] / (float)idu_store_nums, idu_load_nums,
        (float)idu_load_nums / (float)inst_nums * 100,
        (float)inst_clk[LOAD] / (float)idu_load_nums,
        (float)inst_clk[LSU] / (float)(idu_load_nums + idu_store_nums),
        (float)inst_clk[IFETCH] / (float)inst_nums,
        (float)clk_nums / (float)(inst_nums - 1));
  }
};

Performance perf;
CachePerf cacheperf;
extern "C" {

void ifu_get_inst() { perf.ifu_get_inst(); }
void lsu_get_data() { perf.lsu_get_data(); }
void exu_finish_cal() { perf.exu_finish_cal(); }
void idu_decode_inst(int inst) { perf.idu_decode_inst(inst); }

void cache_miss() { cacheperf.cache_miss(); }
void cache_hit() { cacheperf.cache_hit(); }
void cache_init() { cacheperf.cache_init(); }
}

void cpu_update() {
  for (int i = 0; i < 16; i++) {
    cpu.gpr[i] = (TOP_MEMBER(mreg__DOT__rf))[i];
  }
  cpu.pc = TOP_MEMBER(pc);
}

void sim_init() {
  top = new TOP_NAME;
  assert(top != NULL);
#ifdef CONFIG_GTKTRACE
  Verilated::traceEverOn(true);
  contextp = new VerilatedContext;
  tfp = new VerilatedVcdC;
  top->trace(tfp, 0);
  tfp->open("dump.vcd");
#endif

#ifdef CONFIG_NVBOARD
  nvboard_bind_all_pins(top);
  nvboard_init();
#endif
}

void sim_close() {
  top->final();
#ifdef CONFIG_GTKTRACE
  delete top;
  delete tfp;
  delete contextp;
#endif
}

void step_and_dump_wave() {
  top->eval();
#ifdef CONFIG_GTKTRACE
  if (trace_enable) {
    contextp->timeInc(1);
    tfp->dump(contextp->time());
  }
#endif
}
void single_cycle() {
  top->clock = 1;
  step_and_dump_wave();
  top->clock = 0;
  step_and_dump_wave();
}

void reset(int n) {
  top->reset = 1;
  while (n-- > 0)
    single_cycle();
  top->reset = 0;
}

bool mem_en = false;
bool mem_wen = false;
bool perf_begin = false;
int lsu_begin = 0;
uint32_t inst;
int exec_once() {

#ifdef CONFIG_NVBOARD
  nvboard_update();
#endif
// top->inst = inst;
#ifdef CONFIG_GTKTRACE
  if (trace_enable != 1)
    trace_enable = 1;
#endif
  if (pc >= PC_BEGIN && TOP_MEMBER(pc_wen))
    perf_begin = true;
  if (perf_begin) {
    perf.clk_nums++;
    if (TOP_MEMBER(mifu__DOT___inst_valid)) {
      perf.inst_nums++;
      int fetch_clk = perf.clk_nums - perf.clk_rev;
      /* if (fetch_clk != 9) */
      /* std::cout << std::format("取指周期{},pc=0x{:x}\n", fetch_clk, pc); */
      perf.inst_clk[IFETCH] += fetch_clk;
      lsu_begin = perf.clk_nums;
    }
    if ((perf.inst_type == LOAD || perf.inst_type == STORE) &&
        TOP_MEMBER(lsu_finish))
      perf.inst_clk[LSU] += perf.clk_nums - lsu_begin;

    if (TOP_MEMBER(pc_wen)) {
      perf.inst_clk[perf.inst_type] += perf.clk_nums - perf.clk_rev;
      perf.clk_rev = perf.clk_nums;
    }
  }
  mem_en = true;
  mem_wen = true;
  top->clock = 1;
  step_and_dump_wave();
  mem_en = false;
  mem_wen = false;
  pc = TOP_MEMBER(pc);
  inst = TOP_MEMBER(inst);
  top->clock = 0;
  step_and_dump_wave();
// mem_en = false;
#ifdef CONFIG_DEVICE
  device_updata();
#endif

#ifdef CONFIG_ITRACE
  if (TOP_MEMBER(lsu_finish)) {
    disassemble(inst_buf, 128, (uint64_t)pc, (uint8_t *)(&inst), 4);
    // printf("%08x\n", inst);
    printf("0x%x\t0x%08x\t%s\t\n", TOP_MEMBER(pc), inst, inst_buf);
  }
#endif

#ifdef CONFIG_FTRACE
  if (TOP_MEMBER(lsu_finish))
    ftrace(inst, pc, TOP_MEMBER(exu_upc));
#endif

#ifdef CONFIG_DIFFTEST
  // printf("result=0x%x\n", top->result);
  cpu_update();
  extern int difftest_step();
  extern bool npc_is_ref_skip;
  npc_is_ref_skip = npc_is_ref_skip ? 1 : TOP_MEMBER(is_diff_skip);
  if (TOP_MEMBER(diff) && (difftest_step() == -1))
    return -1;
#endif

  int is_exit;
  if (TOP_MEMBER(is_exit)) {
    if (cpu.gpr[10] == 1)
      return -1;
    else
      return 1;
  }
  return 0;
}

int cmd_c(char *args) {
  int i;
  while (1) {
    if ((i = exec_once()) != 0)
      return i;
  }
}
int cmd_si(char *args) {
  if (args == nullptr) {
    return exec_once();
  } else {
    int j;
    char *num = strtok(args, " ");
    int n = atoi(num);
    for (int i = 0; i < n; i++) {
      if ((j = exec_once()) != 0)
        return j;
    }
  }
  return 0;
}
int cmd_info(char *args) {
  for (int i = 0; i < 32; i++) {
    printf("x[%d] = 0x%x ", i, (TOP_MEMBER(mreg__DOT__rf))[i]);
  }
  std::cout << '\n';
  return 0;
}
int cmd_q(char *args) { return 1; }
int cmd_x(char *args) {
  if (args == nullptr) {
    printf("请输入打印地址\n");
    return 0;
  }
  char *endptr;
  uint32_t addr = strtol(strtok(args, " "), &endptr, 0);
  printf("0x%08x\n", (uint32_t)vmem_read(addr, 4));
  return 0;
}

void sdb_init() {
  sdb_map["si"] = cmd_si;
  sdb_map["c"] = cmd_c;
  sdb_map["info"] = cmd_info;
  sdb_map["q"] = cmd_q;
  sdb_map["x"] = cmd_x;
}
int batch = 0;
int run() {
  char args[32];
  char *cmd;
  char *strend;
  std::string line;
#ifdef CONFIG_DIFFTEST
  extern bool npc_is_ref_skip;
  npc_is_ref_skip = true;
#endif
#ifdef CONFIG_DEVICE
  extern void sdl_clear_event_queue();
  sdl_clear_event_queue();
#endif
  if (batch == 1) {
    int result = cmd_c(NULL);
    if (result == 1)
      return 0;
    else if (result == -1)
      return -1;
  } else {
    std::cout << "<< ";
    while (getline(std::cin, line)) {
      strcpy(args, line.c_str());
      strend = args + strlen(args);
      cmd = strtok(args, " ");
      char *sdb_args = cmd + strlen(cmd) + 1;
      if (sdb_args >= strend)
        sdb_args = nullptr;
      int result = sdb_map[cmd](sdb_args);
      if (result == 1)
        return 0;
      else if (result == -1)
        return -1;
      std::cout << "<< ";
    }
  }
}
