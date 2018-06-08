/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief This file contains the system configuration definition.
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

#ifndef _CONFIG_H_
#define _CONFIG_H_

// Compiler switch (do not change these settings)
#include "lib_mcu/compiler.h"             // Compiler definitions
   #include <avr/io.h>                    // Use AVR-GCC library


//! @defgroup global_config Application configuration
//! @{

#include "conf/conf_scheduler.h" //!< Scheduler tasks declaration

//! Enable or not the ADC usage
#undef  USE_ADC

//! CPU core frequency in kHz
#define FOSC 16000
#define PLL_OUT_FRQ  PLL_OUT_48MHZ


// -------- END Generic Configuration -------------------------------------

// UART Sample configuration, if we have one ... __________________________
#define BAUDRATE        57600
#define USE_UART2
#define UART_U2

//#define uart_putchar putchar
#define r_uart_ptchar int
#define p_uart_ptchar int

#define REPEAT_KEY_PRESSED       100

//! @}

#endif // _CONFIG_H_

