/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief This file contains the Power and clock management driver routines.
//!
//!  This file contains the Power and clock management driver routines.
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

//_____ I N C L U D E S ____________________________________________________

#include "config.h"
#include "power_drv.h"

//_____ M A C R O S ________________________________________________________


//_____ D E C L A R A T I O N ______________________________________________

//! set_power_down_mode.
//!
//! This function makes the AVR core enter power down mode.
//!
//! @param none
//!
//! @return none.
//!
void set_power_down_mode(void)
{
   Setup_power_down_mode();
   Sleep_instruction();
}



//! set_idle_mode.
//!
//! This function makes the AVR core enter idle mode.
//!
//! @param none
//!
//! @return none.
//!
void set_idle_mode(void)
{
   Setup_idle_mode();
   Sleep_instruction();
}

//! set_adc_noise_reduction_mode.
//!
//! This function makes the AVR core enter adc noise reduction mode.
//!
//! @param none
//!
//! @return none.
//!
void set_adc_noise_reduction_mode(void)
{
   Setup_adc_noise_reduction_mode();
   Sleep_instruction();
}

//! set_power_save_mode.
//!
//! This function makes the AVR core enter power save mode.
//!
//! @param none
//!
//! @return none.
//!
void set_power_save_mode(void)
{
   Setup_power_save_mode();
   Sleep_instruction();
}

//! set_standby_mode.
//!
//! This function makes the AVR core enter standby mode.
//!
//! @param none
//!
//! @return none.
//!
void set_standby_mode(void)
{
   Setup_standby_mode();
   Sleep_instruction();
}

//! set_ext_standby_mode.
//!
//! This function makes the AVR core enter extended standby mode.
//!
//! @param none
//!
//! @return none.
//!
void set_ext_standby_mode(void)
{
   Setup_ext_standby_mode();
   Sleep_instruction();
}




//! Clock_switch_external.
//!
//! This function makes the AVR selects the EXTERNAL clock source (CRYSTAL)
//!
//! @param none
//!
//! @return none.
//!
void Clock_switch_external(void)
{
  Enable_external_clock();
  while (!External_clock_ready());
  Select_external_clock();
  Disable_RC_clock();
}


//! Clock_switch_internal.
//!
//! This function makes the AVR selects the INTERNAL clock source (RC)
//!
//! @param none
//!
//! @return none.
//!
void Clock_switch_internal(void)
{
  Enable_RC_clock();
  while (!RC_clock_ready());
  Select_RC_clock();
  Disable_external_clock();
}

