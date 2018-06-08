@ @c
#include "config.h"
#include "lib_mcu/uart/uart_lib.h"


bit uart_test_hit (void)
{
return Uart_rx_ready();
}

bit uart_init (void)
{
  UBRR1 = (U16)(((U32)FOSC*1000L)/((U32)57600/2*16)-1); @+ UCSR1A |= 1 << U2X1; /* 57600 */
  UCSR1C = 0x06; /* 8N1 */
  UCSR1B |= (1 << RXEN1) | (1 << TXEN1); /* enable uart */
  return TRUE;
}


r_uart_ptchar uart_putchar (p_uart_ptchar ch)
{
  while(!Uart_tx_ready());
  Uart_set_tx_busy(); // Set Busy flag before sending (always)
  Uart_send_byte(ch);
   
  return ch;
}




char uart_getchar (void)
{
  register char c;

  while(!Uart_rx_ready());
  c = Uart_get_byte();
  Uart_ack_rx_byte();
  return c;
}

