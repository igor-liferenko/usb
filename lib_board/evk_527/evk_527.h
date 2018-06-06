/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief This file contains the low level macros and definition for evk527 board
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

#ifndef EVK_527_H
#define EVK_527_H

//_____ I N C L U D E S ____________________________________________________
#include "config.h"

#if (TARGET_BOARD==EVK527)

#include "lib_mcu/flash/flash_drv.h"   // Because pin JTAG multiplexage

//_____ M A C R O S ________________________________________________________

//! @defgroup EVK_527_module evk527
//! This module contains low level hardware abstraction layer for evk527 board
//! @image html evk_527.gif
//! @{


      //! @defgroup EVK_527_leds Leds Management
      //! Macros to manage Leds on evk527
      //! @{
#define  LED_PORT       PORTD
#define  LED_DDR        DDRD
#define  LED_PIN        PIND
                    
#define  LED0_BIT       PIND5
#define  LED1_BIT       PIND6
#define  LED2_BIT       PIND7
        
#define  Leds_init()    (LED_DDR  |=  (1<<LED0_BIT) | (1<<LED1_BIT) | (1<<LED2_BIT))
#define  Leds_on()      (LED_PORT |=  (1<<LED0_BIT) | (1<<LED1_BIT) | (1<<LED2_BIT))
#define  Leds_off()     (LED_PORT &= ~((1<<LED0_BIT) | (1<<LED1_BIT) | (1<<LED2_BIT)))
#define  Leds_set_val(val) (Leds_off(),LED_PORT |= (val<<5)&((1<<LED0_BIT) | (1<<LED1_BIT) | (1<<LED2_BIT)))
#define  Leds_get_val()    (LED_PORT>>5)


#define  Led0_on()      (LED_PORT |= (1<<LED0_BIT))
#define  Led1_on()      (LED_PORT |= (1<<LED1_BIT))
#define  Led2_on()      (LED_PORT |= (1<<LED2_BIT))
        
#define  Led0_off()     (LED_PORT &= ~(1<<LED0_BIT))
#define  Led1_off()     (LED_PORT &= ~(1<<LED1_BIT))
#define  Led2_off()     (LED_PORT &= ~(1<<LED2_BIT))
        
#define  Led0_toggle()  (LED_PIN |= (1<<LED0_BIT))
#define  Led1_toggle()  (LED_PIN |= (1<<LED1_BIT))
#define  Led2_toggle()  (LED_PIN |= (1<<LED2_BIT))
        
#define  Is_led0_on()   (LED_PIN & (1<<LED0_BIT) ? TRUE : FALSE)
#define  Is_led1_on()   (LED_PIN & (1<<LED1_BIT) ? TRUE : FALSE)
#define  Is_led2_on()   (LED_PIN & (1<<LED2_BIT) ? TRUE : FALSE)
      //! @}

      //! @defgroup EVK_527_joy Joystick Management
      //! Macros to manage Joystick on evk527
      //! @note The up,left and right joy are mapped on JTAG pins
      //! @{
#define  Joy_init()           {DDRC &= ~0x40; PORTC |= 0x40; if(!Is_JTAG_enable()) {DDRF &= ~0xF0; PORTF |= 0xF0;}}
#define  Is_joy_right()       (Is_JTAG_enable() || (PINF & (1<<PINF7)) ?  FALSE : TRUE)
#define  Is_joy_not_right()   ((!Is_JTAG_enable()) && (PINF & (1<<PINF7)) ?  TRUE : FALSE)
#define  Is_joy_select()      (Is_JTAG_enable() || (PINF & (1<<PINF6)) ?  FALSE : TRUE)
#define  Is_joy_not_select()  ((!Is_JTAG_enable()) && (PINF & (1<<PINF6)) ?  TRUE : FALSE)
#define  Is_joy_up()          (Is_JTAG_enable() || (PINF & (1<<PINF5)) ?  FALSE : TRUE)
#define  Is_joy_not_up()      ((!Is_JTAG_enable()) && (PINF & (1<<PINF5)) ?  TRUE  : FALSE)
#define  Is_joy_left()        (Is_JTAG_enable() || (PINF & (1<<PINF4)) ?  FALSE : TRUE)
#define  Is_joy_not_left()    ((!Is_JTAG_enable()) && (PINF & (1<<PINF4)) ?  TRUE : FALSE)
#define  Is_joy_down()        ((PINC & (1<<PINC6)) ?  FALSE : TRUE)
#define  Is_joy_not_down()    ((PINC & (1<<PINC6)) ?  TRUE : FALSE)

//! Enable interrupts for switches (no possible)
#define  Switches_enable_it()

//! Disable interrupts for switches (no possible)
#define  Switches_disable_it()
      //! @}


      //! @defgroup EVK_527_hwb HWB button management
      //! HWB button is connected to PE2 and can also
      //! be used as generic push button
      //! @{
