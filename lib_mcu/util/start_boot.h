/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief 
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  AT90USB1287, AT90USB1286, AT90USB647, AT90USB646
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

#ifndef _START_BOOT_H_
#define _START_BOOT_H_

#define GOTOBOOTKEY  0x55AAAA55

   extern U32 boot_key __attribute__ ((section (".noinit")));

void start_boot_if_required(void);   
void start_boot(void);

#endif
