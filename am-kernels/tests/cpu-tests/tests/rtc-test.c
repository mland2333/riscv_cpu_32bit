#include "trap.h"

void rtc_test() {

  int sec = 1;
  while (1) {
    while(io_read(AM_TIMER_UPTIME).us / 50000 < sec) ;
    /* rtc = io_read(AM_TIMER_RTC); */
    /* printf("%d-%d-%d %02d:%02d:%02d GMT (", rtc.year, rtc.month, rtc.day, rtc.hour, rtc.minute, rtc.second); */
    if (sec == 1) {
      printf("%d\n", sec);
    } else {
      printf("%d\n", sec);
    }
    sec ++;
  }
}

int main(){
  rtc_test();
  return 0;
}
