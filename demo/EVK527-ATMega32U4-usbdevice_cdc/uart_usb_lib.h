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

/*_____ I N C L U D E S ____________________________________________________*/


/*_____ M A C R O S ________________________________________________________*/
#ifdef UART_USB_DEFAULT_INPUT
#define uart_usb_getchar            _getkey
#define uart_usb_test_hit           test_hit
#endif

#ifdef UART_USB_DEFAULT_OUTPUT
#define uart_usb_putchar            putchar
#endif

/*_____ D E F I N I T I O N ________________________________________________*/


/*_____ D E C L A R A T I O N ______________________________________________*/

void  uart_usb_init(void);
bit   uart_usb_test_hit(void);
char uart_usb_getchar(void);
bit   uart_usb_tx_ready(void);
int  uart_usb_putchar(int);
void  uart_usb_flush(void);
void uart_usb_send_buffer(U8 *buffer, U8 nb_data);

#endif /* _UART_USB_LIB_H_ */
