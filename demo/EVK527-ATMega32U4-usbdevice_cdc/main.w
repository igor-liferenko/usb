/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief Main for USB application.
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************
//!
//! @mainpage ATmega32U4 CDC demonstration
//!
//! @section intro License
//! Use of this program is subject to Atmel's End User License Agreement.
//!
//! Please read file  \ref lic_page for copyright notice.
//!
//! @section install Description
//! This embedded application source code illustrates how to implement a CDC application
//! with the ATmega32U4 controller.
//!
//! @section sample About the sample application
//! The sample code is delivered for EVK527.
//!
//! This application will enumerates as a CDC (communication device class) virtual COM port. The application
//! can be used as a USB to serial converter. 
//!
//! @section src_code About the source code
//! This source code is usable with the following compilers:
//! - IAR Embedded Workbench (5.11A and higher)
//! - AVRGCC (WinAVR 20080610 and higher).
//!
//! Support for other compilers may required modifications or attention for:
//! - compiler.h file 
//! - special registers declaration file
//! - interrupt subroutines declarations
//!
//! @section chg Changes
//! 2.0.1: Now does not allow to send data before end enumeration AND open port detection.
//!
//! @section arch Architecture
//! As illustrated in the figure bellow, the application entry point is located is the main.c file.
//! The main function first performs the initialization of a scheduler module and then runs it in an infinite loop.
//! The scheduler is a simple infinite loop calling all its tasks defined in the conf_scheduler.h file.
//! No real time schedule is performed, when a task ends, the scheduler calls the next task defined in
//! the configuration file (conf_scheduler.h).
//!
//! The sample dual role application is based on two different tasks:
//! - The usb_task  (usb_task.c associated source file), is the task performing the USB low level
//! enumeration process in device mode.
//! - The cdc task performs the loop back application between USB and USART interfaces.
//!
//! \image html arch_full.gif
//!
//! ***************************************************************************

//_____  I N C L U D E S ___________________________________________________

#include "config.h"
#include "modules/scheduler/scheduler.h"
#include "lib_mcu/wdt/wdt_drv.h"
#include "lib_mcu/power/power_drv.h"
#include "lib_mcu/usb/usb_drv.h"
#include "lib_mcu/util/start_boot.h"

//_____ M A C R O S ________________________________________________________

//_____ D E F I N I T I O N S ______________________________________________

int main(void)
{
   Usb_enable_regulator();
   wdt_reset();
   Wdt_clear_flag();
   Wdt_change_enable();
   Wdt_stop();
   start_boot_if_required();
   Clear_prescaler();
   scheduler();
   return 0;
}

//! \name Procedure to speed up the startup code
//! This one increment the CPU clock before RAM initialisation
// Locate low level init function before RAM init (init3 section)
// and remove std prologue/epilogue
char __low_level_init(void) __attribute__ ((section (".init3"),naked));

char __low_level_init()
{
  Clear_prescaler();
  return 1;
}
