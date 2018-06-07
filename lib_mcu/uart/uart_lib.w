@ @c
/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief This file provides a minimal VT100 terminal access through UART
//! and compatibility with Custom I/O support
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

/*_____ I N C L U D E S ____________________________________________________*/
#include "config.h"
#include "lib_mcu/uart/uart_lib.h"


/*_____ G L O B A L    D E F I N I T I O N _________________________________*/


/*_____ D E F I N I T I O N ________________________________________________*/

/*_____ M A C R O S ________________________________________________________*/


bit uart_test_hit (void)
{
return Uart_rx_ready();
}


bit uart_init (void)
{
#ifndef UART_U2
  Uart_set_baudrate(BAUDRATE);
  Uart_hw_init(UART_CONFIG);
#else
  Uart_set_baudrate(BAUDRATE/2);
  Uart_double_bdr();
  Uart_hw_init(UART_CONFIG);

#endif
  Uart_enable();
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


