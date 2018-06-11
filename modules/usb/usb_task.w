@ @c
/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief This file manages the USB task either device/host or both.
//!
//!  The USB task selects the correct USB task (usb_device task or usb_host task
//!  to be executed depending on the current mode available.
//!  According to USB_DEVICE_FEATURE and USB_HOST_FEATURE value (located in conf_usb.h file)
//!  The usb_task can be configured to support USB DEVICE mode or USB Host mode or both
//!  for a dual role device application.
//!  This module also contains the general USB interrupt subroutine. This subroutine is used
//!  to detect asynchronous USB events.
//!  Note:
//!    - The usb_task belongs to the scheduler, the usb_device_task and usb_host do not, they are called
//!      from the general usb_task
//!    - See conf_usb.h file for more details about the configuration of this module
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

//_____  I N C L U D E S ___________________________________________________

#include "config.h"
#include "conf_usb.h"
#include "usb_task.h"
#include "lib_mcu/usb/usb_drv.h"
#include "usb_descriptors.h"
#include "lib_mcu/power/power_drv.h"
#include "lib_mcu/pll/pll_drv.h"
#include "modules/usb/device_chap9/usb_device_task.h"

//_____ M A C R O S ________________________________________________________



//_____ D E F I N I T I O N S ______________________________________________

//!
//! Public : U16 g_usb_event
//! usb_connected is used to store USB events detected upon
//! USB general interrupt subroutine
//! Its value is managed by the following macros (See usb_task.h file)
//! Usb_send_event(x)
//! Usb_ack_event(x)
//! Usb_clear_all_event()
//! Is_usb_event(x)
//! Is_not_usb_event(x)
volatile U16 g_usb_event=0;


//! usb_connected is set to TRUE when VBUS has been detected
//! usb_connected is set to FALSE otherwise
extern bit   usb_connected;

// number of the USB configuration used by the USB device
// when its value is different from zero, it means the device mode is enumerated
extern U8    usb_configuration_nb;

//! @brief USB interrupt subroutine
//!
//! This function is called each time a USB interrupt occurs.
//! The following USB DEVICE events are taken in charge:
//! - Start Of Frame
//! - Suspend
//! - Wake-Up
//! - Resume
//! - Reset
//!
//! For each event, the user can launch an action by completing
//! the associate define (See conf_usb.h file to add action upon events)
//!
//! Note: Only interrupts events that are enabled are processed
//!
//! @param none
//!
//! @return none
 ISR(USB_GEN_vect)
{
  // - Resume state bus detection
   if (Is_usb_resume() && Is_resume_interrupt_enabled())
   {
      Usb_ack_resume();
      Usb_disable_resume_interrupt();
      Usb_send_event(EVT_USB_RESUME);
   }
  // - USB bus reset detection
   if (Is_usb_reset()&& Is_reset_interrupt_enabled())
   {
      Usb_ack_reset();
      usb_init_device();
      Usb_send_event(EVT_USB_RESET);
   }

}



