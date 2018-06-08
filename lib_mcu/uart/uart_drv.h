#ifndef _UART_DRV_H_
#define _UART_DRV_H_

#define Uart_tx_ready()         (UCSR1A & (1<<UDRE1))
#define Uart_set_tx_busy()
#define Uart_send_byte(ch)      (UDR1=ch)
#define Uart_rx_ready()         (UCSR1A & (1<<RXC1))
#define Uart_get_byte()         (UDR1)
#define Uart_ack_rx_byte()

#define Uart_enable_it_rx()    (UCSR1B |= 1 << RXCIE1)

#endif
