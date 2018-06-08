/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief This file contains the Power Management low level driver definition
//!
//!  This module allows to configure the different power mode of the AVR core and
//!  also to setup the the internal clock prescaler
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

#ifndef _POWER_DRV_H_
#define _POWER_DRV_H_

//! @defgroup powermode Power management drivers
//!
//! @{

//_____ M A C R O S ________________________________________________________

#define Setup_idle_mode()                        (SMCR=0,SMCR |= (1<<SE))
#define Setup_power_down_mode()                   (SMCR=0,SMCR |= (1<<SE)+(1<<SM1))
#define Setup_adc_noise_reduction_mode()         (SMCR=0,SMCR |= (1<<SE)+(1<<SM0))
#define Setup_power_save_mode()                  (SMCR=0,SMCR |= (1<<SE)+(1<<SM1)+(1<<SM0))
#define Setup_standby_mode()                     (SMCR=0,SMCR |= (1<<SE)+(1<<SM2)+(1<<SM1))
#define Setup_ext_standby_mode()                  (SMCR=0,SMCR |= (1<<SE)+(1<<SM2)+(1<<SM1)+(1<<SM0))

#define Sleep_instruction()              {asm("SLEEP");}

//Backward compatibility
#define Set_power_down_mode()              set_power_down_mode()
#define Set_idle_mode()            set_idle_mode()

//_____ D E C L A R A T I O N ______________________________________________

void set_idle_mode(void);
void set_power_down_mode(void);
void set_adc_noise_reduction_mode(void);
void set_power_save_mode(void);
void set_standby_mode(void);
void set_ext_standby_mode(void);

//! Enter_idle_mode.
//!
//! This function makes the AVR core enter idle mode.
//!
//! @param none
//!
//! @return none.
//!
#define Enter_idle_mode()                 (set_idle_mode())

//! Enter_power_down_mode.
//!
//! This function makes the AVR core enter power down mode.
//!
//! @param none
//!
//! @return none.
//!
#define Enter_power_down_mode()           (set_power_down_mode())

//! Enter_adc_noise_reduction_mode.
//!
//! This function makes the AVR core enter adc noise reduction mode.
//!
//! @param none
//!
//! @return none.
//!
#define Enter_adc_noise_reduction_mode()  (set_adc_noise_reduction_mode())

//! Enter_power_save_mode.
//!
//! This function makes the AVR core enter power save mode.
//!
//! @param none
//!
//! @return none.
//!
#define Enter_power_save_mode()           (set_power_save_mode())

//! Enter_standby_mode.
//!
//! This function makes the AVR core enter standby mode.
//!
//! @param none
//!
//! @return none.
//!
#define Enter_standby_mode()              (set_standby_mode())

//! Enter_ext_standby_mode.
//!
//! This function makes the AVR core enter extended standby mode.
//!
//! @param none
//!
//! @return none.
//!
#define Enter_ext_standby_mode()          (set_ext_standby_mode())


//! @}




//! @defgroup clockmode Clock management drivers
//!
//! @{

//_____ M A C R O S ________________________________________________________

// Clock control
#define   Enable_external_clock()       (CLKSEL0 |= (1<<EXTE))
#define   Disable_external_clock()      (CLKSEL0 &= ~(1<<EXTE))
#define   Enable_RC_clock()             (CLKSEL0 |= (1<<RCE))
#define   Disable_RC_clock()            (CLKSEL0 &= ~(1<<RCE))

// Clock state
#define   External_clock_ready()        (((CLKSTA&(1<<EXTON)) != 0) ? TRUE : FALSE)
#define   RC_clock_ready()              (((CLKSTA&(1<<RCON)) != 0) ? TRUE : FALSE)

// Clock selection
#define   Select_external_clock()       (CLKSEL0 |= (1<<CLKS))
#define   Select_RC_clock()             (CLKSEL0 &= ~(1<<CLKS))

