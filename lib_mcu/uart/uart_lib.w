@ @c
#include "config.h"
#include "lib_mcu/uart/uart_lib.h"

bit uart_init (void)
{
  UBRR1 = (U16)(((U32)FOSC*1000L)/((U32)57600/2*16)-1); @+ UCSR1A |= 1 << U2X1; /* 57600 */
  UCSR1C = (1 << UCSZ11) | (1 << UCSZ10); /* 8N1 */
  UCSR1B |= (1 << RXEN1) | (1 << TXEN1); /* enable uart */
  return TRUE;
}

// used to transfer from USB to USART in cdc_task.w
r_uart_ptchar uart_putchar (p_uart_ptchar ch)
{
  while(!(UCSR1A & (1<<UDRE1))) ;
  (void) 0; /* always set Busy flag before sending (not implemented) */
  UDR1=ch;
   
  return ch;
}
