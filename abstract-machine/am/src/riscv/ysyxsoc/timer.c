#include <am.h>
#include <ysyxsoc.h>
void __am_timer_init() {
}




//static inline uint32_t inl(uintptr_t addr) { return *(volatile uint32_t *)addr; }
void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uint64_t time_hi = inl(RTC_ADDR + 4);
  uptime->us = (time_hi << 32) + inl(RTC_ADDR);
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}
