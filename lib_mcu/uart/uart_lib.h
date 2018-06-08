/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief This file contains Uart lib header file.
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

#ifndef _UART_LIB_H_
#define _UART_LIB_H_

/*_____ I N C L U D E - F I L E S ____________________________________________*/
#include "uart_drv.h"

bit uart_init (void);

/**
 * @brief This function allows to send a character on the UART
 *
 * @param uc_wr_byte character to print on UART.
 *
 * @return character sent.
 *
 * @par Note:
*  the type p_uart_ptchar and r_uart_ptchar can be define to macth with a printf
 * need.
 *
 */
r_uart_ptchar uart_putchar (p_uart_ptchar uc_wr_byte);

/**
 * @brief This function allows to get a character from the UART
 *
 * @return character read.
 *
 */
char uart_getchar (void);

/**
 * @brief This function allows to inform if a character was received
 *
 * @return True if character received.
 *
 */
bit uart_test_hit (void);



#endif /* _UART_LIB_H_ */