// Clock settings : when using a clock source, only the other clock source setting can be modified
// Set the source setting of the next clock source to use before switching to it
#define   Load_ext_clock_config(cfg)    (CLKSEL1 = (CLKSEL1&0xF0) | ((cfg&0x0F)<<EXCKSEL0), \
                                         CLKSEL0 = (CLKSEL0&0xCF) | (((cfg&0x30)>>4)<<EXSUT0))

#define   Load_RC_clock_config(cfg)     (CLKSEL1 = (CLKSEL1&0x0F) | ((cfg&0x0F)<<RCCKSEL0), \
                                         CLKSEL0 = (CLKSEL0&0x3F) | (((cfg&0x30)>>4)<<RCSUT0))

//_____ C L O C K   D E F I N I T I O N S ______________________________________
// Configuration byte defined as SUT<1:0> & CKSEL<3:0> (CKSEL0 is the LSb)

// Interal RC oscillator (frequency between 7.3 and 8.1 MHz)
#define   OSC_INTRC_0MS                  0x02
#define   OSC_INTRC_4MS                  0x12
#define   OSC_INTRC_65MS                 0x22

// External crystal, frequency between 0.3 and 0.9 MHz
#define   OSC_XTAL_RANGE1_258CK_4MS      0x08
#define   OSC_XTAL_RANGE1_258CK_65MS     0x18
#define   OSC_XTAL_RANGE1_1KCK_0MS       0x28
#define   OSC_XTAL_RANGE1_1KCK_4MS       0x38
#define   OSC_XTAL_RANGE1_1KCK_65MS      0x09
#define   OSC_XTAL_RANGE1_16KCK_0MS      0x19
#define   OSC_XTAL_RANGE1_16KCK_4MS      0x29
#define   OSC_XTAL_RANGE1_16KCK_65MS     0x39

// External crystal, frequency between 0.9 and 3 MHz
#define   OSC_XTAL_RANGE2_258CK_4MS      0x0A
#define   OSC_XTAL_RANGE2_258CK_65MS     0x1A
#define   OSC_XTAL_RANGE2_1KCK_0MS       0x2A
#define   OSC_XTAL_RANGE2_1KCK_4MS       0x3A
#define   OSC_XTAL_RANGE2_1KCK_65MS      0x0B
#define   OSC_XTAL_RANGE2_16KCK_0MS      0x1B
#define   OSC_XTAL_RANGE2_16KCK_4MS      0x2B
#define   OSC_XTAL_RANGE2_16KCK_65MS     0x3B

// External crystal, frequency between 3 and 8 MHz
#define   OSC_XTAL_RANGE3_258CK_4MS      0x0C
#define   OSC_XTAL_RANGE3_258CK_65MS     0x1C
#define   OSC_XTAL_RANGE3_1KCK_0MS       0x2C
#define   OSC_XTAL_RANGE3_1KCK_4MS       0x3C
#define   OSC_XTAL_RANGE3_1KCK_65MS      0x0D
#define   OSC_XTAL_RANGE3_16KCK_0MS      0x1D
#define   OSC_XTAL_RANGE3_16KCK_4MS      0x2D
#define   OSC_XTAL_RANGE3_16KCK_65MS     0x3D

// External crystal, frequency between 8 and 16 MHz
#define   OSC_XTAL_RANGE4_258CK_4MS      0x0E
#define   OSC_XTAL_RANGE4_258CK_65MS     0x1E
#define   OSC_XTAL_RANGE4_1KCK_0MS       0x2E
#define   OSC_XTAL_RANGE4_1KCK_4MS       0x3E
#define   OSC_XTAL_RANGE4_1KCK_65MS      0x0F
#define   OSC_XTAL_RANGE4_16KCK_0MS      0x1F
#define   OSC_XTAL_RANGE4_16KCK_4MS      0x2F
#define   OSC_XTAL_RANGE4_16KCK_65MS     0x3F

// External clock
#define   OSC_EXTCLK_0MS                 0x00
#define   OSC_EXTCLK_4MS                 0x10
#define   OSC_EXTCLK_65MS                0x20


//_____ D E C L A R A T I O N ______________________________________________

void Clock_switch_external(void);
void Clock_switch_internal(void);

//! @}


#endif  // _POWER_DRV_H_

