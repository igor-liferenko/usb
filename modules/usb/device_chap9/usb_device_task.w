@ @c
/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief This file manages the USB device controller.
//!
//!  The USB task checks the income of new requests from the USB Host.
//!  When a Setup request occurs, this task will launch the processing
//!  of this setup contained in the usb_standard_request.c file.
//!  Other class specific requests are also processed in this file.
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
#include "usb_device_task.h"
#include "modules/usb/usb_task.h"
#include "lib_mcu/usb/usb_drv.h"
#include "usb_descriptors.h"
#include "modules/usb/device_chap9/usb_standard_request.h"
#include "lib_mcu/pll/pll_drv.h"

//_____ M A C R O S ________________________________________________________

//_____ D E F I N I T I O N S ______________________________________________

//!
//! Public : (bit) usb_connected
//! usb_connected is set to TRUE when VBUS has been detected
//! usb_connected is set to FALSE otherwise
//!/
bit   usb_connected=0;

//!
//! Public : (bit) usb_suspended
//! usb_suspended is set to TRUE when USB is in suspend mode
//! usb_suspended is set to FALSE otherwise
//!/
bit   usb_suspended=0;




//!
//! Public : (U8) usb_configuration_nb
//! Store the number of the USB configuration used by the USB device
//! when its value is different from zero, it means the device mode is enumerated
//! Used with USB_DEVICE_FEATURE == ENABLED only
//!/
extern U8  usb_configuration_nb;

//_____ D E C L A R A T I O N S ____________________________________________

//!
//! @brief This function initializes the USB device controller and system interrupt
//!
//! This function enables the USB controller and init the USB interrupts.
//! The aim is to allow the USB connection detection in order to send
//! the appropriate USB event to the operating mode manager.
//!
//! @param none
//!
//! @return none
//!
//!/
void usb_device_task_init(void)
{
   Usb_disable();
   Usb_enable();
#if (USB_LOW_SPEED_DEVICE==ENABLE)
   Usb_low_speed_mode();
#endif
   Usb_enable_vbus_pad();
   Usb_enable_vbus_interrupt();
   Enable_interrupt();
}

//!
//! @brief This function initializes the USB device controller
//!
//! This function enables the USB controller and init the USB interrupts.
//! The aim is to allow the USB connection detection in order to send
//! the appropriate USB event to the operating mode manager.
//! Start device function is executed once VBUS connection has been detected
//! either by the VBUS change interrupt either by the VBUS high level
//!
//! @param none
//!
//! @return none
//!
void usb_start_device (void)
{
   Usb_freeze_clock();
   Pll_start_auto();
   Wait_pll_ready();
   Usb_unfreeze_clock();
   Usb_attach();
#if (USB_RESET_CPU == ENABLED)
   Usb_reset_all_system();
#else
   Usb_reset_macro_only();
#endif
   Usb_enable_suspend_interrupt();
   Usb_enable_reset_interrupt();
   Enable_interrupt();
   usb_init_device();         // configure the USB controller EP0
}

//! @brief Entry point of the USB device mamagement
//!
//! This function is the entry point of the USB management. Each USB
//! event is checked here in order to launch the appropriate action.
//! If a Setup request occurs on the Default Control Endpoint,
//! the usb_process_request() function is call in the usb_standard_request.c file
//!
//! @param none
//!
//! @return none
void usb_device_task(void)
{
   if (usb_connected == FALSE)
   {
     if (Is_usb_vbus_high())    // check if Vbus ON to attach
     {
       Usb_enable();
       usb_connected = TRUE;
       usb_start_device();
       Usb_vbus_on_action();
     }
   }

   if(Is_usb_event(EVT_USB_RESET))
   {
      Usb_ack_event(EVT_USB_RESET);
      Usb_reset_endpoint(0);
      usb_configuration_nb=0;
   }

   // Here connection to the device enumeration process
   Usb_select_endpoint(EP_CONTROL);
   if (Is_usb_receive_setup())
   {
      usb_process_request();
   }
}
