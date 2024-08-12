#include "trap.h"

/*void test() {
  int i = 0;
  int k = 1;
  int c;
  while (true) {
    c = 0;
    *(int *)0x10002000 = k;
    k = k << 1;
    i++;
    if (i == 16) {
      i = 0;
      k = 1;
    }
    while (c < 100)
      c++;
  }
  printf("%d", c);
}
*/
#define NAMEINIT(key) [AM_KEY_##key] = #key,
static const char *names[] = {AM_KEYS(NAMEINIT)};

static void drain_keys() {
  while (1) {
    AM_INPUT_KEYBRD_T ev = io_read(AM_INPUT_KEYBRD);
    // printf("%d\n", ev.keycode);
    if (ev.keycode == AM_KEY_NONE)
      continue;
    printf("Got  (kbd): %s (%d) %s\n", names[ev.keycode], ev.keycode,
           ev.keydown ? "DOWN" : "UP");
  }
}
int main() {
  *(int *)0x10002008 = 0x2 << 28 | 0x2 << 16 | 0x2 << 8 | 0x7;
  /*while(true)
  {
    if(*(int*)0x10002004 == 0x0001)
      break;
  }*/
  /* test(); */
  *(int *)0x10002000 = 0x11;
  /* while (true) { */
  /*   char a = getch(); */
  /*   if (a != 0xff) { */
  /*     putch(a); */
  /*     if (a == 'a') */
  /*       break; */
  /*   } */
  /* } */
  drain_keys();
  return 0;
}

/* *(int*)0x10002000 = 0xffff; */
// check(*(int*)0x10002000 == 0x00001100);
// while(true);
