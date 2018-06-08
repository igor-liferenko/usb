/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief @brief This file controls the UART USB functions.
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

#ifndef _UART_USB_LIB_H_
#define _UART_USB_LIB_H_

void  uart_usb_init(void);
bit   uart_usb_test_hit(void);
char uart_usb_getchar(void);
bit   uart_usb_tx_ready(void);
int  uart_usb_putchar(int);
void  uart_usb_flush(void);
void uart_usb_send_buffer(U8 *buffer, U8 nb_data);

#endif /* _UART_USB_LIB_H_ */
