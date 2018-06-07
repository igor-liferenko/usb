@ @c
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

#include "config.h"
#include "start_boot.h"
#include "lib_mcu/wdt/wdt_drv.h"

void (*start_bootloader) (void)=(void (*)(void))0x3800;

   U32 boot_key __attribute__ ((section (".noinit")));
   

void start_boot_if_required(void)
{
  if(boot_key==GOTOBOOTKEY)
  {
      boot_key = 0;
      (*start_bootloader)();           //! Jumping to bootloader
  }
}

void start_boot(void)
{
   boot_key=0x55AAAA55;
   
   // Enable the WDT for reset mode
      wdt_reset();
      Wdt_change_enable();
      Wdt_enable_16ms();
   while(1);
}

