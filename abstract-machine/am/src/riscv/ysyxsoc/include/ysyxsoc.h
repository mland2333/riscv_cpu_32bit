#pragma once

#include <klib-macros.h>
#include ISA_H
#define UART_BASE 0x10000000
#define UART_TX   0

#define DEVICE_BASE 0xa0000000
#define MMIO_BASE 0xa0000000

#define SERIAL_PORT     (DEVICE_BASE + 0x00003f8)
#define KBD_ADDR        (0x10011000)
#define RTC_ADDR        (0x20000000 + 0xbff8)
#define VGACTL_ADDR     (DEVICE_BASE + 0x0000100)
#define AUDIO_ADDR      (DEVICE_BASE + 0x0000200)
#define DISK_ADDR       (DEVICE_BASE + 0x0000300)
#define FB_ADDR         (0x21000000)
#define AUDIO_SBUF_ADDR (MMIO_BASE   + 0x1200000)

#define REG(reg) ((volatile uint8_t *)(UART_BASE + reg))
#define ReadReg(reg) (*(REG(reg)))
#define WriteReg(reg, v) (*(REG(reg)) = (v))

#define RBR 0x0	// Receive Holding Register (read mode)
#define THR 0x0	// Transmit Holding Register (write mode)
#define DLL 0x0	// LSB of Divisor Latch (write mode)
#define IER 0x1	// Interrupt Enable Register (write mode)
#define DLM 0x1	// MSB of Divisor Latch (write mode)
#define FCR 0x2	// FIFO Control Register (write mode)
#define ISR 0x2	// Interrupt Status Register (read mode)
#define LCR 0x3	// Line Control Register
#define MCR 0x4	// Modem Control Register
#define LSR 0x5	// Line Status Register
#define MSR 0x6	// Modem Status Register
#define SCR 0x7	// ScratchPad Register
#define LSR_RX_READY (1 << 0)
#define LSR_TX_IDLE  (1 << 5)


