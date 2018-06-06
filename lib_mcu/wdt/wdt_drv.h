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

/* Copyright (c) 2007, Atmel Corporation All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. The name of ATMEL may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY ATMEL ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE EXPRESSLY AND
 * SPECIFICALLY DISCLAIMED. IN NO EVENT SHALL ATMEL BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#ifndef _WDT_DRV_H_
#define _WDT_DRV_H_

//_____ I N C L U D E S ____________________________________________________

#ifdef __GNUC__
   #include <avr/io.h>
   #include <avr/wdt.h>
#endif


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

#ifdef __GNUC__
//#define Wdt_reset_instruction()   (asm("WDR"))
#define Wdt_reset_instruction()  (wdt_reset())
#else
#define Wdt_reset_instruction()  (__watchdog_reset())
#endif
#define Wdt_clear_flag()         (Ack_wdt_reset())
#define Wdt_change_enable()      (WDTCSR |= (1<<WDCE) )
#define Wdt_enable_16ms()        (WDTCSR =  (1<<WDE))
#define Wdt_enable_32ms()        (WDTCSR =  (1<<WDE) | (1<<WDP0) )
#define Wdt_enable_64ms()        (WDTCSR =  (1<<WDE) | (1<<WDP1) )
#define Wdt_enable_125ms()       (WDTCSR =  (1<<WDE) | (1<<WDP1) | (1<<WDP0))
#define Wdt_enable_250ms()       (WDTCSR =  (1<<WDE) | (1<<WDP2) )
#define Wdt_enable_500ms()       (WDTCSR =  (1<<WDE) | (1<<WDP2) | (1<<WDP0))
#define Wdt_enable_1s()          (WDTCSR =  (1<<WDE) | (1<<WDP2) | (1<<WDP1))
#define Wdt_enable_2s()          (WDTCSR =  (1<<WDE) | (1<<WDP2) | (1<<WDP1) | (1<<WDP0))
#define Wdt_enable_4s()          (WDTCSR =  (1<<WDE) | (1<<WDP3) )
#define Wdt_enable_8s()          (WDTCSR =  (1<<WDE) | (1<<WDP3) | (1<<WDP0))

#define Wdt_interrupt_16ms()     (WDTCSR =  (1<<WDIE))
#define Wdt_interrupt_32ms()     (WDTCSR =  (1<<WDIE) | (1<<WDP0) )
#define Wdt_interrupt_64ms()     (WDTCSR =  (1<<WDIE) | (1<<WDP1) )
#define Wdt_interrupt_125ms()    (WDTCSR =  (1<<WDIE) | (1<<WDP1) | (1<<WDP0))
#define Wdt_interrupt_250ms()    (WDTCSR =  (1<<WDIE) | (1<<WDP2) )
#define Wdt_interrupt_500ms()    (WDTCSR =  (1<<WDIE) | (1<<WDP2) | (1<<WDP0))
#define Wdt_interrupt_1s()       (WDTCSR =  (1<<WDIE) | (1<<WDP2) | (1<<WDP1))
#define Wdt_interrupt_2s()       (WDTCSR =  (1<<WDIE) | (1<<WDP2) | (1<<WDP1) | (1<<WDP0))
#define Wdt_interrupt_4s()       (WDTCSR =  (1<<WDIE) | (1<<WDP3) )
#define Wdt_interrupt_8s()       (WDTCSR =  (1<<WDIE) | (1<<WDP3) | (1<<WDP0))

#define Wdt_enable_reserved5()   (WDTCSR =  (1<<WDE) | (1<<WDP3) | (1<<WDP2) | (1<<WDP1) | (1<<WDP0))
#define Wdt_stop()               (WDTCSR = 0x00)

#define Wdt_ack_interrupt()      (WDTCSR = (U8)(1<<WDIF))
#define Is_wdt_interrupt()         (WDTCSR&(1<<WDIF) ? TRUE:FALSE)
#define Is_not_wdt_interrupt()         (WDTCSR&(1<<WDIF) ? FALSE:TRUE)




//! Wdt_off.
//!
//! This macro stops the hardware watchdog timer.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_off()                (Wdt_reset_instruction(),  \
                                  Wdt_clear_flag(),         \
                                  Wdt_change_enable(),      \
                                  Wdt_stop())




//! wdt_change_16ms.
//!
//! This macro activates the hardware watchdog timer for 16ms timeout.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_16ms()        (Wdt_reset_instruction(), \
                                  Wdt_change_enable(),     \
                                  Wdt_enable_32ms() )
                              
//! wdt_change_32ms.
//!
//! This macro activates the hardware watchdog timer for 32ms timeout.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_32ms()        (Wdt_reset_instruction(), \
                                  Wdt_change_enable(),     \
                                  Wdt_enable_32ms() )


//! wdt_change_64ms.
//!
//! This macro activates the hardware watchdog timer for 64ms timeout.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_64ms()        (Wdt_reset_instruction(), \
                                  Wdt_change_enable(),     \
                                  Wdt_enable_64ms() )




//! wdt_change_32ms.
//!
//! This macro activates the hardware watchdog timer for 125ms timeout.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_125ms()       (Wdt_reset_instruction(), \
                                  Wdt_change_enable(),     \
                                  Wdt_enable_125ms() )

//! wdt_change_250ms.
//!
//! This macro activates the hardware watchdog timer for 250ms timeout.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_250ms()       (Wdt_reset_instruction(), \
                                  Wdt_change_enable(),     \
                                  Wdt_enable_250ms() )

//! wdt_change_500ms.
//!
//! This macro activates the hardware watchdog timer for 500ms timeout.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_500ms()       (Wdt_reset_instruction(), \
                                  Wdt_change_enable(),     \
                                  Wdt_enable_500ms() )

//! wdt_change_1s.
//!
//! This macro activates the hardware watchdog timer for 1s timeout.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_1s()          (Wdt_reset_instruction(), \
                                  Wdt_change_enable(),     \
                                  Wdt_enable_1s() )


//! wdt_change_2s.
//!
//! This macro activates the hardware watchdog timer for 2s timeout.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_2s()          (Wdt_reset_instruction(), \
                                  Wdt_change_enable(),     \
                                  Wdt_enable_2s() )
//! wdt_change_4s.
//!
//! This macro activates the hardware watchdog timer for 4s timeout.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_4s()          (Wdt_reset_instruction(), \
                                  Wdt_change_enable(),     \
                                  Wdt_enable_4s() )


//! wdt_change_8s.
//!
//! This macro activates the hardware watchdog timer for 8s timeout.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_8s()          (Wdt_reset_instruction(), \
                                  Wdt_change_enable(),     \
                                  Wdt_enable_8s() )


//! wdt_change_interrupt_16ms.
//!
//! This macro activates the hardware watchdog timer for 16ms interrupt.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_interrupt_16ms()    (Wdt_reset_instruction(), \
                                        Wdt_change_enable(),     \
                                        Wdt_interrupt_16ms() )

//! wdt_change_interrupt_32ms.
//!
//! This macro activates the hardware watchdog timer for 32ms interrupt.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_interrupt_32ms()    (Wdt_reset_instruction(), \
                                        Wdt_change_enable(),     \
                                        Wdt_interrupt_32ms() )

//! wdt_change_interrupt_64ms.
//!
//! This macro activates the hardware watchdog timer for 64ms interrupt.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_interrupt_64ms()    (Wdt_reset_instruction(), \
                                        Wdt_change_enable(),     \
                                        Wdt_interrupt_64ms() )

//! wdt_change_interrupt_125ms.
//!
//! This macro activates the hardware watchdog timer for 125ms interrupt.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_interrupt_125ms()      (Wdt_reset_instruction(), \
                                           Wdt_change_enable(),     \
                                           Wdt_interrupt_125ms() )

//! wdt_change_interrupt_250ms.
//!
//! This macro activates the hardware watchdog timer for 250ms interrupt.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_interrupt_250ms()      (Wdt_reset_instruction(), \
                  Wdt_change_enable(),     \
                  Wdt_interrupt_250ms() )

//! wdt_change_interrupt_500ms.
//!
//! This macro activates the hardware watchdog timer for 500ms interrupt.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_interrupt_500ms()      (Wdt_reset_instruction(), \
                  Wdt_change_enable(),     \
                  Wdt_interrupt_500ms() )

//! wdt_change_interrupt_1s.
//!
//! This macro activates the hardware watchdog timer for 1s interrupt.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_interrupt_1s()      (Wdt_reset_instruction(), \
                  Wdt_change_enable(),     \
                  Wdt_interrupt_1s() )

//! wdt_change_interrupt_2s.
//!
//! This macro activates the hardware watchdog timer for 2s interrupt.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_interrupt_2s()      (Wdt_reset_instruction(), \
                  Wdt_change_enable(),     \
                  Wdt_interrupt_2s() )

//! wdt_change_interrupt_4s.
//!
//! This macro activates the hardware watchdog timer for 4s interrupt.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_interrupt_4s()      (Wdt_reset_instruction(), \
                  Wdt_change_enable(),     \
                  Wdt_interrupt_4s() )

//! wdt_change_interrupt_8s.
//!
//! This macro activates the hardware watchdog timer for 8s interrupt.
//!
//! @warning Interrupts should be disable before call to ensure
//! no timed sequence break.
//!
//! @param none
//!
//! @return none.
//!
#define Wdt_change_interrupt_8s()      (Wdt_reset_instruction(), \
                  Wdt_change_enable(),     \
                  Wdt_interrupt_8s() )

#define Wdt_change_reserved5()   (Wdt_reset_instruction(), \
                                 Wdt_change_enable(),     \
                                 Wdt_enable_reserved5() )

#define Soft_reset()             {asm("jmp 0000");}

//! @}




#endif  // _WDT_DRV_H_

