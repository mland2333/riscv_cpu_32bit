#include <nvboard.h>
#include <Vtop.h>
/* #include "verilated_vcd_c.h" */
static TOP_NAME dut;
/* VerilatedContext *contextp = NULL; */
/* VerilatedVcdC *tfp = NULL; */
void nvboard_bind_all_pins(TOP_NAME *top);

static void single_cycle() {
  dut.clk = 0;
  dut.eval();
  /* contextp->timeInc(1); */
  /* tfp->dump(contextp->time()); */
  dut.clk = 1;
  dut.eval();
  /* contextp->timeInc(1); */
  /* tfp->dump(contextp->time()); */
}

static void reset(int n) {
  dut.rst = 1;
  while (n-- > 0)
    single_cycle();
  dut.rst = 0;
}

int main() {
  nvboard_bind_all_pins(&dut);
  nvboard_init();
  /* Verilated::traceEverOn(true); */
  /* contextp = new VerilatedContext; */
  /* tfp = new VerilatedVcdC; */
  /* dut.trace(tfp, 0); */
  /* tfp->open("dump.vcd"); */
  reset(10);

  while (1) {
    nvboard_update();
    single_cycle();
  }
  /* delete tfp; */
  /* delete contextp; */
}
