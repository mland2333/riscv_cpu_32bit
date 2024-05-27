/*`define SLL 2'b00
`define SRA 2'b01
`define SRL 2'b10*/

`define MRET 3'b001
`define ECALL 3'b010
`define EBREAK 3'b011
`define CSRW 3'b100

`define IFU_IDLE 2'b01
`define IFU_WAIT_READY 2'b10

`define DEVICE_BASE 32'ha0000000
`define UART 32'h10000000
`define RTC_ADDR 32'ha0000048
`define RTC_ADDR_HIGH 32'ha000004c
`define FLASH_BASE 32'h30000000
`define FLASH_SIZE 32'h10000000

`define SRAM_BASE 32'h0f000000
`define SRAM_SIZE 32'h00002000