#define  Hwb_button_init()    (DDRE  &= ~(1<<PINE2), PORTE |= (1<<PINE2))
#define  Is_hwb()             ((PINE &   (1<<PINE2)) ?  FALSE : TRUE)
#define  Is_not_hwb()         ((PINE &   (1<<PINE2)) ?  TRUE : FALSE)
      //! @}


#define  Enable_DAC_pwm()      Timerhs_enable_pwm_d()
#define  Enable_buck_pwm()     Timerhs_enable_pwm_a()  
        
#define  Set_DAC_wpm(v)        Timerhs_set_compare_d(v)
#define  Set_buck_pwm(v)       Timerhs_set_compare_a(v)

//! EVK 527 ADC Channel Definition
#define  ADC_MIC_CH            0x21 // Enable Single Ended Input on ADC9 pin
#define  ADC_TEMP_CH           0x00 // Enable Single Ended Input on ADC0 pin

#ifdef USE_ADC       //!< this define is set in config.h file

//! Get_adc_mic_val.
//!
//! This function performs an ADC conversion from the evk527 MIC channel
//! an returns the 10 bits result in an U16 value.
//!
//! @warning USE_ADC should be defined in config.h
//!
//! @param none
//!
//! @return U16 microphone sample value.
//!
   U16 Get_adc_mic_val(void);

//! Get_adc_temp_val.
//!
//! This function performs an ADC conversion from the evk527 TEMP channel
//! an returns the 10 bits result in an U16 value.
//!
//! @warning USE_ADC should be defined in config.h
//!
//! @param none
//!
//! @return U16 analog sensor temperature value.
//!
   U16 Get_adc_temp_val(void);

//! Read_temperature.
//!
//! This function performs an ADC conversion from the evk527 POT channel
//! an returns the 10 bits result of the temperature (in °C) in an S16 value.
//!
//! @warning USE_ADC should be defined in config.h
//!
//! @param none
//!
//! @return S16 temperature value in °C.
//!
   S16  Read_temperature(void);

#endif  //!USE_ADC

      //! @defgroup EVK_527_df_evk527 ATMEL Hardware data flash configuration
      //! Macros to init the environnement for DF on evk527
      //! @{

#define DF_4_MB   // Type of DF implemented on evk527.


#define DF_SELECT_MEM        0
#define DF_UNSELECT_MEM      1
#define DF_NB_MEM            1

#ifndef __GNUC__
   // PORTB_Bit0=1,DDRB_Bit0=0: SPI Slave Select Input. The data direction of the
   //    NOT(SS) is INPUT and the pull-up resistor is activated.
   // DDRB_Bit1=1: the SCK signal direction is OUTPUT.
   // DDRB_Bit2=1: the SI signal direction is OUTPUT.
   // DDRB_Bit3=0: the SO signal direction is INPUT.
   // PORTB_Bit4=1,DDRB_Bit4=1: CS driven high
   //    and both CS are OUTPUT.

   
   #define DF_CS_PIN          PORTE_Bit6
   #define Init_df_evk527()   (DDRB_Bit0=1,PORTB_Bit0=1,DF_CS_PIN=1,DDRE|=0x40)
   #define DF_CS0             DF_CS_PIN
   #define DF_CS1             DF_CS0
   #define DF_CS2             DF_CS0
   #define DF_CS3             DF_CS0
   #define Df_select_df(i, val) (DF_CS##i = val)
   #define Df_desel_all()       (DF_CS0=DF_UNSELECT_MEM)     // set CS# dataflash memories
#else //! for __GNUC__
   #define Init_df_evk527()   (PORTB|=0x01,DDRB &= 0xFE,\
                           DDRB|=0x01,DDRB|=0x04,DDRB|=0x04,DF_CS_PORT|=(1<<DF_CS0),DDRE|=0x40)
   #define DF_CS_PORT         PORTE
   #define DF_CS0             6
   #define DF_CS1             DF_CS0
   #define DF_CS2             DF_CS0
   #define DF_CS3             DF_CS0
   #define Df_desel_all()     (DF_CS_PORT|=(1<<DF_CS0)) // set CS# dataflash memories (unselect).
#endif
#define df_init_spi()      Init_df_evk527()
      //! @}
   
      //! @defgroup EVK_527_mmc_sd Hardware mmc sd interface configuration
      //! Macros to init the environnement for mmc /sd on evk527
      //! @{   
#define   MMC_io_init()             (DDRB &= 0xF7, DDRB |= 0x07, PORTB |= 0x09)
#ifndef   __GNUC__
  #define   MMC_CS_LINE             PORTB_Bit0
#endif

#define   MMC_CS_PORT               PORTB   // port
#define   MMC_CS_PIN                0x00    // offset
#define   Mmc_sd_select()           (MMC_CS_PORT &= ~(1<<MMC_CS_PIN))
#define   Mmc_sd_unselect()         (MMC_CS_PORT |= (1<<MMC_CS_PIN))
      //! @}
//! @}

#endif   // TARGET_BOARD==EVK527

#endif  // EVK_527_H