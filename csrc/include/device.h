#ifdef CONFIG_DEVICE

#pragma once
#include <cstdint>

#define DEVICE_BASE 0xa0000000
#define MMIO_BASE 0xa0000000

#define SERIAL_PORT     (DEVICE_BASE + 0x00003f8)
#define KBD_ADDR        (DEVICE_BASE + 0x0000060)
#define RTC_ADDR        (DEVICE_BASE + 0x0000048)
#define VGACTL_ADDR     (DEVICE_BASE + 0x0000100)
#define AUDIO_ADDR      (DEVICE_BASE + 0x0000200)
#define DISK_ADDR       (DEVICE_BASE + 0x0000300)
#define FB_ADDR         (MMIO_BASE   + 0x1000000)
#define AUDIO_SBUF_ADDR (MMIO_BASE   + 0x1200000)

#define TIMER_HZ 60
#define WIDTH 800
#define HEIGHT 600
void vga_update_screen();
void init_vga();
void device_updata();
uint64_t get_time();
void send_key(uint8_t, bool);
void i8042_data_io_handler();
void init_i8042();
uint32_t get_key();

#endif
