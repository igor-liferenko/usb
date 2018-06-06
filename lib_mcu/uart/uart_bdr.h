/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief Provide Baudrate configuration for MCU
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

#ifndef _UART_BDR_H
#define _UART_BDR_H

  #define Uart_set_baudrate(bdr)  ( UBRR = (U16)(((U32)FOSC*1000L)/((U32)bdr*16)-1))

#define Uart_double_bdr()          (UCSRA |= (1<<U2X1))

#endif/* _UART_BDR_H */

