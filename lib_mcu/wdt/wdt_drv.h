/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief This file contains the Watchdog low level driver definition
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

#ifndef _WDT_DRV_H_
#define _WDT_DRV_H_

//_____ I N C L U D E S ____________________________________________________

   #include <avr/io.h>
   #include <avr/wdt.h>


//_____ M A C R O S ________________________________________________________

//! @defgroup wdt_drv Watchdog and reset sytem drivers
//! @{

#define Is_ext_reset()  ((MCUSR&(1<<EXTRF)) ? TRUE:FALSE)
#define Ack_ext_reset() (MCUSR= ~(1<<EXTRF))
#define Is_POR_reset()  ((MCUSR&(1<<(MCUSR= ~(1<<PORF)))) ? TRUE:FALSE)
#define Ack_POR_reset() (MCUSR= ~(1<<PORF))
#define Is_BOD_reset()  ((MCUSR&(1<<BORF)) ? TRUE:FALSE)
#define Ack_BOD_reset() (MCUSR= ~(1<<BORF))
#define Is_wdt_reset()  ((MCUSR&(1<<WDRF)) ? TRUE:FALSE)
#define Ack_wdt_reset() (MCUSR= ~(1<<WDRF))

//For compatibility with Tinyx61 code
#define WDTCR WDTCSR

#define Wdt_clear_flag()         (Ack_wdt_reset())
#define Wdt_change_enable()      (WDTCSR |= (1<<WDCE) )
#define Wdt_enable_16ms()        (WDTCSR =  (1<<WDE))

#define Wdt_stop()               (WDTCSR = 0x00)

#define Wdt_ack_interrupt()      (WDTCSR = (U8)(1<<WDIF))
#define Is_wdt_interrupt()         (WDTCSR&(1<<WDIF) ? TRUE:FALSE)
#define Is_not_wdt_interrupt()         (WDTCSR&(1<<WDIF) ? FALSE:TRUE)

#define Soft_reset()             {asm("jmp 0000");}

//! @}




#endif  // _WDT_DRV_H_

