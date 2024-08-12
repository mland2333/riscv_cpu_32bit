
#define UART_BASE 0x10000000L
#define UART_TX   0
void char_test() {
  *(volatile char *)(UART_BASE + UART_TX) = 'B';
  /**(volatile char *)(UART_BASE + UART_TX) = 'C';
  *(volatile char *)(UART_BASE + UART_TX) = 'C';
  *(volatile char *)(UART_BASE + UART_TX) = 'D';
  *(volatile char *)(UART_BASE + UART_TX) = 'E';*/
  while (1);
}

int main(){
  char_test();
  return 0;
}
